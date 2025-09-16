import boto3
import json
import os
from datetime import datetime, timedelta


def handler(event, context):
    """
    Lambda function to monitor CloudWatch queue metrics and deploy ECS tasks on demand
    """

    # Initialize AWS clients
    cloudwatch = boto3.client("cloudwatch")
    ecs = boto3.client("ecs")

    # Get configuration from event
    worker_name = event["worker_name"]
    task_definition = event["task_definition"]
    max_worker_tasks = event["max_worker_tasks"]
    capacity_provider = event["capacity_provider"]
    queues = event["queues"]
    subnets = event["subnets"]
    security_groups = event["security_groups"]

    cluster_name = os.environ["ECS_CLUSTER_NAME"]

    print(f"Processing on-demand worker: {worker_name}")
    print(f"Monitoring queues: {queues}")

    try:
        # Check queue lengths for all queues
        total_queue_length = 0

        for queue_name in queues:
            # Get the most recent queue length metric
            response = cloudwatch.get_metric_statistics(
                Namespace="SmallScaleSimulator/JobQueue",
                MetricName="QueueLength",
                Dimensions=[{"Name": "QueueName", "Value": queue_name}],
                StartTime=datetime.utcnow() - timedelta(minutes=5),
                EndTime=datetime.utcnow(),
                Period=300,  # 5 minutes
                Statistics=["Maximum"],
            )

            if response["Datapoints"]:
                # Get the most recent datapoint
                latest_datapoint = max(
                    response["Datapoints"], key=lambda x: x["Timestamp"]
                )
                queue_length = int(latest_datapoint["Maximum"])
                total_queue_length += queue_length
                print(f"Queue {queue_name} length: {queue_length}")
            else:
                print(f"No metrics found for queue: {queue_name}")

        print(f"Total queue length: {total_queue_length}")

        # If no jobs in queues, no need to deploy workers
        if total_queue_length == 0:
            print("No jobs in queues. Skipping worker deployment.")
            return {"statusCode": 200, "body": json.dumps("No jobs in queues")}

        # Count currently running on-demand tasks for this worker
        family_name = f"small-scale-simulator-on-demand-worker-{worker_name}"

        list_response = ecs.list_tasks(
            cluster=cluster_name, family=family_name, desiredStatus="RUNNING"
        )

        running_tasks = len(list_response["taskArns"])
        print(f"Currently running on-demand tasks: {running_tasks}")

        # Check if we've reached the maximum
        if running_tasks >= max_worker_tasks:
            print(
                f"Maximum workers ({max_worker_tasks}) already running. Skipping deployment."
            )
            return {
                "statusCode": 200,
                "body": json.dumps("Maximum workers already running"),
            }

        # Deploy a new task
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
            capacityProviderStrategy=capacity_provider_strategy,
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": subnets,
                    "securityGroups": security_groups,
                    "assignPublicIp": "DISABLED",
                }
            },
            tags=[
                {"key": "WorkerType", "value": f"on-demand-{worker_name}"},
                {"key": "LaunchedBy", "value": "lambda"},
            ],
        )

        if run_response["tasks"]:
            task_arn = run_response["tasks"][0]["taskArn"]
            print(f"Successfully deployed on-demand worker task: {task_arn}")

            return {
                "statusCode": 200,
                "body": json.dumps(
                    {
                        "message": "Worker task deployed successfully",
                        "taskArn": task_arn,
                        "workerName": worker_name,
                        "totalQueueLength": total_queue_length,
                    }
                ),
            }
        else:
            print("Failed to deploy worker task")
            return {
                "statusCode": 500,
                "body": json.dumps("Failed to deploy worker task"),
            }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"statusCode": 500, "body": json.dumps(f"Error: {str(e)}")}
