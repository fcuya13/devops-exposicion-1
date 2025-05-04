import boto3
import json

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('equipos')
    
    # Initial data for teams
    equipos = [
        {
            'equipo': 'Universitario',
            'campeonatos': 28
        },
        {
            'equipo': 'Alianza Lima',
            'campeonatos': 25
        },
        {
            'equipo': 'Sporting Cristal',
            'campeonatos': 20
        },
        {
            'equipo': 'Sport Boys',
            'campeonatos': 6
        },
        {
            'equipo': 'FBC Melgar',
            'campeonatos': 3
        }
    ]
    
    # Insert items into DynamoDB
    with table.batch_writer() as batch:
        for equipo in equipos:
            batch.put_item(Item=equipo)
    
    return {
        'statusCode': 200,
        'body': json.dumps('Data seeded successfully!')
    } 