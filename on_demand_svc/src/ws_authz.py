def do(event, context):
    headers = event["headers"]
    token = headers.get("Sec-WebSocket-Protocol", "").replace("Bearer-", "Bearer ")

    # FIXME add proper keycloak authz
    if token.startswith("Bearer "):
        authResponse = generateAllow("me", event["methodArn"])
        # FIXME get user vlab/proj
        authResponse["context"] = {
            "SVC_VLAB": "dummy-vlab-id",
            "TOKEN": token,
        }
        return authResponse

    return generateDeny("me", event["methodArn"])


def generatePolicy(principalId, effect, resource):
    authResponse = {}
    authResponse["principalId"] = principalId
    if effect and resource:
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
