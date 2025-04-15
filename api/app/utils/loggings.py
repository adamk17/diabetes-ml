import logging
import boto3
import watchtower
from datetime import datetime, timezone

def setup_logging(config):
    # Primary log configuration
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    logger = logging.getLogger('diabetes-ml')
    
     # Add optional Cloudwatch as log handler
    if config.enable_cloudwatch:
        try:
            cloudwatch_handler = watchtower.CloudWatchLogHandler(
                log_group=config.cloudwatch_log_group,
                stream_name=datetime.now(timezone.utc).strftime("%Y-%m-%d-%H-%M-%S"),
                boto3_session=boto3.Session()
            )
            logger.addHandler(cloudwatch_handler)
            logger.info("CloudWatch logging enabled")
        except Exception as e:
            logger.warning(f"Failed to initialize CloudWatch logging: {e}")
    
    return logger