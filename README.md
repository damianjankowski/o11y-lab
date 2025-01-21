# [DRAFT] Serverless Unified Observability Done Right: I wrote a Tutorial so you Don’t Have To!


# Intro
Nowadays, the rapidly developing technology lean towards architects and developers to adopt cloud native principles. By abstracting infrastructure management, increasing adoption of event-driven design and scalability the serverless is natural step ahead in cloud-native philosophy, especially where those matters. This approach offers a lot of benefits but "with great power comes great responsibility...". Without proper desing and observability profits may become challenges, leading to raise of costs, degrageted performance, security vulnerabilities and difficulties in debugging. 

Serverless Unified Observability Done Right
is a article which I hope will bring you closed to really comprehensive topic which is `OBSERVABILITY`.
In this material you will learn how to setup "observability lab" which contains technologies like:
- AWS Lambda
- API Gateway
- DynamoDB
- OpenTelemetry
- Dynatrace


# Observability lab - components

## AWS Lambda
serverless compute service that runs your code dynamically on demand, eliminating the need for provisioning or managing infastucture. It execute your application in response to event such as HTTP requests, changes data in S3 bucket, DynamoDB tables or scheduled tasks. Key metrics, such as failure rate, execution duration, concurrent executions count and number of invocations provide a comprehensive view of backend performance.

## AWS APIGateway 
APIs are the backbone of modern system. APIGateway manage all HTTP/HTTPS calls to our applications. It works seamlessly with Lambda to create scalable, event-driven architectures for modern applications .It is also a perfect entry point to start debugging problem with application. 4xx errors helps to identify a problems with bad requests e.g. authorization error. Analyse of 5xx erros helps with debugging problems with backend configuration, avability, and performance. Latency measure the API response speed, while integration latency highlights a problems with backend-level delays. 


# Tools
## OpenTelemetry 
open-source tool for collecting, and processing data such as traces, metrics and logs. Serverless requests flow throught multiple serveices. The key benefit of OpenTelemetry is insight into such flow. More info you will find below.

## Dynatrace 
For enterprise-grade observability, we integrate the setup with Dynatrace, a comprehensive monitoring platform. Dynatrace provides powerful AI-driven insights, anomaly detection, and dashboards tailored for API performance. It complements OpenTelemetry by adding deep analytics and actionable intelligence to the collected data.

# Summary
By leveraging observability, teams gain actionable insights into patterns, error rates, traffic flows, and backend integration performance. This data-driven approach not only helps in identifying and resolving issues proactively but also empowers engineering teams to optimize  performance and deliver exceptional end-user experiences.


# Let’s kickstart this adventure - setting up the environment

In the following sections, we’ll walk through setting up this environment, configuring key observability metrics, and analyzing the data to optimize your API Gateway performance. By the end, you'll have a practical roadmap for implementing observability in your own infrastructure.

### Prerequisites

Before diving into the creation of an AWS Lambda Function, ensure you have the following:

- [ ] **AWS Account**: If you don’t have one, create it at [AWS Signup](https://signin.aws.amazon.com/signup?request_type=register).
- [ ] **IAM Permissions**: Ensure your AWS user has the necessary permissions to create and manage Lambda functions and API Gateway resources.

#### Sign in to AWS Management Console
Access the [AWS Management Console](https://aws.amazon.com/console/) and log in to your account.

### Elastic Container Registry (ECR)

To use a Docker image-based Lambda function, we first need to create an **Elastic Container Registry (ECR)** to store the Docker image containing the Lambda code.

1. Open **ECR** in the AWS Console.
2. Click **Create registry** in the top-right corner.
3. Under General settings:
   - Set a unique name for the registry, e.g., `traffiq`.
4. Click **Create** to finalize the setup.

### Lambda Function with Docker

Let’s create a simple Python-based Lambda function that returns `"Hello Observability!"`.

##### Step 1: Create `lambda_function.py`

```python
def handler(event, context):
    return {"statusCode": 200, "body": "Hello Observability!"}
```

##### Step 2: Create a `Dockerfile`

```dockerfile
FROM public.ecr.aws/lambda/python:3.12-x86_64

COPY lambda_function.py ${LAMBDA_TASK_ROOT}

CMD ["lambda_function.handler"]
```

##### Step 3: Build and Push the Docker Image

- **Authenticate Docker Client to ECR**

Retrieve an authentication token and authenticate your Docker client to the registry using the AWS CLI:

```bash
aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
```

- **Build the Docker Image**

Build the Docker image for the `linux/amd64` platform:

```bash
docker build --platform linux/amd64 -t traffiq:latest .
```

- **Tag the Docker Image**

After the build is complete, tag the image for your ECR repository:

```bash
docker tag traffiq:latest $(AWS_ACCOUNT_ID).dkr.ecr.eu-west-1.amazonaws.com/traffiq:latest
```

- **Push the Image to ECR**

Push the image to your newly created ECR repository:

```bash
docker push $(AWS_ACCOUNT_ID).dkr.ecr.eu-west-1.amazonaws.com/traffiq:latest
```

### Lambda Function with zip

First step is basicly the same like with Docker option: 

##### Step 1: Create `lambda_function.py`

```python
def handler(event, context):
    return {"statusCode": 200, "body": "Hello Observability!"}
```

##### Step 2: 

TODO 


### Lambda Function

To create a Lambda function with a container image:

1. Open **Lambda** in the AWS Console.
2. Click on **Create Function** in the top-right corner.
3. Choose **Container Image** and fill in the following under **Basic Information**:
   - **Function Name**: `traffiq`
   - **Container Image URI**: `$(AWS_ACCOUNT_ID).dkr.ecr.eu-west-1.amazonaws.com/traffiq:latest`
4. Click **Create Function** to complete the setup.


### API Gateway

#### Step 1: Navigate to API Gateway

1. Open **API Gateway** in the AWS Console.
2. Click **Create API** and select the **REST API** option.
3. Under **API Details**:
   - Choose **New API**.
   - Set a unique **API Name**, e.g., `traffiq-api`.


#### Step 2: Create Methods

1. Add a new method:
   - Select **Create Method**.
   - From the dropdown, choose **GET**.
2. Configure the method:
   - **Integration Type**: Select **Lambda Function**.
   - Enable **Lambda Proxy Integration** to send requests to Lambda as structured events.
   - Provide the **Name**, **Alias**, or **ARN** of your Lambda function.
3. Click **Create Method** to save the configuration.
4. Repeat the process for additional methods, such as **POST** and **DELETE**, if needed.


#### Step 3: Deploy the API

1. Click on **Deploy API**.
2. Select or create a deployment stage:
   - If deploying for the first time, create a new stage (e.g., `prod`).
   - Name the stage appropriately.
3. Click **Deploy** to finalize the process.
4. Retrieve the **Invoke URL** for your deployed API from the **Stage Details**.


#### Step 4: Enable Logs and Tracing

1. In the **Stage Settings**, click **Edit**.
2. Under **CloudWatch Logs**, enable the following:
   - **Errors and Info Logs**.
   - **Detailed Metrics** for advanced monitoring.

### Checkpoint

To ensure that everythings work correctly, run
```
curl -X GET "https://{APIGATEWAY_UNIQUE_ID}.execute-api.eu-west-1.amazonaws.com/{STAGE}"
```
it should return `Hello Observability!`

you can use also Postman, if you prefer a UI environment to work with https://www.postman.com/


### Ingesting AWS Logs into Dynatrace via Amazon Kinesis Data Firehose

Integrating Dynatrace with Amazon Kinesis Data Firehose allows for seamless and secure log ingestion from AWS services. To enable log forwarding, you’ll need to set up a Firehose delivery stream and configure it to send logs to your Dynatrace environment. CloudWatch log groups can be linked through subscription filters, or logs can be sent directly from other supported services like Amazon MSK (Managed Streaming for Apache Kafka).

#### Step 1: Configure an Amazon Kinesis Data Firehose Stream

1. **Access Firehose**: Open the Amazon Kinesis Data Firehose service in the AWS Management Console.
2. **Create a Delivery Stream**: Click on **Create Delivery Stream**.
3. **Set Basic Configuration**:
   - **Source**: Choose **Direct PUT**.
   - **Destination**: Select **Dynatrace**.
   - **Stream Name**: Provide a unique name for the stream, e.g., `DynatraceLogStream`.
   - **Data Transformation**: Ensure this is **disabled**.
4. **Advanced Settings**:
   - **Ingestion Type**: Select **Logs**.
   - **API Token**: Enter your Dynatrace API token (see prerequisites).
   - **API URL**: Specify your Dynatrace environment URL.
   - **Content Encoding**: Choose **GZIP**.
   - **Retry Duration**: Set to **900 seconds**.
   - **Buffer Hints**: Configure buffer size to **1 MiB** and buffer interval to **60 seconds**.
   - **Backup Settings**: Enable **Failed data only** and create a backup S3 bucket.
5. **Finalize Stream Creation**: Review your settings and click **Create Delivery Stream**.

case is a bit diffrent if you would like to use Terraform. There is no avaiable nativly supported destination, so you have to
choose **http_endpoint** insted of, which brings one more difference - you have to provide URL with api

```terraform
resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = local.firehose_stream_name
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = var.dynatrace_api_url
    name               = "Dynatrace"
    access_key = var.dynatrace_access_key
    retry_duration     = 900
    buffering_size     = 1
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose_role.arn

    s3_backup_mode = "FailedDataOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = var.s3_bucket_arn
      prefix             = "firehose-backup/"
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = local.firehose_log_group_s3_backup
        log_stream_name = "S3BackupLogs"
      }
    }

  cloudwatch_logging_options  {
    enabled         = true
    log_group_name  = local.firehose_log_group_http
    log_stream_name = "HttpEndpointLogs"
  }
  }

  tags = {
    Name        = "traffiq-terraform-kinesis-firehose-dynatrace-stream"
  }
}
```

#### Step 2: Setup an IAM Role for CloudWatch

A delivery stream requires an IAM role with a trust relationship to CloudWatch. Follow these steps to create the role:

1. **Create an IAM Policy**:
   - Navigate to **IAM > Policies** in the AWS Console.
   - Select **Create Policy** and switch to the JSON editor. Paste the following policy:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "firehose:PutRecord",
             "firehose:PutRecordBatch"
           ],
           "Resource": "*"
         }
       ]
     }
     ```
   - For a more restrictive setup, replace `*` with the specific ARN of your Firehose stream.
   - Name the policy and click **Create Policy**.

2. **Create an IAM Role**:
   - Navigate to **IAM > Roles** and click **Create Role**.
   - Choose **Custom Trust Policy** and paste the following JSON:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Principal": {
             "Service": "logs.amazonaws.com"
           },
           "Action": "sts:AssumeRole"
         }
       ]
     }
     ```
   - Attach the policy created earlier.
   - Name the role and click **Create Role**.


#### Step 3: Subscribe CloudWatch Log Groups

1. Navigate to **CloudWatch > Logs > Log Groups**.
2. Select the log group you want to stream.
3. Click **Actions > Subscription Filters > Create Amazon Data Firehose Subscription Filter**.
4. Configure the subscription:
   - **Firehose Delivery Stream**: Select the stream you created earlier.
   - **IAM Role**: Choose the role created in Step 2.
   - **Filter Name**: Provide a descriptive name for the subscription.
5. Click **Start Streaming** to activate log forwarding.

### Instrumentation

What is instrumentation?
Instrumentation is a process of equipping an application code with mechanizm that enable the collection and emission of telemetry data such as traces, metrics and logs.The complexity of modern applications clearly brings many challenges with debugging and performance evaluation, and OpenTelemetry addresses all these issues.

One of the most recognising instrumentation open source tool is `OpenTelemetry`. OpenTelemetry gives developers two main ways to instrument the application:
- Code-based solution via APIs and SDKs for languages like `C++, C#/.NET, GO, Java, JavaScript, Python, Ruby, Rust` (all list of supported languages you will find on official website https://opentelemetry.io/docs/languages/)
- Zero-code solutions which are the best way to get started with instrumentation your application or if you are not able to change a code. 

# Important:
you can use both solutions simultaneously

I would like to focus mostly, how you can benefit OpenTelemetry with Dynatrace. Dynatrace offers possibility to use OneAgent to instrument your application. Tool provides dedicated AWS Lambda layer that contains OneAgent.

Given configuration method
- JSON file 
- Environments variables
- Terraform
- AWS SAM
- Serverless framework
- AWS CloudFormation

# Why terraform?
IaC (Infrastructure as Code) become a GitOps standard about how to manage and provision configuration of the infrastructure. Terraform is another open source tool which allows users to define a state of the infrastucture in code. 

Bellow example show how Dynatrace AWS Layer
` layers = var.lambda_layers_arns` is added to the AWS Lambda. 

# Terraform configuration

Lambda definition
```terraform
resource "aws_lambda_function" "function" {  
  function_name = var.function_name  
  
  s3_bucket   = var.s3_bucket  
  s3_key      = var.s3_key  
  publish     = var.publish  
  handler     = var.handler  
  runtime     = "python3.12"  
  memory_size = 192  
  timeout     = 30  
  
  role = aws_iam_role.iam_for_lambda.arn  
  
  layers = var.lambda_layers_arns  
  
  environment {  
    variables = var.environment_variables  
  }  
}
```

Variables for Dynatrace configuration
```
variable "environment_variables" {  
  description = "A map of environment variables to be set for the Lambda function."  
  type        = map(string)  
  sensitive   = true  
  default     = {}  
}
```

Example of Dynatrace environments variable
```
environment_variables_dynatrace_open_telemetry = {  
  AWS_LAMBDA_EXEC_WRAPPER              = "/opt/dynatrace"  
  DT_TENANT                            = "<YOUR DT_TENANT>"  
  DT_CLUSTER_ID                        = "<YOUR DT_CLUSTER_ID>"
  DT_CONNECTION_BASE_URL               = "https://<DT_TENANT>.live.dynatrace.com"  
  DT_CONNECTION_AUTH_TOKEN             = "<YOUR DT_CONNECTION_AUTH_TOKEN>"   
  DT_LOG_COLLECTION_AUTH_TOKEN         = "<YOUR DT_LOG_COLLECTION_AUTH_TOKEN>"  
  DT_OPEN_TELEMETRY_ENABLE_INTEGRATION = "true"  
}  
lambda_layers_arns = [  
  "arn:aws:lambda:<YOUR REGION>:725887861453:layer:Dynatrace_OneAgent_1_303_2_20241004-043401_with_collector_python:1"  
]
```

Obviously alternative way how to archive the same is to setup lambda manually, by:
1. Open **Lambda** in the AWS Console.
2. Scroll down in `Code` section and
3. Click on `Add a layer`
   <img src="img/lambda-layers.png"/>
4. Choose `Specify an ARN` and fill it with necessary ARN e.g. `arn:aws:lambda:eu-west-1:725887861453:layer:Dynatrace_OneAgent_1_303_2_20241004-043401_with_collector_python:1`
   <img src="img/lambda-add-layer.png"/>
6. Click `Add` to finalize a process

then environments variables needs to be setup. Navigate to `Configuration` section of your Lambda settings and fill all necessary values.
<img src="img/lambda-env-vars.png"/>

# How to retrive all necessary values?
Dynatrace offers quite good support for onboarding users. To retrive all necessary configuration you have to:
1. Log into your Dynatrace account
2. Open `Distributed Tracing` application
3. Select source: `Cloud Workload` then `AWS` and `Lambda`
Configuration wizzard opens possibility to retrive all necessery values to go throught above example. Event Terraform snipped is added.

# Cream de la creme... Confirmation! 
Speaking of confirmation, finally we are reaching the point when Dynatrace is going to be used. Lambda should be visible in new `Services` application. 
<img src="img/lambda-services-main-view.png">
From that point you can easly navigate to `Distributed tracing` application
<img src="img/lambda-services-view-traces.png">

<img src="img/lambda-dist-traces-lambda-view.png">

<img src="img/lambda-dist-traces-lambda-view-all-good.png">
