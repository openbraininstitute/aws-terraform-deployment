import os
import json
import boto3
from datetime import datetime
from zoneinfo import ZoneInfo
from botocore.exceptions import BotoCoreError, ClientError
import urllib.request
import logging
from typing import Any, Dict, List, Optional

TEAMS_WEBHOOK_SECRET_NAME: str = 'TEAMS_WEBHOOK_SECRET_NAME'
TEAMS_WEBHOOK_SECRET_KEY_IMPORTANT_MESSAGES: str = 'TEAMS_WEBHOOK_SECRET_KEY'
TEAMS_WEBHOOK_SECRET_KEY_UNIMPORTANT_MESSAGES: str = 'TEAMS_WEBHOOK_SECRET_KEY_UNIMPORTANT'


logger: logging.Logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client('secretsmanager')


def get_secret_by_name_and_key(env_var_with_name: str, env_var_with_key: str) -> str:
    if env_var_with_name not in os.environ:
        raise ValueError(f"Missing environment variable: {env_var_with_name}")
    secret_name: Optional[str] = os.environ.get(env_var_with_name)
    if not secret_name or secret_name.strip() == "":
        raise ValueError(f"Environment variable empty: {env_var_with_name}")
    if env_var_with_key not in os.environ:
        raise ValueError(f"Missing environment variable: {env_var_with_key}")
    secret_key: Optional[str] = os.environ.get(env_var_with_key)
    if not secret_key or secret_key.strip() == "":
        raise ValueError(f"Environment variable empty: {env_var_with_key}")
    try:
        secret_str = secrets_client.get_secret_value(SecretId=secret_name)['SecretString']
        secret_dict = json.loads(secret_str)
        return secret_dict[secret_key]
    except (ClientError, BotoCoreError) as e:
            logger.error(f"Failed to fetch secret {env_var_with_name} with key {env_var_with_key}", e, exc_info=True)
            raise


def parse_eventbridge_json_to_readable_message(msg: Dict[str,Any]) -> str:
    """ Parse the raw SNS message from EventBridge and convert it to a readable format."""
    if isinstance(msg, str):
        msg = json.loads(msg)
    # In case it's a cost anomaly message, don't bother with the original message but only log some fields
    if 'source' in msg and msg['source'] == 'aws.ce':
        logger.info("aws.ce message, cost anomaly => replacing the message")
        dimensionValue = msg['detail']['dimensionValue']
        totalActualSpend = msg['detail']['impact']['totalActualSpend']
        anomalyDetailsLink = msg['detail']['anomalyDetailsLink']
        dt_utc = datetime.fromisoformat(msg['time'])
        dt_swiss = dt_utc.astimezone(ZoneInfo("Europe/Zurich"))
        final_message = f"Swiss time: {dt_swiss}\n\n" + \
            f"Total actual spend: {totalActualSpend}\n\n" + \
            f"Anomaly details link: {anomalyDetailsLink}\n\n" + \
            f"Dimension value: {dimensionValue}\n\n"
        return final_message
    else:
        # all other types of messages
        final_message: str = ""
        if "time" in msg:
            final_message += f"GMT time: {msg['time']}\n\n"
            dt_utc = datetime.fromisoformat(msg['time'])
            dt_swiss = dt_utc.astimezone(ZoneInfo("Europe/Zurich"))
            final_message += f"Swiss time: {dt_swiss}\n\n"
        final_message += f"Message:\n\n```\n{json.dumps(msg, indent=2)}\n```\n"
        return final_message    


def parse_log_event_json_to_readable_message(msg: Dict[str,Any]) -> str:
    """Parse the raw SNS message from ECS and convert it to a readable format."""
    # { "time": "2025-10-22T11:26:49.598302+00:00",
    #   "level": "ERROR",
    #   "name": "notebook_service.backend.eks.kubernetes_client",
    #   "message": "pod found with name: user-scheduler-65768ff8c9-brktz - dries test",
    #   "extra": {},
    #   "exception": null }",
    final_message: str = ""
    if "time" in msg:
        final_message += f"GMT time: {msg['time']}\n\n"
        dt_utc = datetime.fromisoformat(msg['time'])
        dt_swiss = dt_utc.astimezone(ZoneInfo("Europe/Zurich"))
        final_message += f"Swiss time: {dt_swiss}\n\n"
    if "name" in msg:
        final_message += f"Name: {msg['name']}\n\n"
    if "message" in msg:
        final_message += f"Message: {msg['message']}\n\n"
    if "exception" in msg:
        final_message += f"Exception: {msg['exception']}\n\n"
    return final_message

def handle_eventbridge_cost_anomaly_event(event: Dict[str, Any], _) -> Dict[str, Any]:
    """Main Lambda handler for processing EventBridge AWS cost anomaly events."""
    return generic_handle_eventbridge_event_with_single_channel(event)


def handle_eventbridge_aws_error_event(event: Dict[str, Any], _) -> Dict[str, Any]:
    """Main Lambda handler for processing EventBridge AWS error events."""
    return generic_handle_eventbridge_event_with_single_channel(event)

def handle_eventbridge_ses_event(event: Dict[str, Any], _) -> Dict[str, Any]:
    """Main Lambda handler for processing EventBridge AWS error events."""
    return generic_handle_eventbridge_event_with_single_channel(event)


def generic_handle_eventbridge_event_with_single_channel(event: Dict[str, Any])  -> Dict[str, Any]:
    logger.info("Received event: %s", json.dumps(event))
    try:
        webhook_url = get_secret_by_name_and_key(TEAMS_WEBHOOK_SECRET_NAME, TEAMS_WEBHOOK_SECRET_KEY_IMPORTANT_MESSAGES)
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


def is_important_sns_message(sns_message: Dict[str, Any], log_source_name: str) -> bool:
    """Check if the SNS message is important."""
    if 'message' in sns_message and 'installHook.js.map' in sns_message['message']:
        return False
    if 'message' in sns_message and 'NOT_AUTHENTICATED' in sns_message['message'] and log_source_name == 'entity_core':
        return False
    return True


def handle_log_event(event: Dict[str, Any], _) -> Dict[str, Any]:
    """Main Lambda handler for processing SNS events."""
    logger.info("Received event: %s", json.dumps(event))

    try:
        webhook_url_important = get_secret_by_name_and_key(TEAMS_WEBHOOK_SECRET_NAME, TEAMS_WEBHOOK_SECRET_KEY_IMPORTANT_MESSAGES)
        webhook_url_unimportant = get_secret_by_name_and_key(TEAMS_WEBHOOK_SECRET_NAME, TEAMS_WEBHOOK_SECRET_KEY_UNIMPORTANT_MESSAGES)
        if 'UNIQUE_SHORT_NAME' not in os.environ:
            raise ValueError("Missing environment variable: UNIQUE_SHORT_NAME")
        log_source_name = os.environ.get('UNIQUE_SHORT_NAME', "")
        records: List[Dict[str, Any]] = event.get("Records", [])

        for record in records:
            raw_sns_message = record.get("Sns", {}).get("Message", {})
            if isinstance(raw_sns_message, str):
                raw_sns_message = json.loads(raw_sns_message)
            sns_message = parse_log_event_json_to_readable_message(raw_sns_message)
            logger.info("Processing SNS message: %s", sns_message[:500])  # limit log size
            if is_important_sns_message(raw_sns_message, log_source_name):
                send_to_teams(sns_message, webhook_url_important)
            else:
                send_to_teams(sns_message, webhook_url_unimportant)

        return {"statusCode": 200, "body": "Messages sent to Teams."}
    
    except Exception as e:
        logger.error("Unhandled error in lambda_handler: %s", e, exc_info=True)
        return {"statusCode": 500, "body": "Failed to process SNS messages."}

def send_to_teams(message: str, webhook_url: str) -> None:
    """Send a simple text message to a Microsoft Teams channel."""
    headers = {'Content-Type': 'application/json'}
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
