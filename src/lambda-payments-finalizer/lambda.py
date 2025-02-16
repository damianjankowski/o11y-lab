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

            # Simulate configuration
            simulate_fin = detail.get("simulate", {}).get("fin", {})
            latency = simulate_fin.get("latency", 0)
            if latency > 0:
                logger.info(f"Simulating finalization latency for {latency} seconds")
                time.sleep(latency)

            # Simulate DB error
            if simulate_fin.get("db_error", False):
                logger.error("Simulated DB error (finalizer) triggered")
                raise Exception("Simulated DB error (finalizer)")

            # Simulate payment authorization
            final_status = random.choice(["Success", "Failure"])
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
                    ":timestamp": str(datetime.datetime.now(datetime.timezone.utc)),
                    ":ttl": ttl_timestamp
                },
            )

            # Simulate 500 error
            if simulate_fin.get("error_500", False):
                logger.error("Simulated 500 error (finalizer) triggered")
                raise Exception("Simulated 500 error (finalizer)")

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
