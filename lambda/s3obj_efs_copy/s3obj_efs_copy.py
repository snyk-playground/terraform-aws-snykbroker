import boto3
from botocore.exceptions import ClientError
import os

BASE_DIR = "/mnt/shared"


def lambda_handler(event, context):
    """
    Handler to inject private key and cert (.crt) from S3 bucket to EFS volume mounted at BASE_DIR
    :param event: lambda event (map)
    :param context: lambda context
    :return: None
    """
    try:
        download_objects(event)
        print(f"Directory listing of {BASE_DIR}:\n {os.listdir(BASE_DIR)}")
    except Exception as e:
        print(f"Exception at copying s3 objects to efs directory {BASE_DIR}: {str(e)}")


def download_objects(event):
    """
    Downloads s3 objects to the efs mounted directory
    :param event: lambda event
    :return:
    """
    session = boto3.session.Session()
    s3_client = session.client('s3')

    try:
        bucket_name = event['bucket_name']
        objects = event['s3_objects']

        for obj in objects:
            # split the s3 key in case it is nested within s3 folders
            object_name = obj.split("/")[-1]
            filename = os.path.join(BASE_DIR, object_name)
            s3_client.download_file(bucket_name, obj, filename)
    except ClientError as ce:
        raise Exception("boto3 client error in download_objects:" + str(ce))
    except Exception as e:
        raise Exception("exception at download_objects:" + str(e))
