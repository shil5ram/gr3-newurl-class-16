import os
import json
import boto3

region_aws = os.getenv('REGION_AWS')
db_tablename = os.getenv('DB_NAME')
ddb = boto3.resource('dynamodb', region_name=region_aws).Table(db_tablename)

def lambda_handler(event, context):
    path_params = event.get('pathParameters', {}) or {}
    short_id = path_params.get('short_id')
    
    if not short_id:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing short_id in path parameters'})
        }
   
    try:
        item = ddb.get_item(Key={'short_id': short_id})
        if 'Item' not in item:
            raise ValueError("ID not found")
            
        long_url = item.get('Item').get('long_url')
        ddb.update_item(
            Key={'short_id': short_id},
            UpdateExpression='set hits = hits + :val',
            ExpressionAttributeValues={':val': 1}
        )
   
    except Exception:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Short URL invalid or expired.'})
        }
   
    return {
        "statusCode": 302,
        "headers": {
            "Location": long_url,
            "Access-Control-Allow-Origin": "*"
        },
        "body": ""
    }
