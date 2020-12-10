provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "C:\\Users\\Tushar Dashpute\\.aws\\credentials"
  profile                 = "customprofile"
}

## IAM ROLE CREATION

resource "aws_iam_role" "lambda_ec2_role" {
  name = "lambda_ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "cwl_policy" {
  name = "cwl_policy"
  role = aws_iam_role.lambda_ec2_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Action": [
        "cloudwatch:*",
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_object" "object" {

  bucket = "tusharbucket12345"

  key    = "ec2_stop.zip"

  acl    = "private"  # or can be "public-read"

  source = "ec2_stop.zip"

  etag = filemd5("ec2_stop.zip")

}

resource "aws_lambda_function" "ec2_stop" {
  
  function_name = "ec2_stop"
  s3_bucket     = "tusharbucket12345"
  s3_key        = "ec2_stop.zip"
  role          = aws_iam_role.lambda_ec2_role.arn
  handler       = "ec2_stop.lambda_handler"
  runtime       = "python3.6"
}

######### Schedule the start of instance every 5 minutes using cloudwatch

resource "aws_cloudwatch_event_rule" "stop_instance" {
    name = "stop_instance"
    description = "Fires every five minutes"
    schedule_expression = "cron(55 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "check_stop_instance_every_five_minutes" {
    rule = aws_cloudwatch_event_rule.stop_instance.name
    target_id = "ec2_stop"
    arn = aws_lambda_function.ec2_stop.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_ec2_stop" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.ec2_stop.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.stop_instance.arn
}

###### EC2_START

resource "aws_lambda_function" "ec2_start" {
  
  function_name = "ec2_start"
  s3_bucket     = "tusharbucket12345"
  s3_key        = "ec2_stop.zip"
  role          = aws_iam_role.lambda_ec2_role.arn
  handler       = "ec2_start.lambda_handler"
  runtime       = "python3.6"
}

######### Schedule the start of instance every 5 minutes using cloudwatch

resource "aws_cloudwatch_event_rule" "start_instance" {
    name = "start_instance"
    description = "Fires every five minutes"
    schedule_expression = "cron(52 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "check_start_instance_every_five_minutes" {
    rule = aws_cloudwatch_event_rule.start_instance.name
    target_id = "ec2_start"
    arn = aws_lambda_function.ec2_start.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_ec2_start" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.ec2_start.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.start_instance.arn
}

