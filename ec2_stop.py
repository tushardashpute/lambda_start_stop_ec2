import boto3
region = 'us-east-1'
instances = ['i-079f0f08515777306']
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=instances)
    print('stop your instances: ' + str(instances))