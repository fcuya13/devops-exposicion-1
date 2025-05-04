import boto3
import json
from decimal import Decimal

# Helper class to convert Decimal to int/float
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('equipos')
    
    try:
        # Scan the table to get all items
        response = table.scan()
        items = response['Items']
        
        # Sort teams by number of championships (descending)
        items.sort(key=lambda x: x['campeonatos'], reverse=True)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # Enable CORS
            },
            'body': json.dumps(items, cls=DecimalEncoder)  # Use custom encoder
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # Enable CORS
            },
            'body': json.dumps({'error': str(e)})
        }