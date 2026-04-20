import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "received_event": event,
            "function_name": context.function_name,
            "request_id": context.aws_request_id,
            "remaining_time_ms": context.get_remaining_time_in_millis(),
        }),
    }
