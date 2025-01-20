import json
import boto3
import logging
import time
import datetime
import random
from loguru import logger

class Config():
    marker = "o11y-lab"
    initializer_table_name = "ShowMeTheMoney"
    finalizer_table_name = "BreakingTheBank"
    time_to_distroy = 2 * 60 * 60

# Configure loguru
logger.remove()
logger.add(
    sink=lambda msg: print(json.dumps(msg, ensure_ascii=False)),
    serialize=True,
    level="INFO",
    format="{time} - o11y-lab - {level} - {message}",
)

def handler(event, context):
    config = Config()
    dynamodb = boto3.resource("dynamodb")

    try:
        logger.info("Received event: %s", json.dumps(event))

        if 'detail-type' in event and 'source' in event:
            detail = event.get('detail', {})
            payment_id = detail.get('payment_id')
            if not payment_id:
                logger.error("Missing payment_id in event detail")
                return {"statusCode": 400, "body": json.dumps({"message": "Bad Request"})}

            final_status = random.choice(["Success", "Failure"])  # simulate payment authorization

            ttl_timestamp = int(time.time()) + config.time_to_distroy

            table = dynamodb.Table(config.finalizer_table_name)
            table.update_item(
                Key={"PaymentID": payment_id},
                UpdateExpression="set #s = :status, #t = :timestamp, #ttl = :ttl",
                ExpressionAttributeNames={
                    "#s": "Status",
                    "#t": "Timestamp",
                    "#ttl": "ttl_timestamp"
                },
                ExpressionAttributeValues={
                    ":status": final_status,
                    ":timestamp": str(datetime.datetime.now(datetime.UTC)),
                    ":ttl": ttl_timestamp
                },
            )

            logger.info(
                "Payment %s updated with status %s and TTL %d",
                payment_id,
                final_status,
                ttl_timestamp
            )

            return {"statusCode": 200, "body": json.dumps({"message": "Payment finalized"})}
        else:
            logger.error("Invalid event structure")
            return {"statusCode": 400, "body": json.dumps({"message": "Bad Request"})}
    except Exception as err:
        logger.error("Failed to finalize payment: %s", str(err))
        return {"statusCode": 500, "body": json.dumps({"message": "Internal Server Error"})}
