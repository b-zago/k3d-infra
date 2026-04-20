import json


def lambda_handler(event, context):
    # Authorizer invocations have "type": "REQUEST" at the top level.
    # Proxy integration invocations have a "requestContext.http" structure instead.
    is_authorizer_request = event.get("type") == "REQUEST"

    if is_authorizer_request:
        return handle_authorizer(event)
    else:
        return handle_proxy(event)


def handle_authorizer(event):
    # Payload format 2.0 simple response
    headers = event.get("headers", {})
    token = headers.get("authorization")

    if token == "secretToken":
        print("allowed")
        return {"isAuthorized": True, "context": {"user": "test"}}
    else:
        print("denied")
        return {"isAuthorized": False}


def handle_proxy(event):
    # Payload format 2.0 proxy response
    headers = event.get("headers", {})
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "message": "You made it through!",
            "path": event.get("rawPath"),
            "method": event.get("requestContext", {}).get("http", {}).get("method"),
            "auth_context": event.get("requestContext", {}).get("authorizer", {}),
        }),
    }