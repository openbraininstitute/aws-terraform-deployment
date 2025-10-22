import os, json, gzip, base64, boto3  # noqa: E401

sns = boto3.client("sns")
TOPIC_ARN = os.environ["TOPIC_ARN"]

def handle_log_event(event, _):
    payload = base64.b64decode(event["awslogs"]["data"])
    data = json.loads(gzip.decompress(payload))
    for e in data.get("logEvents", []):
        sns.publish(
            TopicArn=TOPIC_ARN,
            Message=e.get("message", "")
        )
    return {"sent": len(data.get("logEvents", []))}
