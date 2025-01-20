import datetime
import json
import time
import boto3
from loguru import logger
from opentelemetry import trace
from opentelemetry.instrumentation.logging import LoggingInstrumentor
from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.propagate import inject


# OpenTelemetry setup
provider = TracerProvider()
processor = BatchSpanProcessor(ConsoleSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

LoggingInstrumentor().instrument(set_logging_format=True)

# Configure loguru
logger.remove()
logger.add(
    sink=lambda msg: print(json.dumps(msg, ensure_ascii=False)),
    serialize=True,
    level="INFO",
    format="{time} - o11y-lab - {level} - {message}",
)

class Config:
    table_name = "ShowMeTheMoney"
    time_to_distroy = 2 * 60 * 60
    event_bus_name = "o11y-lab-event-bus"
    source = "payments.initializator"
    detail_type = "payment.initiated"

def record_error(span, error):
    span.record_exception(error)
    span.set_attribute("error.type", type(error).__name__)
    span.set_attribute("error.message", str(error))

def create_headers():
    inject(headers := {})
    headers.update({
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    })
    return headers

def handler(event, context):
    dynamodb_resource = boto3.resource("dynamodb")
    event_bridge = boto3.client('events')
    config = Config()
    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span("payment.initialize") as span:
        logger.info(f"Received event: {event}")
        span.set_attribute("http.method", "POST")
        span.add_event("received-payment-request")

        try:
            with tracer.start_as_current_span("payment.validate") as validate_span:
                if 'body' not in event:
                    raise ValueError("Missing 'body' key in the event.")

                body = event['body']
                if isinstance(body, str):
                    body = json.loads(body)
                elif isinstance(body, dict):
                    pass
                else:
                    raise ValueError("Unsupported 'body' format.")
                validate_span.add_event("validation-completed", attributes={"body": body})

            payment_id = body.get('payment_id')
            amount = body.get('amount')
            currency = body.get('currency', 'EUR')

            span.set_attribute("payment_id", payment_id)
            span.set_attribute("amount", amount)
            span.set_attribute("currency", currency)

            with tracer.start_as_current_span("payment.store-dynamodb") as store_span:
                try:
                    table = dynamodb_resource.Table(config.table_name)
                    table.put_item(
                        Item={
                            "payment_id": payment_id,
                            "amount": amount,
                            "currency": currency
                        }
                    )
                    logger.info(
                        "Inserted payment into DynamoDB",
                        extra={"payment_id": payment_id, "table_name": config.table_name},
                    )
                    store_span.add_event("payment-stored", attributes={"table_name": config.table_name})
                except Exception as e:
                    record_error(store_span, e)
                    logger.error(
                        "Failed to store payment in DynamoDB",
                        extra={"payment_id": payment_id, "error": str(e)},
                    )
                    raise

            with tracer.start_as_current_span("eventbridge.publish") as event_span:
                inject(headers := {})
                try:
                    event = {
                        "Source": config.source,
                        "DetailType": config.detail_type,
                        "Detail": json.dumps({
                            "payment_id": payment_id,
                            "amount": amount,
                            "currency": currency,
                            "timestamp": str(datetime.datetime.now(datetime.timezone.utc)),
                            "ttl_timestamp": int(time.time()) + config.time_to_distroy,
                            "traceparent": headers.get("traceparent")
                        }),
                        "EventBusName": config.event_bus_name
                    }

                    event_bridge.put_events(
                        Entries=[
                            event
                        ]
                    )
                    logger.info(
                        "Published event to EventBridge",
                        extra={"event_bus": config.event_bus_name, "event_detail": event},
                    )
                    event_span.add_event("event-published", attributes={"event_bus": config.event_bus_name})
                except Exception as e:
                    record_error(event_span, e)
                    logger.error(
                        "Failed to publish event to EventBridge",
                        extra={"payment_id": payment_id, "error": str(e)},
                    )
                    raise

            span.set_status(trace.StatusCode.OK)

            return {
                "statusCode": 200,
                "headers": create_headers(),
                "body": json.dumps({"message": "Payment initiated", "paymentId": payment_id}),
            }

        except ValueError as ve:
            record_error(span, ve)
            logger.error("Validation Error", extra={"error": str(ve)})
            return {"statusCode": 400, "headers": create_headers(), "body": json.dumps({"error": str(ve)})}
        except Exception as e:
            record_error(span, e)
            logger.error("Unhandled Error", extra={"error": str(e)})
            return {"statusCode": 500, "headers": create_headers(), "body": json.dumps({"error": "Internal server error"})}
