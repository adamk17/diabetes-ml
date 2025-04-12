import boto3
import os
import sys
from dotenv import load_dotenv
from botocore.exceptions import ClientError

def main():
    try:
        # Load data from .env
        if not load_dotenv():
            print("Could not find .env file or it's empty")
            return False

        # Get data from .env
        bucket = os.getenv("MODEL_BUCKET")
        prefix = os.getenv("MODEL_PREFIX")
        region = os.getenv("AWS_REGION")
        access_key = os.getenv("AWS_ACCESS_KEY_ID")
        secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")

        # Validate required environment variables
        if not bucket:
            print("Error: MODEL_BUCKET variable is not defined in .env file")
            return False
            
        if not prefix:
            print("Warning: MODEL_PREFIX variable is not defined in .env file")
            prefix = "tf_model"  # Set default value only when not in .env
            
        if not region:
            print("Warning: AWS_REGION variable is not defined in .env file")
            region = "eu-central-1"  # Set default value only when not in .env

        if not access_key or not secret_key:
            print("Error: AWS access keys missing in .env file")
            return False

        # Initialize AWS session
        try:
            session = boto3.session.Session(
                aws_access_key_id=access_key,
                aws_secret_access_key=secret_key,
                region_name=region
            )
            s3 = session.client("s3")
        except Exception as e:
            print(f"Error initializing AWS session: {str(e)}")
            return False

        # List of files to upload
        files_to_upload = [
            {"local_path": "./trained_model/tf_model.h5", "key": f"{prefix}/model.h5"},
            {"local_path": "./trained_model/scaler.pkl", "key": f"{prefix}/scaler.pkl"}
        ]

        # Upload files
        success = True
        for file_info in files_to_upload:
            if not upload_file(s3, bucket, file_info["local_path"], file_info["key"]):
                success = False

        if success:
            print("All files successfully uploaded!")
            return True
        else:
            print("Errors occurred while uploading some files.")
            return False

    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return False

def upload_file(s3_client, bucket, local_path, key):
    """
    Uploads a file to S3
    Returns True if upload was successful, False otherwise
    """
    try:
        # Check if file exists
        if not os.path.exists(local_path):
            print(f"Error: File {local_path} does not exist")
            return False

        print(f"Uploading {local_path} → s3://{bucket}/{key}")
        s3_client.upload_file(local_path, bucket, key)
        
        # Verify file was uploaded
        try:
            s3_client.head_object(Bucket=bucket, Key=key)
            print(f"✅ File {key} was successfully uploaded")
            return True
        except ClientError:
            print(f"❌ Could not verify if file {key} was uploaded")
            return False
            
    except ClientError as e:
        print(f"AWS error while uploading {local_path}: {str(e)}")
        return False
    except Exception as e:
        print(f"Unexpected error while uploading {local_path}: {str(e)}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)