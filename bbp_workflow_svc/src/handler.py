"""Handlers for the workflow service."""

import base64
import json
import logging
import os
import random
from dataclasses import dataclass
from enum import Enum
from time import sleep
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlunsplit
from urllib.request import HTTPErrorProcessor, Request, build_opener

import boto3

L = logging.getLogger()
L.setLevel(logging.INFO)

ROUTE_TIMEOUT = 30  # seconds
RETRY_IN = 2  # seconds
MAX_ATTEMPTS = ROUTE_TIMEOUT // RETRY_IN - 3
TASK_REGISTRY_TABLE = os.environ["DDB_ID_TASK"]
WORKFLOW_SVC_PORT = 8100

DDB_RETRIES = 3
DDB_RETRY_DELAY = 0.1  # seconds
DDB_RETRY_MAX_DELAY = 5  # seconds

WAIT_TASK_READY_ATTEMPTS = 5
WAIT_TASK_READY_DELAY = 2  # seconds
WAIT_TASK_READY_MAX_DELAY = 60. # seconds

PENDING_STATUSES = {"PROVISIONING", "PENDING", "ACTIVATING"}


def cors(event, _context: Any = None):
    """Lambda handler for the CORS route."""
    return {"statusCode": 204}


def default(event, _context: Any = None):
    """Lambda handler for the default route."""
    if event["path"] == '/favicon.ico':
        return {"statusCode": 204}
    return _forward(event)


def launch(event: dict[str, Any], _context: Any = None) -> dict[str, Any]:
    """Lambda handler for the launch route."""
    return _forward(event)


class TaskStatus(Enum):
    """The status of a task."""
    RUNNING = "RUNNING"
    PENDING = "PENDING"
    UNHEALTHY = "UNHEALTHY"


@dataclass(repr=False, eq=False, frozen=True, slots=True, kw_only=True)
class Task:
    """A task."""
    id: str
    ip: str | None = None
    arn: str
    status: TaskStatus

    def __repr__(self):
        """String representation of the task."""
        return self.id

    def __str__(self):
        """String representation of the task."""
        return self.__repr__()

    def is_active(self) -> bool:
        """Check if the task is active."""
        return self.status in {TaskStatus.RUNNING, TaskStatus.PENDING}


def _forward(event):
    """Forward the request to a running task dedicated to the given virtual lab project."""

    ecs_client = boto3.client("ecs")
    ddb_client = boto3.client("dynamodb")

    ecs_cluster = os.environ["ECS_CLUSTER"]

    kc_subject =  event["requestContext"]["authorizer"]["KC_SUB"]

    body = json.loads(event["body"])
    virtual_lab, project = body["virtual_lab"], body["project"]

    try:
        task = _get_or_create_active_task(
            ddb_client=ddb_client,
            ecs_client=ecs_client,
            ecs_cluster=ecs_cluster,
            virtual_lab=virtual_lab,
            project=project,
            task_env_vars={
                "KC_SUB": kc_subject,
                "VIRTUAL_LAB": virtual_lab,
                "PROJECT": project,
            },
        )
    except Exception as e:
        L.error("Error in launch: %s", e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error"
            })
        }

    if task and task.status == TaskStatus.PENDING:
        L.info("Task '%s' is pending, try again later..", task)
        return {
            "statusCode": 503,
            "headers": {"Retry-After": 30},
            "body": json.dumps({
                "message": "Task is starting up, please try again later in a few seconds."
            })
        }

    if task and task.status == TaskStatus.RUNNING:
        assert task.ip
        L.info("Forwarding request to task '%s'", task)
        return _forward_to_address(f"{task.ip}:{WORKFLOW_SVC_PORT}", event)

    # Race condition occurred, ask client to retry
    return {
        "statusCode": 409,
        "body": json.dumps({
            "message": "Task creation conflict, please retry"
        })
    }


def _get_or_create_active_task(
    *,
    ddb_client: Any,
    ecs_client: Any,
    ecs_cluster: str,
    virtual_lab: str,
    project: str,
    task_env_vars: dict[str, str],
) -> Task:
    """
    Get an existing active task or create a new one.

    Args:
        ddb_client: The DDB client.
        ecs_client: The ECS client.
        ecs_cluster: The ECS cluster.
        virtual_lab: The virtual lab.
        project: The project.

    Returns:
        The task or None if the task is not found.
    """
    task_id = f"{virtual_lab}-{project}"

    L.info("Task ID: %s", task_id)

    # Try to reserve a slot in db or get existing task in one operation
    task_arn, slot_reserved = _get_task_arn_or_reserve_slot(
        ddb_client=ddb_client,
        task_id=task_id,
    )

    L.info("Task ARN: %s, Slot reserved: %s", task_arn, slot_reserved)

    if task_arn:
        if task := _get_active_or_ddb_delete_unhealthy_task(
            ddb_client=ddb_client,
            ecs_client=ecs_client,
            ecs_cluster=ecs_cluster,
            task_id=task_id,
            task_arn=task_arn
        ):
            return task

        # Try to get or reserve a new slot
        task_arn, slot_reserved = _get_task_arn_or_reserve_slot(
            ddb_client=ddb_client,
            task_id=task_id,
        )

        # Try fetching the task again in case it was created by another instance
        if task_arn:
            if task := _get_active_or_ddb_delete_unhealthy_task(
                ddb_client=ddb_client,
                ecs_client=ecs_client,
                ecs_cluster=ecs_cluster,
                task_id=task_id,
                task_arn=task_arn
            ):
                return task

    if not slot_reserved:
        L.info("Failed to reserve slot for task '%s'", task_id)
        return None

    # try fetching the active task if it exists
    L.info("Trying to fetch active task if it exists..")
    if task := _get_active_or_ddb_delete_unhealthy_task(
        ddb_client=ddb_client,
        ecs_client=ecs_client,
        ecs_cluster=ecs_cluster,
        task_id=task_id,
        task_arn=task_arn
    ):
        L.info("Found active task '%s'", task)
        return task
    
    L.info("Active task was not found.")

    # Someone else is creating a task, let client retry
    if not slot_reserved:
        L.info("Failed to reserve slot for task '%s'", task_id)
        return None

    L.info("Reservation was successful, trying to create task..")

    ecs_cluster = os.environ["ECS_CLUSTER"]

    # We have the reservation, now create the ECS task
    try:
        new_task_arn = _start_task(
            ecs_client=ecs_client,
            ecs_cluster=ecs_cluster,
            task_id=task_id,
            tags={
                "vlab": virtual_lab,
                "proj": project,
            },
            task_env_vars=task_env_vars,
        )
        L.info("Created ECS task '%s'", new_task_arn)
    except Exception as e:
        L.error("Failed to create task: %s", e)
        return None

    # Update our reservation with the active task ARN
    if _ddb_update_reservation(ddb_client=ddb_client, task_id=task_id, task_arn=new_task_arn):

        L.info("Updated reservation '%s' with active task ARN '%s'", task_id, new_task_arn)

        if task := _get_active_or_ddb_delete_unhealthy_task(
            ddb_client=ddb_client,
            ecs_client=ecs_client,
            ecs_cluster=ecs_cluster,
            task_id=task_id,
            task_arn=new_task_arn,
        ):
            L.info("Retrieved created task '%s'", task)
            return task

        L.info("Failed to create active task using a reservation '%s'", task_id)

    # If update failed, clean up the task
    try:
        ecs_client.stop_task(
            cluster=ecs_cluster,
            task=new_task_arn,
            reason="Failed to update task reservation"
        )
        L.info("Stopped task '%s' after failed registration", new_task_arn)
    except Exception as e:
        L.error("Failed to stop task after failed registration: %s", e)

    # Check one last time for a healthy task
    if task := _get_active_or_ddb_delete_unhealthy_task(
        ddb_client=ddb_client,
        ecs_client=ecs_client,
        ecs_cluster=ecs_cluster,
        task_id=task_id,
        task_arn=new_task_arn,
    ):
        return task

    return None


def _get_task_arn_or_reserve_slot(*, ddb_client: Any, task_id: str) -> tuple[Task | None, bool]:
    """
    Get an existing task ARN or reserve a slot for a new task.

    Args:
        ddb_client: The DDB client.
        task_id: The task ID.

    Returns:
        A tuple of (task_arn, slot_reserved).
    """
    try:
        # Try to reserve slot, get existing item if it fails
        ddb_client.put_item(
            TableName=TASK_REGISTRY_TABLE,
            Item={"id": {"S": task_id}},
            ConditionExpression="attribute_not_exists(id)",
            ReturnValuesOnConditionCheckFailure="ALL_OLD",
        )
        # Put succeeded, we got the slot
        L.info("Reserved slot for task '%s'", task_id)
        return None, True

    except ddb_client.exceptions.ConditionalCheckFailedException as e:
        # Put failed, get the existing item from the error response
        arn = e.response.get("Item", {}).get("arn", {}).get("S")
        L.info("Failed to reserve slot for task '%s', got existing task ARN '%s'", task_id, arn)
        return arn, False


def _get_active_or_ddb_delete_unhealthy_task(
    *,
    ddb_client: Any,
    ecs_client: Any,
    ecs_cluster: str,
    task_id: str,
    task_arn: str,
) -> Task | None:
    """Get an active task or delete the task registration if it's not active."""
    if not task_arn:
        return None

    task = _get_task(
            ddb_client=ddb_client,
            ecs_client=ecs_client,
            ecs_cluster=ecs_cluster,
            task_id=task_id,
            task_arn=task_arn
    )

    if not task:
        L.info("Task '%s' not found", task_id)
        return None

    L.info("Task '%s' found with status '%s'", task.id, task.status)

    if task.status not in {TaskStatus.RUNNING, TaskStatus.PENDING}:
        L.info("Task '%s' is not running or pending, deleting task registration", task_id)
        _ddb_delete_task(ddb_client=ddb_client, task_id=task.id, task_arn=task_arn)
        return None

    return task


def _ddb_update_reservation(ddb_client: Any, task_id: str, task_arn: str) -> bool:
    """Update the reservation with the created task ARN.
    
    Args:
        ddb_client: The DDB client.
        task_id: The task ID.
        task_arn: The task ARN.

    Returns:
        True if the update was successful, False otherwise.
    """
    try:
        ddb_client.update_item(
            TableName=TASK_REGISTRY_TABLE,
            Key={"id": {"S": task_id}},
            UpdateExpression="SET arn = :arn",
            ConditionExpression="attribute_exists(id) AND attribute_not_exists(arn)",
            ExpressionAttributeValues={":arn": {"S": task_arn}},
        )
        return True
    except ddb_client.exceptions.ConditionalCheckFailedException:
        return False


def _ddb_get_task_arn(*, ddb_client: Any, task_id: str) -> str | None:
    """Get the task ARN from the DDB table.
    
    Uses decorrelated jitter formula to calculate the delay between retries.

    Args:
        ddb_client: The DDB client.
        task_id: The task ID.

    Returns:
        The task ARN or None if the task is not found.
    """

    attempts = 0
    delay = DDB_RETRY_DELAY

    while attempts < DDB_RETRIES:

        response = ddb_client.get_item(
            TableName=TASK_REGISTRY_TABLE,
            Key={"id": {"S": task_id}}
        )

        if task_arn := response.get("Item", {}).get("arn", {}).get("S"):
            return task_arn

        if attempts == DDB_RETRIES - 1:
            break

        # Decorrelated Jitter Formula
        delay = min(DDB_RETRY_MAX_DELAY, random.uniform(DDB_RETRY_DELAY, delay * 3))

        sleep(delay)

        attempts += 1

    L.info("Failed to get task ARN for task '%s' for table '%s'", task_id, TASK_REGISTRY_TABLE)

    return None


def _ddb_delete_task(ddb_client: Any, task_id: str, task_arn: str) -> None:
    """Delete task registration."""
    ddb_client.delete_item(
        TableName=TASK_REGISTRY_TABLE,
        Key={"id": {"S": task_id}},
        ConditionExpression="arn = :arn",
        ExpressionAttributeValues={":arn": {"S": task_arn}},
    )
    L.info("Deleted task registration for task '%s' from table '%s'", task_id, TASK_REGISTRY_TABLE)


def _get_task(
    ddb_client: Any,
    ecs_client: Any,
    ecs_cluster: str,
    task_id: str,
    task_arn: str | None,
) -> Task | None:
    """Get task and verify its health status."""
    if not task_arn:
        L.info("Arn is None, trying to get it from DDB table '%s'", task_id)
        task_arn = _ddb_get_task_arn(ddb_client=ddb_client, task_id=task_id)

    if not task_arn:
        L.info("Task '%s' arn not found in DDB table '%s'", task_id, TASK_REGISTRY_TABLE)
        return None

    # The task is stopped as it's not in the ECS cluster anymore
    if not (tasks := ecs_client.describe_tasks(cluster=ecs_cluster, tasks=[task_arn])["tasks"]):
        L.info("Task '%s' not found in ECS cluster '%s'", task_arn, ecs_cluster)
        return Task(id=task_id, arn=task_arn, status=TaskStatus.UNHEALTHY)

    task = tasks[0]
    last_status, health_status = task["lastStatus"], task["healthStatus"]

    # When PROVISIONING, the task health status is UNKNOWN
    if health_status in {"HEALTHY", "UNKNOWN"}:
        # Task is running and healthy and has an ip address
        if (
            last_status == "RUNNING"
            and (ip := _find_task_container_ip(ecs_cluster=ecs_cluster, task=task))
        ):
            L.info("Task '%s' is running and healthy.", task_id)
            return Task(id=task_id, arn=task_arn, status=TaskStatus.RUNNING, ip=ip)

        # Task is preparing to run
        if last_status in PENDING_STATUSES:
            L.info("Task '%s' is preparing to run.", task_id)
            return Task(id=task_id, arn=task_arn, status=TaskStatus.PENDING)

    # Let's assume all other cases are unsuitable for forwarding
    L.info("Task '%s' with health status '%s' and last status '%s' is unsuitable for forwarding", task_id, health_status, last_status)
    return Task(id=task_id, arn=task_arn, status=TaskStatus.UNHEALTHY)


def _start_task(*, ecs_client: Any, ecs_cluster: str, task_id: str, tags: list[dict[str, str]], task_env_vars) -> str:
    """Start a task."""
    ecs_task_def = os.environ["ECS_TASK_DEF"]
    svc_subnet = os.environ["SVC_SUBNET"]
    svc_security_grp = os.environ["SVC_SECURITY_GRP"]

    task = ecs_client.run_task(
        cluster=ecs_cluster,
        taskDefinition=ecs_task_def,
        launchType="FARGATE",
        enableExecuteCommand=True,  # TODO
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": [svc_subnet],
                "securityGroups": [svc_security_grp]}},
        overrides={
            "containerOverrides": [
            {
                "name": ecs_cluster,
                "environment": [
                    {"name": key, "value": value}
                    for key, value in task_env_vars.items()
                ],
            },
            # {
            #     "name": f"{ecs_cluster}_sc",
            #     "environment": [
            #         {"name": "KC_SUB", "value": sub},
            #         {"name": "SESSION_ID", "value": session_id}]
            # },
            ]},
        propagateTags="TASK_DEFINITION",
        tags=[{"key": key, "value": value} for key, value in tags.items()]
        )
    return task["tasks"][0]["taskArn"]


def _find_task_container_ip(*, ecs_cluster: str, task: dict[str, Any]) -> str | None:
    """Find the ip address of the task container."""

    container = None
    for current_container in task["containers"]:
        if current_container["name"] == ecs_cluster:
            container = current_container
            break
    else:
        L.error("Container not found in task %s", task)
        return None

    container_health = container["healthStatus"]
    L.debug("Container %s health: %s", container["name"], container_health)

    network_ifs = container.get("networkInterfaces", [])

    if not network_ifs:
        L.error("No network interfaces found for container %s of task %s", container["name"], task)
        return None

    ip = network_ifs[0]["privateIpv4Address"]

    L.info("Service at %s healthy ip ready.", ip)

    return ip


class NoRedirect(HTTPErrorProcessor):
    """HTTPErrorProcessor that does not redirect."""
    def http_response(self, request, response):
        code, msg, hdrs = response.code, response.msg, response.info()
        if code in [301, 302, 303, 307, 308]:
            return response
        if not 200 <= code < 300:
            response = self.parent.error(
                'http', request, response, code, msg, hdrs)
        return response


def _event_to_request(address: str, event: dict[str, Any]) -> Request:

    method = event["httpMethod"]

    # TODO: to add path parameters in routes to the path that will be forwarded to the service
    if method == "POST":
        path = event["path"]
    else:
        path_params = event["pathParameters"]
        # remove the path parameters from the path that will be forwarded to the service
        # e.g. /vlab/proj/launch/ -> /launch/
        path = event["path"].replace(f"/{path_params['virtual_lab']}/{path_params['project']}", "")

    event_headers = event["headers"]
    headers = {}
    if (qs := event["queryStringParameters"]) is not None:
        qs = "&".join([f"{k}={v}" for k, v in qs.items()])

    url = urlunsplit(("http", address, path, qs, None))
    body = None
    if method == "POST":
        headers["Content-Type"] = event_headers["Content-Type"]
        headers["Content-Length"] = event_headers["Content-Length"]
        if "Authorization" in event_headers:
            headers["Authorization"] = event_headers["Authorization"]
        if (body := event["body"]) is not None:
            body = body.encode()
            if event["isBase64Encoded"]:
                body = base64.b64decode(body)

    L.info("Forward: %s %s", method, url)
    return Request(url, method=method, headers=headers, data=body)


def _forward_to_address(address: str, event: dict[str, Any]) -> str:
    """Forward the request to the given address."""
    request = _event_to_request(address, event)

    try:
        with build_opener(NoRedirect).open(request, timeout=5) as response:
            response_headers = {}
            binary = False
            for k, v in response.headers.items():
                if k in ["Content-Type", "Location", "Etag"]:
                    response_headers[k] = v
                    if k == "Content-Type" and (v.startswith("image/")
                                                or v.startswith("font/")
                                                or v == "application/octet-stream"):
                        binary = True
            # L.info("Forward response: %s", response.status)
            if binary:
                return {"statusCode": response.status,
                        "isBase64Encoded": True,
                        "headers": response_headers,
                        "body": base64.b64encode(response.read()).decode("utf-8")}

            return {"statusCode": response.status,
                    "body": response.read(),
                    "headers": response_headers}

    except HTTPError as e:
        L.info("Message forward http error: %s %s.", e.code, e.reason)
        return {"statusCode": e.code}
    except URLError as e:
        L.info("Message forward url error: %s.", e.reason)
        return {"statusCode": 500}
    return ""