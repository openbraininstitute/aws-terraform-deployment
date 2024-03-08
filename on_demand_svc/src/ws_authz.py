import json
from ipaddress import ip_network, ip_address


def do(event, context):
    headers = event["headers"]
    ip = ip_address(headers["X-Forwarded-For"])
    epfl_cidr = ip_network("128.178.0.0/15", False)

    # FIXME add proper keycloak authz
    if (ip in epfl_cidr and headers["Authorization"].startswith("Bearer ")):
        return json.loads(generateAllow("me", event["methodArn"]))

    return json.loads(generateDeny("me", event["methodArn"]))


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

    # FIXME get user vlab/proj
    authResponse["context"] = {"SVC_VLAB": "O1_data_physiology_sep11"}

    return json.dumps(authResponse)


def generateAllow(principalId, resource):
    return generatePolicy(principalId, "Allow", resource)


def generateDeny(principalId, resource):
    return generatePolicy(principalId, "Deny", resource)
