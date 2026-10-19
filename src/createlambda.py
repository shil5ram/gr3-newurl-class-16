import os
import json
import boto3
from string import ascii_letters, digits
from random import choice, randint
from time import strftime, time
from urllib import parse

app_url = os.getenv('APP_URL')
min_char = int(os.getenv('MIN_CHAR', 12))
max_char = int(os.getenv('MAX_CHAR', 16))
region_aws = os.getenv('REGION_AWS')
db_tablename = os.getenv('DB_NAME')
string_format = ascii_letters + digits

ddb = boto3.resource('dynamodb', region_name=region_aws).Table(db_tablename)

def generate_timestamp():
    return strftime("%Y-%m-%dT%H:%M:%S")

def expiry_date():
    return int(time()) + 604800

def check_id(short_id):
    if 'Item' in ddb.get_item(Key={'short_id': short_id}):
        return generate_id()
    return short_id

def generate_id():
    short_id = "".join(choice(string_format) for _ in range(randint(min_char, max_char)))
    return check_id(short_id)

def lambda_handler(event, context):
    analytics = {}
    short_id = generate_id()
    short_url = app_url + short_id
    
    try:
        body = json.loads(event.get('body', '{}'))
        long_url = body.get('long_url')
    except Exception:
        return {'statusCode': 400, 'body': json.dumps({'error': 'Invalid JSON body'})}

    if not long_url:
        return {'statusCode': 400, 'body': json.dumps({'error': 'Missing long_url'})}

    timestamp = generate_timestamp()
    ttl_value = expiry_date()
   
    headers = event.get('headers', {}) or {}
    analytics['user_agent'] = headers.get('User-Agent')
    analytics['source_ip'] = headers.get('X-Forwarded-For')
    analytics['xray_trace_id'] = headers.get('X-Amzn-Trace-Id')
   
    parsed_query = parse.urlsplit(long_url).query
    if len(parsed_query) > 0:
        url_params = dict(parse.parse_qsl(parsed_query))
        for k, v in url_params.items():
            analytics[k] = v

    ddb.put_item(
        Item={
            'short_id': short_id,
            'created_at': timestamp,
            'ttl': int(ttl_value),
            'short_url': short_url,
            'long_url': long_url,
            'analytics': analytics,
            'hits': int(0)
        }
    )
   
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"short_url": short_url, "short_id": short_id})
    }
