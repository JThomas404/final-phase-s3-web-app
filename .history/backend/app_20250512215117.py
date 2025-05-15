import json
import boto3
import urllib.parse
import traceback
import logging
import jwt  # Required for decoding id_token (make sure this is packaged with the Lambda)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Lambda event received: %s", json.dumps(event))

    # Handle CORS preflight
    if event.get('httpMethod') == 'OPTIONS':
        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": json.dumps("CORS preflight OK")
        }

    path = event.get('path', '')

    try:
        if path == '/contact':
            return handle_contact(event)
        elif path == '/userdata':
            return handle_userdata(event)
        else:
            logger.warning("Unhandled path: %s", path)
            return {
                "statusCode": 404,
                "headers": cors_headers(),
                "body": json.dumps({"error": "Not Found"})
            }

    except Exception as e:
        logger.error("Exception occurred: %s", str(e))
        logger.error(traceback.format_exc())
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({"error": "Internal server error"})
        }

def handle_contact(event):
    content_type = event["headers"].get("Content-Type") or event["headers"].get("content-type", "")
    body = event.get("body", "")

    if "application/json" in content_type:
        body = json.loads(body)
    elif "application/x-www-form-urlencoded" in content_type:
        parsed = urllib.parse.parse_qs(body)
        body = {k: v[0] for k, v in parsed.items()}
    else:
        logger.warning("Unsupported content type: %s", content_type)
        body = {}

    logger.info("Parsed body: %s", json.dumps(body))

    # Extract fields
    first_name = body.get("first_name")
    last_name = body.get("last_name")
    job_title = body.get("job_title")
    phone_number = body.get("phone_number")
    email = body.get("email")
    company = body.get("company")

    if not first_name or not last_name or not email:
        return {
            "statusCode": 400,
            "headers": cors_headers(),
            "body": json.dumps({"error": "First name, last name, and email are required."})
        }

    logger.info("Saving to DynamoDB: %s", email)
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("ConnectingTheDots")
    table.put_item(Item={
        "email": email,
        "first_name": first_name,
        "last_name": last_name,
        "job_title": job_title,
        "phone_number": phone_number,
        "company": company
    })

    return {
        "statusCode": 200,
        "headers": cors_headers(),
        "body": json.dumps({"message": "Contact data stored successfully"})
    }

def handle_userdata(event):
    auth_header = event['headers'].get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return {
            "statusCode": 401,
            "headers": cors_headers(),
            "body": json.dumps({"error": "Unauthorized"})
        }

    token = auth_header.replace('Bearer ', '')
    try:
        payload = jwt.decode(token, options={"verify_signature": False})
        logger.info("Decoded ID Token: %s", json.dumps(payload))

        return {
            "statusCode": 200,
            "headers": cors_headers(methods="GET,OPTIONS"),
            "body": json.dumps({
                "first_name": payload.get('given_name', ''),
                "last_name": payload.get('family_name', ''),
                "email": payload.get('email', ''),
                "picture": payload.get('picture', '')
            })
        }

    except Exception as e:
        logger.error("Failed to decode token: %s", str(e))
        return {
            "statusCode": 400,
            "headers": cors_headers(),
            "body": json.dumps({"error": "Invalid token"})
        }

def cors_headers(methods="POST,OPTIONS"):
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": methods,
        "Access-Control-Allow-Headers": "Content-Type,Authorization"
    }
