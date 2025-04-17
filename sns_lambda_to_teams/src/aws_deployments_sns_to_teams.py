import os
import json
import boto3
from botocore.exceptions import BotoCoreError, ClientError
import urllib.request
import logging
from typing import Any, Dict, List, Optional

TEAMS_WEBHOOK_SECRET_NAME: str = 'TEAMS_WEBHOOK_SECRET_NAME'

logger: logging.Logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client('secretsmanager')




def get_teams_webhook_url() -> str:
    if TEAMS_WEBHOOK_SECRET_NAME not in os.environ:
        raise ValueError(f"Missing environment variable: {TEAMS_WEBHOOK_SECRET_NAME}")
    secret_name: Optional[str] = os.environ.get(TEAMS_WEBHOOK_SECRET_NAME)
    if not secret_name or secret_name.strip() == "":
        raise ValueError(f"Environment variable empty: {TEAMS_WEBHOOK_SECRET_NAME}")
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)['SecretString']
        return response
    except (ClientError, BotoCoreError) as e:
            logger.error("Failed to fetch secret {TEAMS_WEBHOOK_SECRET_NAME}: %s", e, exc_info=True)
            raise


def parse_ecs_json_to_readable_message(msg: Dict[str,Any]) -> str:
    """Parse the raw SNS message from ECS and convert it to a readable format."""
    if isinstance(msg, str):
        msg = json.loads(msg)
    final_message: str = ""
    if "detail-type" in msg:
        final_message += f"Event Type: {msg['detail-type']}\n"
    if "detail" in msg and "status" in msg["detail"]:
        final_message += f"Status: {msg['detail']['status']}\n"
    if "detail" in msg and "clusterArn" in msg["detail"]:
        final_message += f"Cluster ARN: {msg['detail']['clusterArn']}\n"
    if "detail" in msg and "veersion" in msg["detail"]:
        final_message += f"Version: {msg['detail']['version']}\n"
    if "detail" in msg and "eventType" in msg["detail"]:
        final_message += f"Event Type: {msg['detail']['eventType']}\n"
    if "detail" in msg and "eventName" in msg["detail"]:
        final_message += f"Event Name: {msg['detail']['eventName']}\n"
    if "detail" in msg and "reason" in msg["detail"]:
        final_message += f"Reason: {msg['detail']['reason']}\n"
    if "detail" in msg and "lastStatus" in msg["detail"]:
        final_message += f"Last Status: {msg['detail']['lastStatus']}\n"
    if "detail" in msg and "connectivity" in msg["detail"]:
        final_message += f"Connectivity: {msg['detail']['connectivity']}\n"
    if "detail" in msg and "attachments" in msg["detail"]:
        attachments = msg["detail"]["attachments"]
        if isinstance(attachments, list):
            for attachment in attachments:
                att_type = attachment.get("type", "Unknown")
                att_status = attachment.get("status", "Unknown")
                final_message += f"Attachment of type {att_type}: {att_status}\n"
    if "detail" in msg and "containers" in msg["detail"]:
        containers = msg["detail"]["containers"]
        if isinstance(containers, list):
            for num, container in enumerate(containers):
                container_image = container.get("image", "Unknown")
                container_status = container.get("status", "Unknown")
                container_last_status = container.get("lastStatus", "Unknown")
                final_message += f"Container {num} status: {container_status} last status: {container_last_status}, image: {container_image}\n"

    if "runningTasksCount" in msg:
        final_message += f"Running Tasks Count: {msg['runningTasksCount']}\n"
    return final_message


def handle_deployment_event(event: Dict[str, Any], _) -> Dict[str, Any]:
    """Main Lambda handler for processing SNS events."""
    logger.info("Received event: %s", json.dumps(event))

    try:
        webhook_url = get_teams_webhook_url()
        records: List[Dict[str, Any]] = event.get("Records", [])

        for record in records:
            raw_sns_message = record.get("Sns", {}).get("Message", {})
            sns_message = parse_ecs_json_to_readable_message(raw_sns_message)
            logger.info("Processing SNS message: %s", sns_message[:500])  # limit log size
            send_to_teams(sns_message, webhook_url)

        return {"statusCode": 200, "body": "Messages sent to Teams."}
    
    except Exception as e:
        logger.error("Unhandled error in lambda_handler: %s", e, exc_info=True)
        return {"statusCode": 500, "body": "Failed to process SNS messages."}

def send_to_teams(message: str, webhook_url: str) -> None:
    """Send a simple text message to a Microsoft Teams channel."""
    headers = {'Content-Type': 'application/json'}
    # TODO ugly hack: apparently teams expects markdown, so 2 newlines to get separate lines
    message = message.replace('\n', '\n\n')
    teams_payload = {
        'text': f"{message}"
    }

    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(teams_payload).encode('utf-8'),
        headers=headers
    )
    try:
        with urllib.request.urlopen(req) as response:
            logger.info("Message sent to Teams, response code: %s", response.getcode())
    except Exception as e:
        logger.error("Failed to send message to Teams: %s", e, exc_info=True)
        raise