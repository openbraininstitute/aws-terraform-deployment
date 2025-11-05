import os
import json
import boto3
from datetime import datetime
from zoneinfo import ZoneInfo
from botocore.exceptions import BotoCoreError, ClientError
import urllib.request
import logging
from typing import Any, Dict, List, Optional, final

TEAMS_WEBHOOK_SECRET_NAME: str = 'TEAMS_WEBHOOK_SECRET_NAME'
TEAMS_WEBHOOK_SECRET_KEY: str = 'TEAMS_WEBHOOK_SECRET_KEY'


logger: logging.Logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client('secretsmanager')




def get_teams_webhook_url() -> str:
    if TEAMS_WEBHOOK_SECRET_NAME not in os.environ:
        raise ValueError("Missing environment variable: TEAMS_WEBHOOK_SECRET_NAME")
    secret_name: Optional[str] = os.environ.get(TEAMS_WEBHOOK_SECRET_NAME)
    if not secret_name or secret_name.strip() == "":
        raise ValueError("Environment variable empty: TEAMS_WEBHOOK_SECRET_NAME")
    if TEAMS_WEBHOOK_SECRET_KEY not in os.environ:
        raise ValueError("Missing environment variable: TEAMS_WEBHOOK_SECRET_KEY")
    secret_key: Optional[str] = os.environ.get(TEAMS_WEBHOOK_SECRET_KEY)
    if not secret_key or secret_key.strip() == "":
        raise ValueError("Environment variable empty: TEAMS_WEBHOOK_SECRET_KEY")
    try:
        secret_str = secrets_client.get_secret_value(SecretId=secret_name)['SecretString']
        secret_dict = json.loads(secret_str)
        return secret_dict[secret_key]
    except (ClientError, BotoCoreError) as e:
            logger.error("Failed to fetch secret {TEAMS_WEBHOOK_SECRET_NAME}: %s", e, exc_info=True)
            raise


def parse_eventbridge_json_to_readable_message(msg: Dict[str,Any]) -> str:
    """ Parse the raw SNS message from EventBridge and convert it to a readable format."""
    if isinstance(msg, str):
        msg = json.loads(msg)
    final_message: str = ""
    if "time" in msg:
        final_message += f"GMT time: {msg['time']}\n"
        dt_utc = datetime.fromisoformat(msg['time'])
        dt_swiss = dt_utc.astimezone(ZoneInfo("Europe/Zurich"))
        final_message += f"Swiss time: {dt_swiss}\n"
    final_message += f"Message: \n```\n{json.dumps(msg, indent=2)}\n```\n"
    return final_message    


def parse_ecs_json_to_readable_message(msg: Dict[str,Any]) -> str:
    """Parse the raw SNS message from ECS and convert it to a readable format."""
    if isinstance(msg, str):
        msg = json.loads(msg)
    # { "time": "2025-10-22T11:26:49.598302+00:00",
    #   "level": "ERROR",
    #   "name": "notebook_service.backend.eks.kubernetes_client",
    #   "message": "pod found with name: user-scheduler-65768ff8c9-brktz - dries test",
    #   "extra": {},
    #   "exception": null }",
    final_message: str = ""
    if "time" in msg:
        final_message += f"GMT time: {msg['time']}\n"
        dt_utc = datetime.fromisoformat(msg['time'])
        dt_swiss = dt_utc.astimezone(ZoneInfo("Europe/Zurich"))
        final_message += f"Swiss time: {dt_swiss}\n"
    if "name" in msg:
        final_message += f"Name: {msg['name']}\n"
    if "message" in msg:
        final_message += f"Message: {msg['message']}\n"
    if "exception" in msg:
        final_message += f"Exception: {msg['exception']}\n"
    return final_message


def handle_eventbridge_aws_error_event(event: Dict[str, Any], _) -> Dict[str, Any]:
    """Main Lambda handler for processing EventBridge AWS error events."""
    logger.info("Received event: %s", json.dumps(event))
    try:
        webhook_url = get_teams_webhook_url()
        records: List[Dict[str, Any]] = event.get("Records", [])

        for record in records:
            raw_sns_message = record.get("Sns", {}).get("Message", {})
            sns_message = parse_eventbridge_json_to_readable_message(raw_sns_message)
            logger.info("Processing SNS message: %s", sns_message[:500])  # limit log size
            send_to_teams(sns_message, webhook_url)

        return {"statusCode": 200, "body": "Messages sent to Teams."}
    
    except Exception as e:
        logger.error("Unhandled error in lambda_handler: %s", e, exc_info=True)
        return {"statusCode": 500, "body": "Failed to process SNS messages."}



def handle_log_event(event: Dict[str, Any], _) -> Dict[str, Any]:
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
