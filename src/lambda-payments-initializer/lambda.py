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
    """Record error details in the span."""
    span.record_exception(error)
    span.set_attribute("error.type", type(error).__name__)
    span.set_attribute("error.message", str(error))


def create_headers():
    """Create HTTP response headers and inject trace context."""
    headers = {}
    inject(headers)
    headers.update({
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    })
    return headers


def handler(event, context):
    dynamodb_resource = boto3.resource("dynamodb")
    event_bridge = boto3.client("events")
    config = Config()
    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span("payment.initialize") as span:
        logger.info(f"Received event: {event}")
        span.set_attribute("http.method", "POST")
        span.add_event("received-payment-request")

        try:
            with tracer.start_as_current_span("payment.validate") as validate_span:
                if "body" not in event:
                    raise ValueError("Missing 'body' key in the event.")

                body = event["body"]
                if isinstance(body, str):
                    body = json.loads(body)
                elif not isinstance(body, dict):
                    raise ValueError("Unsupported 'body' format.")

                # Simulation settings
                simulate = body.get("simulate", {})
                simulate_init = simulate.get("init", {})
                simulate_latency_init = simulate_init.get("latency", 0)
                simulate_error_400_init = simulate_init.get("error_400", False)
                simulate_db_error_init = simulate_init.get("db_error", False)
                simulate_error_500_init = simulate_init.get("error_500", False)

                # Simulate 400 error in validation
                if simulate_error_400_init:
                    raise ValueError("Simulated 400 error (init)")

                # Simulate processing latency 
                if simulate_latency_init > 0:
                    logger.info(f"Simulating init processing latency for {simulate_latency_init} seconds")
                    time.sleep(simulate_latency_init)

                validate_span.add_event("validation-completed", attributes={"body": body})

            payment_id = body.get("payment_id")
            amount = body.get("amount")
            currency = body.get("currency", "EUR")

            span.set_attribute("payment_id", payment_id)
            span.set_attribute("amount", amount)
            span.set_attribute("currency", currency)

            with tracer.start_as_current_span("payment.store-dynamodb") as store_span:
                try:
                    table = dynamodb_resource.Table(config.table_name)

                    # Simulate DB error 
                    if simulate_db_error_init:
                        raise Exception("Simulated database connection error (init)")

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

            # Simulate 500 error  before sending event
            if simulate_error_500_init:
                raise Exception("Simulated 500 error (init) before sending event to EventBridge")

            with tracer.start_as_current_span("eventbridge.publish") as event_span:
                try:
                    # Optionally simulate integration latency (e.g. external call delay)
                    integration_latency = simulate_init.get("integration_latency", 0)
                    if integration_latency > 0:
                        logger.info(f"Simulating integration latency for {integration_latency} seconds")
                        time.sleep(integration_latency)

                    headers = {}
                    inject(headers)
                    event_detail = {
                        "payment_id": payment_id,
                        "amount": amount,
                        "currency": currency,
                        "timestamp": str(datetime.datetime.now(datetime.timezone.utc)),
                        "ttl_timestamp": int(time.time()) + config.time_to_distroy,
                        "traceparent": headers.get("traceparent"),
                        "simulate": simulate
                    }
                    event_data = {
                        "Source": config.source,
                        "DetailType": config.detail_type,
                        "Detail": json.dumps(event_detail),
                        "EventBusName": config.event_bus_name
                    }

                    event_bridge.put_events(Entries=[event_data])
                    logger.info(
                        "Published event to EventBridge",
                        extra={"event_bus": config.event_bus_name, "event_detail": event_data},
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

            # Return a 200 response to indicate that the request was accepted
            return {
                "statusCode": 200,
                "headers": create_headers(),
                "body": json.dumps({"message": "Payment initiated", "paymentId": payment_id})
            }

        except ValueError as ve:
            record_error(span, ve)
            logger.error("Validation Error", extra={"error": str(ve)})
            return {
                "statusCode": 400,
                "headers": create_headers(),
                "body": json.dumps({"error": str(ve)})
            }
        except Exception as e:
            record_error(span, e)
            logger.error("Unhandled Error", extra={"error": str(e)})
            return {
                "statusCode": 500,
                "headers": create_headers(),
                "body": json.dumps({"error": "Internal server error"})
            }
