import os
import base64
import logging
import boto3
from typing import Any
from urllib.parse import urlunsplit
from urllib.request import build_opener, Request, HTTPErrorProcessor
from urllib.error import URLError, HTTPError
from uuid import uuid4
from time import sleep


L = logging.getLogger()
L.setLevel(logging.INFO)

ROUTE_TIMEOUT = 30  # seconds
RETRY_IN = 2  # seconds
MAX_ATTEMPTS = ROUTE_TIMEOUT // RETRY_IN - 3

COOKIE_NAME = "sessionid"


class NoRedirect(HTTPErrorProcessor):
    def http_response(self, request, response):
        code, msg, hdrs = response.code, response.msg, response.info()
        if code in [301, 302, 303, 307, 308]:
            return response
        if not (200 <= code < 300):
            response = self.parent.error(
                'http', request, response, code, msg, hdrs)
        return response

def set_cookie(session_id: str) -> str:
    """Return cookie header."""
    return f"{COOKIE_NAME}={session_id}; Secure; HttpOnly; SameSite=None; Path=/;"


def start_instance(ecs: Any, session_id: str, sub: str) -> str:
    """Starts new workflow svc instance as ECS task.
    Returns: task ARN."""
    ecs_cluster = os.environ["ECS_CLUSTER"]
    ecs_task_def = os.environ["ECS_TASK_DEF"]
    svc_subnet = os.environ["SVC_SUBNET"]
    svc_security_grp = os.environ["SVC_SECURITY_GRP"]
    task = ecs.run_task(
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
                    {"name": "KC_SUB", "value": sub},
                    {"name": "SESSION_ID", "value": session_id}]
            },
            # {
            #     "name": f"{ecs_cluster}_sc",
            #     "environment": [
            #         {"name": "KC_SUB", "value": sub},
            #         {"name": "SESSION_ID", "value": session_id}]
            # },
            ]},
        propagateTags="TASK_DEFINITION",
        # tags=[{"key": "vlab", "value": vlab,
        #        "key": "proj", "value": proj}]
        )
    return task["tasks"][0]["taskArn"]


def healthy_task_ip(task_arn: str) -> str | None:
    """Get task ip, else None."""
    assert task_arn
    ecs = boto3.client("ecs")
    ecs_cluster = os.environ["ECS_CLUSTER"]
    described = ecs.describe_tasks(cluster=ecs_cluster, tasks=[task_arn])
    task = described["tasks"][0]
    task_health = task["healthStatus"]
    L.debug("task health:%s", task_health)
    containers = task.get("containers", [])
    for container in containers:
        if container["name"] == ecs_cluster:
            container_health = container["healthStatus"]
            L.debug("container health: %s", container_health)
            network_ifs = container.get("networkInterfaces", [])
            if len(network_ifs) > 0:
                if task_health == "HEALTHY":
                    L.info("Service healthy ip ready.")
                    return network_ifs[0].get("privateIpv4Address")
    return None


def update_task_ip(ddb: Any, id_value: str, session_id: str, task_ip: str) -> None:
    ddb.update_item(TableName=id_value,
                    Key={"id": {"S": session_id}},
                    UpdateExpression="set ip = :task_ip",
                    ExpressionAttributeValues={":task_ip": {"S": task_ip}})


def forward_to_addr(addr: str, session_id: str, event: dict[str, Any]) -> str:
    path = event["path"]
    event_headers = event["headers"]
    headers = {"Cookie": f"{COOKIE_NAME}={session_id}"}
    if (qs := event["queryStringParameters"]) is not None:
        qs = "&".join([f"{k}={v}" for k, v in qs.items()])
    url = urlunsplit(("http", addr, path, qs, None))
    method = event["httpMethod"]
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
    try:
        with build_opener(NoRedirect).open(Request(url, method=method, headers=headers, data=body),
                                           timeout=5) as response:
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
            else:
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


def get_task(ddb: Any, id_value: str, session_id: str, wait: bool = False) -> (str | None, str | None):
    wait_attempts = 0
    data = ddb.get_item(TableName=id_value, Key={"id": {"S": session_id}})
    # wait if other client updated ip/arn linked to new session id
    while (wait and "Item" not in data and wait_attempts < 4):
        sleep(4)
        data = ddb.get_item(TableName=id_value, Key={"id": {"S": session_id}})
        wait_attempts += 1
    ip = data.get("Item", {}).get("ip", {}).get("S")
    arn = data.get("Item", {}).get("arn", {}).get("S")
    L.debug("get task ip:%s arn:%s", ip, arn)
    return ip, arn


def cors(event, context):
    return {"statusCode": 204}


def put_new_session_id_or_raise_old(ddb: Any, id_value: str, sub: str, session_id: str) -> None:
    # condition fails if old session exists
    L.debug("attempting session_id:%s for sub:%s", session_id, sub)
    ddb.put_item(TableName=id_value,
                 Item={"id": {"S": sub},
                       "sessionid": {"S": session_id}},
                 ConditionExpression="attribute_not_exists(sessionid)",
                 ReturnValuesOnConditionCheckFailure="ALL_OLD")


def put_new_session_id(ddb: Any, id_value: str, sub: str, session_id: str, existing_session_id: str) -> None:
    # condition could fail if updated concurrently by other client
    L.debug("storing session_id:%s for sub:%s", session_id, sub)
    ddb.put_item(TableName=id_value,
                 Item={"id": {"S": sub},
                       "sessionid": {"S": session_id}},
                 ConditionExpression="sessionid = :session_id",
                 ExpressionAttributeValues={":session_id": {"S": existing_session_id}},
                 ReturnValuesOnConditionCheckFailure="ALL_OLD")


def put_session_id_arn(ddb: Any, id_value: str, session_id: str, task_arn: str) -> None:
    L.debug("storing task_arn:%s for session_id:%s", task_arn, session_id)
    ddb.put_item(TableName=id_value,
                 Item={"id": {"S": session_id},
                       "arn": {"S": task_arn}})


def is_task_active(ecs: Any, ddb: Any, id_value: str, session_id: str) -> bool:
    _, arn = get_task(ddb, id_value, session_id, wait=True)
    if arn:
        ecs_cluster = os.environ["ECS_CLUSTER"]
        described = ecs.describe_tasks(cluster=ecs_cluster, tasks=[arn])
        tasks = described.get("tasks")
        if tasks:
            last_status = tasks[0].get("lastStatus")
        else:
            # old missing task
            last_status = None
        L.debug("last_status:%s for arn:%s", last_status, arn)
        if last_status in {"PROVISIONING", "PENDING", "ACTIVATING", "RUNNING"}:
            return True
        else:
            L.debug("deleting session_id:%s", session_id)
            ddb.delete_item(TableName=id_value, Key={"id": {"S": session_id}})
    return False


def session(event, context):
    sub = event["requestContext"]["authorizer"]["KC_SUB"]
    ddb = boto3.client("dynamodb")
    ecs = boto3.client("ecs")
    id_value = os.environ["DDB_ID_TASK"]
    session_id = str(uuid4())
    L.debug("new session_id:%s", session_id)
    try:
        put_new_session_id_or_raise_old(ddb, id_value, sub, session_id)
        L.debug("new session id stored")
    except ddb.exceptions.ConditionalCheckFailedException as e:
        existing_session_id = e.response["Item"]["sessionid"]["S"]
        L.debug("existing_session_id:%s found", existing_session_id)
        if is_task_active(ecs, ddb, id_value, existing_session_id):
            L.debug("task is active")
            return {"statusCode": 204,
                    "headers": {"Set-Cookie": set_cookie(existing_session_id)}}
        else:
            L.debug("task is not active, put new session id")
            try:
                put_new_session_id(ddb, id_value, sub, session_id, existing_session_id)
                L.debug("new session id stored")
            except ddb.exceptions.ConditionalCheckFailedException as e:
                # other client rewrote already session id, task must be active
                existing_session_id = e.response["Item"]["sessionid"]["S"]
                assert is_task_active(ecs, ddb, id_value, existing_session_id)
                L.debug("conflict, return existing_session_id:%s", existing_session_id)
                return {"statusCode": 204,
                        "headers": {"Set-Cookie": set_cookie(existing_session_id)}}
    task_arn = start_instance(ecs, session_id, sub)
    L.debug("new instance task_arn:%s", task_arn)
    put_session_id_arn(ddb, id_value, session_id, task_arn)
    return {"statusCode": 204, "headers": {"Set-Cookie": set_cookie(session_id)}}


def forward(event: Any, update_ip: bool = False) -> Any:
    session_id = event["requestContext"]["authorizer"]["SESSION_ID"]
    ddb = boto3.client("dynamodb")
    id_value = os.environ["DDB_ID_TASK"]
    ip, arn = get_task(ddb, id_value, session_id)
    if not arn:
        return {"statusCode": 502, "body": "GET /session/ endpoint first"}
    if not ip:
        if update_ip:
            ip = healthy_task_ip(arn)
            if not ip:
                return {"statusCode": 503, "headers": {"Retry-After": 20}}  # client should retry
            update_task_ip(ddb, id_value, session_id, ip)
        else:
            return {"statusCode": 502, "body": "GET /auth/ endpoint first"}
    return forward_to_addr(f"{ip}:8100", session_id, event)


def auth(event, context):
    return forward(event, update_ip=True)


def launch(event, context):
    headers = event["headers"]
    key_arn = os.environ["KEY_ARN"]
    sm = boto3.client('secretsmanager')
    key = sm.get_secret_value(SecretId=key_arn)["SecretString"].encode()
    headers["Authorization"] = base64.b64encode(key).decode()
    return forward(event)


def default(event, context):
    if event["path"] == '/favicon.ico':
        return {"statusCode": 204}
    return forward(event)
