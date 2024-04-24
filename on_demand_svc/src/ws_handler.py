import os
import json
import logging
import boto3
from datetime import datetime, timedelta
from urllib.request import urlopen, Request
from urllib.error import URLError

L = logging.getLogger()
L.setLevel(logging.INFO)

RETRY_MSG = "Retry later"

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


def _update_item_acc(time, svc_vlab, task_duration):
    DDB.update_item(TableName=DDB_ECS_TASK_ACC,
                    Key={"year_month_acc": {"S": _task_key(time, svc_vlab)}},
                    UpdateExpression="set task_duration = if_not_exists(task_duration, :zero) + :d",
                    ExpressionAttributeValues={":d": {"N": str(task_duration)}, ":zero": {"N": "0"}})


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
        svc_healthy = False
        task_submit_time = datetime.fromisoformat(data["Item"]["task_submit_time"]["S"])
        task_arn = data["Item"]["task"]["S"]
        described = ECS.describe_tasks(cluster=ECS_CLUSTER, tasks=[task_arn])
        task = described["tasks"][0]
        containers = task.get("containers", [])
        if len(containers) > 0:
            network_ifs = containers[0].get("networkInterfaces", [])
            if len(network_ifs) > 0:
                ip = network_ifs[0].get("privateIpv4Address")
                L.info("Service ip ready, ip: %s.", ip)
        if not ip:
            L.info("Waiting for service ip.")
            # could be "Internal server error" if apigw integration crashed
            return {"statusCode": 503, "body": json.dumps({"message": RETRY_MSG})}
        try:
            with urlopen(f"http://{ip}:8080/health", timeout=1) as response:
                if response.status == 204:
                    L.info("Service is healthy.")
                    svc_healthy = True
        except URLError as e:
            L.info("Checking for service error: %s.", e)
        if svc_healthy:
            try:
                token = event["requestContext"]["authorizer"]["TOKEN"]
                with urlopen(Request(f"http://{ip}:8080/init",
                                    headers={"Content-Type": "application/json"},
                                    data=json.dumps({"token": token}).encode()),
                             timeout=2) as response:
                    L.info("Service init invoked.")
            except URLError as e:
                L.error("Unable to init service: %s", e)
                return {"statusCode": 500,
                        "body": json.dumps({"message": "Error invoking svc init"})}
            L.info("Task lead time: %s.", str(datetime.utcnow() - task_submit_time))
            DDB.update_item(TableName=DDB_WS_CONN_TASK,
                            Key={"conn": {"S": conn_id}},
                            UpdateExpression="set ip = :ip",
                            ExpressionAttributeValues={":ip": {"S": ip}})
        else:
            L.info("Waiting for service to be healthy.")
            return {"statusCode": 503, "body": json.dumps({"message": RETRY_MSG})}
    # we have ip and svc is healthy
    try:
        with urlopen(Request(f"http://{ip}:8080/default",
                             headers={"Content-Type": "application/json"},
                             data=event["body"].encode()),
                     timeout=2) as response:
            L.info("Message forwarded.")
            return {"statusCode": response.status, "body": response.read()}
    except URLError as e:
        L.error("Unable to forward message: %s", e)
    return {"statusCode": 500, "body": json.dumps({"message": "Error forwarding message"})}


def disconnect(event, context):
    conn_id = event["requestContext"]["connectionId"]
    svc_vlab = event["requestContext"]["authorizer"]["SVC_VLAB"]
    data = DDB.delete_item(TableName=DDB_WS_CONN_TASK, Key={"conn": {"S": conn_id}}, ReturnValues="ALL_OLD")
    task_submit_time = datetime.fromisoformat(data["Attributes"]["task_submit_time"]["S"])
    ip = data["Attributes"]["ip"]["S"]
    task = data["Attributes"]["task"]["S"]
    if ip:
        try:
            # let shutdown cleanup task wait 10sec
            urlopen(Request(f"http://{ip}:8080/shutdown", method="POST"), timeout=10)
        except URLError as e:
            L.info("Shutting down svc error: %s.", e)
    ECS.stop_task(cluster=ECS_CLUSTER, task=task)
    # task accounting
    task_end_time = datetime.utcnow()
    if task_end_time - task_submit_time > timedelta(days=1):
        L.error("Task was running for too long! Submitted: %s, finished: %s, vlab: %s, task: %s",
                task_submit_time, task_end_time, svc_vlab, task)
        return {"statusCode": 500}
    end_time_1st_day_of_month = datetime(task_end_time.year, task_end_time.month, 1)
    if task_submit_time < end_time_1st_day_of_month:
        # task duration spanned over two months
        old_month_duration = (end_time_1st_day_of_month - task_submit_time).total_seconds()
        new_month_duration = (task_end_time - end_time_1st_day_of_month).total_seconds()
        _update_item_acc(task_submit_time, svc_vlab, old_month_duration)
        _update_item_acc(task_end_time, svc_vlab, new_month_duration)
        L.info("Task duration old month: %s, new month: %s.", old_month_duration, new_month_duration)
    else:
        task_duration = (task_end_time - task_submit_time).total_seconds()
        _update_item_acc(task_submit_time, svc_vlab, task_duration)
        L.info("Task duration: %s.", task_duration)
    return {"statusCode": 200}
