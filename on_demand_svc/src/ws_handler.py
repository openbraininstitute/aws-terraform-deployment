import os
import json
import logging
import boto3
from datetime import datetime, timedelta
from time import sleep
from urllib.request import urlopen, Request
from urllib.error import URLError

L = logging.getLogger()
L.setLevel(logging.INFO)

ROUTE_TIMEOUT = 29 - 3 # seconds
RETRY_IN = 2  # seconds
MAX_ATTEMPTS = ROUTE_TIMEOUT // RETRY_IN - 2

DDB = boto3.client("dynamodb")
ECS = boto3.client("ecs")

DDB_WS_CONN_TASK = os.environ["DDB_WS_CONN_TASK"]
DDB_ECS_TASK_ACC = os.environ["DDB_ECS_TASK_ACC"]
APIGW_ENDPOINT = os.environ["APIGW_ENDPOINT"]
APIGW_REGION = os.environ["APIGW_REGION"]
ECS_CLUSTER = os.environ["ECS_CLUSTER"]
ECS_TASK_NAME = os.environ["ECS_TASK_NAME"]
ECS_TASK_DEF = os.environ["ECS_TASK_DEF"]
SVC_SUBNET = os.environ["SVC_SUBNET"]
SVC_SECURITY_GRP = os.environ["SVC_SECURITY_GRP"]
SVC_BUCKET = os.environ["SVC_BUCKET"]


def _task_key(date, label):
    return f"{date.strftime('%Y-%m')}-{label}"


def connect(event, context):
    conn_id = event["requestContext"]["connectionId"]
    protocol = event["headers"]["Sec-WebSocket-Protocol"]
    svc_vlab = event["requestContext"]["authorizer"]["SVC_VLAB"]
    task = ECS.run_task(
        cluster=ECS_CLUSTER,
        taskDefinition=ECS_TASK_DEF,
        networkConfiguration={"awsvpcConfiguration": {"subnets": [SVC_SUBNET],
                                                      "securityGroups": [SVC_SECURITY_GRP]}},
        overrides={
            "containerOverrides": [{
                "name": ECS_TASK_NAME,
                "environment": [
                    {"name": "APIGW_ENDPOINT", "value": APIGW_ENDPOINT},
                    {"name": "APIGW_REGION", "value": APIGW_REGION},
                    {"name": "APIGW_CONN_ID", "value": conn_id},
                    {"name": "SVC_BUCKET", "value": SVC_BUCKET},
                    {"name": "SVC_VLAB", "value": svc_vlab}]}]},
        propagateTags="TASK_DEFINITION",
        tags=[{
            "key": "vlab",
            "value": svc_vlab}])
    now = datetime.utcnow()
    L.info(_task_key(now, svc_vlab))
    DDB.put_item(
        TableName=DDB_WS_CONN_TASK,
        Item={"conn": {"S": conn_id},
              "task": {"S": task["tasks"][0]["taskArn"]},
              "ip": {"S": ""},
              "task_submit_time": {"S": now.isoformat()}})
    return {"statusCode": 200,
            "headers": {"Sec-WebSocket-Protocol": protocol}}

def default(event, context):
    start_time = datetime.utcnow()
    conn_id = event["requestContext"]["connectionId"]
    data = DDB.get_item(TableName=DDB_WS_CONN_TASK, Key={"conn": {"S": conn_id}})
    ip = data["Item"]["ip"]["S"]
    if not ip:
        wait_for_svc_attempts = 0
        svc_healthy = False
        task_submit_time = datetime.fromisoformat(data["Item"]["task_submit_time"]["S"])
        task_arn = data["Item"]["task"]["S"]
        while (datetime.utcnow() - start_time < timedelta(seconds=ROUTE_TIMEOUT)
               and wait_for_svc_attempts < MAX_ATTEMPTS):
            described = ECS.describe_tasks(cluster=ECS_CLUSTER, tasks=[task_arn])
            task = described["tasks"][0]
            containers = task.get("containers", [])
            if len(containers) > 0:
                network_ifs = containers[0].get("networkInterfaces", [])
                if len(network_ifs) > 0:
                    ip = network_ifs[0].get("privateIpv4Address")
                    L.info("service ip ready, ip: %s", ip)
                    break
            wait_for_svc_attempts += 1
            L.info("waiting for service ip, attempt: %d", wait_for_svc_attempts)
            sleep(RETRY_IN)
        if not ip:
            return {"statusCode": 503,
                    # could be "Internal server error" if apigw integration crashed
                    "body": json.dumps({"message": "Retry later"})}
        while (datetime.utcnow() - start_time < timedelta(seconds=ROUTE_TIMEOUT)
               and wait_for_svc_attempts < MAX_ATTEMPTS):
            try:
                with urlopen(f"http://{ip}:8080/health",
                             timeout=1) as response:
                    if response.status == 204:
                        L.info("service is healthy")
                        svc_healthy = True
                        break
            except URLError as e:
                L.info("Checking for service error: %s", e)
            wait_for_svc_attempts += 1
            L.info("Waiting for service to be healthy, attempt: %s", wait_for_svc_attempts)
            sleep(RETRY_IN)
        if svc_healthy:
            L.info("Task lead time %s:", str(datetime.utcnow() - task_submit_time))
            DDB.update_item(TableName=DDB_WS_CONN_TASK,
                            Key={"conn": {"S": conn_id}},
                            UpdateExpression="set ip = :ip",
                            ExpressionAttributeValues={":ip": {"S": ip}})
        else:
            return {"statusCode": 503,
                    "body": json.dumps({"message": "Retry later"})}
    # we have ip and svc is healthy
    try:
        with urlopen(Request(f"http://{ip}:8080/default",
                             headers={"Content-Type": "application/json"},
                             data=event["body"].encode()),
                     timeout=2) as response:
            L.info("Message forwarded")
            return {"statusCode": response.status, "body": response.read()}
    except URLError as e:
        L.error("Unable to forward message: %s", e)
    return {"statusCode": 500, "body": json.dumps({"message": "Error forwarding message"})}

def disconnect(event, context):
    conn_id = event["requestContext"]["connectionId"]
    data = DDB.delete_item(TableName=DDB_WS_CONN_TASK, Key={"conn": {"S": conn_id}}, ReturnValues="ALL_OLD")
    task_submit_time = datetime.fromisoformat(data["Attributes"]["task_submit_time"]["S"])
    ip = data["Attributes"]["ip"]["S"]
    task = data["Attributes"]["task"]["S"]
    ECS.stop_task(cluster=ECS_CLUSTER, task=task)
    task_duration = datetime.utcnow() - task_submit_time
    L.info("Task duration %s", str(task_duration))
    if ip:
        try:
            urlopen(Request(f"http://{ip}:8080/shutdown", method="POST"), timeout=2)
        except URLError as e:
            L.info("Shutting down svc error: %s", e)
    return {"statusCode": 200}
