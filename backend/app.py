import json
import boto3
import urllib.parse

def lambda_handler(event, context):
    if event['httpMethod'] == 'OPTIONS':
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            "body": json.dumps("CORS preflight response")
        }

    try:
        content_type = event["headers"].get("Content-Type") or event["headers"].get("content-type", "")

        if "application/json" in content_type:
            body = json.loads(event.get("body", "{}"))
        elif "application/x-www-form-urlencoded" in content_type:
            body = urllib.parse.parse_qs(event.get("body", ""))
            body = {k: v[0] for k, v in body.items()}
        else:
            body = {}

        first_name = body.get("first_name")
        last_name = body.get("last_name")
        job_title = body.get("job_title")
        phone_number = body.get("phone_number")
        email = body.get("email")
        company = body.get("company")

        if not first_name or not last_name or not email:
            return {
                "statusCode": 400,
                "headers": {
                    "Access-Control-Allow-Origin": "*"
                },
                "body": json.dumps({"error": "Required fields are missing"})
            }

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
            "headers": {
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"message": "Contact data stored successfully"})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": str(e)})
        }
