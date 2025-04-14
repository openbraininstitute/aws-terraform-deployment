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


def handle(event: Dict[str, Any], _) -> Dict[str, Any]:
    """Main Lambda handler for processing SNS events."""
    logger.info("Received event: %s", json.dumps(event))

    try:
        webhook_url = get_teams_webhook_url()
        records: List[Dict[str, Any]] = event.get("Records", [])

        for record in records:
            sns_message = record.get("Sns", {}).get("Message", "")
            logger.info("Processing SNS message: %s", sns_message[:500])  # limit log size
            send_to_teams(sns_message, webhook_url)

        return {"statusCode": 200, "body": "Messages sent to Teams."}
    
    except Exception as e:
        logger.error("Unhandled error in lambda_handler: %s", e, exc_info=True)
        return {"statusCode": 500, "body": "Failed to process SNS messages."}

def send_to_teams(message: str, webhook_url: str) -> None:
    """Send a simple text message to a Microsoft Teams channel."""
    headers = {'Content-Type': 'application/json'}
    teams_payload = {
        'text': f"New SNS message received:\n\n{message}"
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