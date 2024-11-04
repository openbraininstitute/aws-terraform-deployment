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
    token = event["identitySource"][0]
    headers = event["headers"]
    ip = ip_address(headers["x-forwarded-for"])
    epfl_cidr = ip_network("128.178.0.0/15", False)
    bbp_dmz_cidr = ip_network("192.33.211.0/26", False)

    if ip in epfl_cidr or ip in bbp_dmz_cidr:
        user_info = os.environ["USER_INFO"]
        with urlopen(Request(user_info, headers={"authorization": token}), timeout=2) as response:
            sub = json.load(response)["sub"]
            authResponse = generateAllow("me", event["routeArn"])
            authResponse["context"] = {"KC_SUB": sub}
            return authResponse
    return generateDeny("me", event["routeArn"])


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
