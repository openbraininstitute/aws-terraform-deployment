import boto3
import json
import math
import os
from datetime import datetime, timedelta, timezone

# A task that started this recently may hold jobs the queue metric still counts as queued
RECENTLY_STARTED = timedelta(seconds=150)
IN_FLIGHT_STATUSES = {"PROVISIONING", "PENDING", "ACTIVATING"}
# ECS limits
DESCRIBE_TASKS_BATCH = 100
RUN_TASK_MAX_COUNT = 10


def queue_length(cloudwatch, queue_name, now):
    """The newest datapoint of the queue length in the last minute, or 0 if there is none."""
    response = cloudwatch.get_metric_statistics(
        Namespace="SmallScaleSimulator/JobQueue",
        MetricName="QueueLength",
        Dimensions=[{"Name": "QueueName", "Value": queue_name}],
        StartTime=now - timedelta(minutes=1),
        EndTime=now,
        Period=10,
        Statistics=["Minimum"],
    )
    if not response["Datapoints"]:
        print(f"No metrics found for queue: {queue_name}")
        return 0
    latest = max(response["Datapoints"], key=lambda x: x["Timestamp"])
    return int(latest["Minimum"])


def worker_task_arns(ecs, cluster_name, family):
    """All tasks of the family that are starting or running."""
    arns = []
    for page in ecs.get_paginator("list_tasks").paginate(
        cluster=cluster_name, family=family, desiredStatus="RUNNING"
    ):
        arns.extend(page["taskArns"])
    return arns


def described(ecs, cluster_name, arns):
    tasks = []
    for i in range(0, len(arns), DESCRIBE_TASKS_BATCH):
        response = ecs.describe_tasks(
            cluster=cluster_name, tasks=arns[i : i + DESCRIBE_TASKS_BATCH]
        )
        tasks.extend(response["tasks"])
    return tasks


def is_in_flight(task, now):
    """Whether the task has not taken its share of the queued jobs yet, as far as the metric
    knows."""
    if task["lastStatus"] in IN_FLIGHT_STATUSES:
        return True
    started_at = task.get("startedAt")
    return (
        task["lastStatus"] == "RUNNING"
        and started_at is not None
        and now - started_at < RECENTLY_STARTED
    )


def tasks_to_start(queued, workers_per_task, running, in_flight, max_worker_tasks):
    needed = math.ceil(queued / workers_per_task) - in_flight
    return max(0, min(needed, max_worker_tasks - running))


def handler(event, context):
    """
    Lambda function to monitor CloudWatch queue metrics and deploy ECS tasks on demand
    """

    cloudwatch = boto3.client("cloudwatch")
    ecs = boto3.client("ecs")

    worker_name = event["worker_name"]
    task_definition = event["task_definition"]
    task_family = event["task_family"]
    workers_per_task = event["num_workers_per_task"]
    max_worker_tasks = event["max_worker_tasks"]
    capacity_provider = event["capacity_provider"]
    queues = event["queues"]
    subnets = event["subnets"]
    security_groups = event["security_groups"]

    cluster_name = os.environ["ECS_CLUSTER_NAME"]

    print(f"Processing on-demand worker: {worker_name}")
    print(f"Monitoring queues: {queues}")

    try:
        now = datetime.now(timezone.utc)
        queued = sum(queue_length(cloudwatch, queue_name, now) for queue_name in queues)
        print(f"Total queue length: {queued}")

        if queued == 0:
            print("No jobs in queues. Skipping worker deployment.")
            return {"statusCode": 200, "body": json.dumps("No jobs in queues")}

        arns = worker_task_arns(ecs, cluster_name, task_family)
        if len(arns) >= max_worker_tasks:
            print(
                f"Maximum workers ({max_worker_tasks}) already running. Skipping deployment."
            )
            return {
                "statusCode": 200,
                "body": json.dumps("Maximum workers already running"),
            }

        tasks = described(ecs, cluster_name, arns)
        in_flight = sum(1 for task in tasks if is_in_flight(task, now))
        count = tasks_to_start(
            queued, workers_per_task, len(tasks), in_flight, max_worker_tasks
        )
        print(f"Tasks: {len(tasks)}, in flight: {in_flight}, to start: {count}")

        if count == 0:
            return {"statusCode": 200, "body": json.dumps("No more workers needed")}

        capacity_provider_strategy = []
        if capacity_provider == "FARGATE":
            capacity_provider_strategy = [{"capacityProvider": "FARGATE", "weight": 1}]
        elif capacity_provider == "FARGATE_SPOT":
            capacity_provider_strategy = [
                {"capacityProvider": "FARGATE_SPOT", "weight": 1}
            ]

        run_response = ecs.run_task(
            cluster=cluster_name,
            taskDefinition=task_definition,
            count=min(count, RUN_TASK_MAX_COUNT),
            capacityProviderStrategy=capacity_provider_strategy,
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": subnets,
                    "securityGroups": security_groups,
                    "assignPublicIp": "DISABLED",
                }
            },
        )

        for failure in run_response.get("failures", []):
            print(f"Failed to deploy a worker task: {failure}")

        task_arns = [task["taskArn"] for task in run_response["tasks"]]
        if not task_arns:
            print("Failed to deploy worker task")
            return {
                "statusCode": 500,
                "body": json.dumps("Failed to deploy worker task"),
            }

        print(f"Successfully deployed on-demand worker tasks: {task_arns}")
        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Worker tasks deployed successfully",
                    "taskArns": task_arns,
                    "workerName": worker_name,
                    "totalQueueLength": queued,
                }
            ),
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"statusCode": 500, "body": json.dumps(f"Error: {str(e)}")}
