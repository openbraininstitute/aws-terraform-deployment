import os
import json
import logging
from ipaddress import ip_network, ip_address
from urllib.request import urlopen, Request
from urllib.error import URLError

L = logging.getLogger()
L.setLevel(logging.INFO)


def generatePolicy(principalId, effect, resource):
    authResponse = {}
    authResponse["principalId"] = principalId
    if (effect and resource):
        policyDocument = {}
        policyDocument["Version"] = "2012-10-17"
        policyDocument["Statement"] = []
        statementOne = {}
        statementOne["Action"] = "execute-api:Invoke"
        statementOne["Effect"] = effect
        statementOne["Resource"] = resource
        policyDocument["Statement"] = [statementOne]
        authResponse["policyDocument"] = policyDocument

    return authResponse


def generateAllow(principalId, resource):
    return generatePolicy(principalId, "Allow", resource)


def generateDeny(principalId, resource):
    return generatePolicy(principalId, "Deny", resource)


def token(event, context):
    """AWS Lambda authorizer function that validates a JWT token against the keycloak endpoint.

    Args:
        event (dict): Lambda event containing:
            - identitySource[0]: JWT token to validate
            - headers: Request headers
            - routeArn: AWS resource ARN for the API route
        context (LambdaContext): AWS Lambda context object (unused)

    Returns:
        dict: IAM policy response with structure:
            - Allow: Grants access if token is valid, includes KC_SUB in context
            - Deny: Denies access if token is invalid or validation fails
    """
    token = event["identitySource"][0]
    headers = event["headers"]
    route_arn = event["routeArn"]

    user_info = os.environ["USER_INFO"]

    if not user_info:
        return generateDeny("me", route_arn)

    try:
        request = Request(user_info, headers={"authorization": token})
    except URLError:
        return generateDeny("me", route_arn)

    try:
        with urlopen(request, timeout=2) as response:
            sub = json.load(response)["sub"]
    except (HTTPError, json.JSONDecodeError, KeyError):
        return generateDeny("me", route_arn)

    authResponse = generateAllow("me", route_arn)
    authResponse["context"] = {"KC_SUB": sub}

    return authResponse


def get_session_id(cookies: str) -> str | None:
    """Get session id cookie value."""
    session_id = None
    # if multivalued, take the last one
    for cookie in cookies.split(";"):
        name, value = cookie.strip().split("=")
        if name.strip() == "sessionid":
            session_id = value.strip()
    return session_id


def cookie(event, context):
    session_id = get_session_id(event["identitySource"][0])
    if session_id:
        authResponse = generateAllow("me", event["routeArn"])
        authResponse["context"] = {"SESSION_ID": session_id}
        return authResponse
    return generateDeny("me", event["routeArn"])
