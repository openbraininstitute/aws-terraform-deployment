import json
import boto3

ecs = boto3.client('ecs')

def lambda_handler(event, context):

    command = ['run','--s3','--config','ship.conf','--path', event['EXPORT_FILE_PATH']]

    if 'OFFSET' in event:
        command = command + ['--offset', event['OFFSET']]

    print('The command is {}'.format(command))

    response = ecs.run_task(
        cluster='nexus_ecs_cluster',
        taskDefinition='nexus_ship_task_family',
        launchType='FARGATE',
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': ['subnet-0ea70750833d08f39'], # nexus_a subnet
                'securityGroups': ['sg-074f3f141431ea8b7'], # main_nexus_sg
                'assignPublicIp': 'DISABLED'
            }
        },
        overrides={
            'containerOverrides': [
                {
                    'name': 'nexus_ship',
                    'command': command,
                    'environment': [
                        {
                            'name': 'POSTGRES_DATABASE',
                            'value': event['POSTGRES_DATABASE']
                        },
                        {
                            'name': 'POSTGRES_HOST',
                            'value': event['POSTGRES_HOST']
                        },
                        {
                            'name': 'POSTGRES_USERNAME',
                            'value': event['POSTGRES_USERNAME']
                        },
                        {
                            'name': 'TARGET_BASE_URI',
                            'value': event['TARGET_BASE_URI']
                        },
                        {
                            'name': 'TARGET_BUCKET',
                            'value': event['TARGET_BUCKET']
                        }

                    ]
                }
            ]
        }
    )

    print(response)

    return {
        'statusCode': 200,
        'body': json.dumps('The lambda has reached its end')
    }
