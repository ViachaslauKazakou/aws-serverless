Task description
Lab Description
The goal of this task is to grant the correct permissions to a Lambda function so that it can access the necessary resources and other resources can access it as well.

Examine the architecture below:


Task Resources
Region-specific resources are created in the eu-west-1 region. For more details about regional services, see AWS Services by Region.

In this task, you will work with the following resources:

Lambda function cmtr-4n6e9j62-iam-lp-lambda: Returns a list of Lambda functions in the AWS account. This function has an execution role cmtr-4n6e9j62-iam-lp-iam_role and a resource-based policy and serves as the HTTP API back end.
Lambda execution role cmtr-4n6e9j62-iam-lp-iam_role.
API Gateway cmtr-4n6e9j62-iam-lp-apigwv2_api: An HTTP API integrated with the cmtr-4n6e9j62-iam-lp-lambda function.
Objectives
You must achieve the following objectives in two moves:

Grant the correct permissions to the Lambda function so it can access the resources it needs based on the function code. Use the AWS managed policy that grants access to Lambda API actions, and follow the principle of least privilege. Please use the existing AWS policy; do not create your own.
Grant the correct permissions to the Lambda function so that the HTTP API can invoke it.
One move is to create, update, or delete an AWS resource. Some verification steps may pass without any action being applied, but to complete the task you must ensure that all the steps are passed.

Task Verification
To make sure everything is set up correctly, test your API by using a web-browser to invoke it.

Deployment Time
It should take about 2 minutes to deploy the task resources.

Sandbox User Credentials
Use the credentials below to access the AWS environment:

AWS Console
Console URL: https://135808946124.signin.aws.amazon.com/console?region=eu-west-1
IAM username: cmtr-4n6e9j62
Password: Ru7&3WXeP0dqHIm8
AWS environment variables
AWS_ACCESS_KEY_ID=AKIAR7HWYB7GGJEF5KH7
AWS_SECRET_ACCESS_KEY=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