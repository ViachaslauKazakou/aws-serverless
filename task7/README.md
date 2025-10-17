# Integrating API Gateway with a Lambda Function

Lab Description
The goal of this task is to integrate API Gateway with a Lambda function.

Examine the architecture below:


Task Resources
Region-specific resources are created in the eu-west-1 region. For more details about regional services, see AWS Services by Region.

The following infrastructure has been created for you:

API Gateway: erv7myh2nb
Route ID: py00o9v
Lambda function: cmtr-4n6e9j62-api-gwlp-lambda-contacts
## Objectives
The Lambda function code has already been deployed. Your task is to:

- Integrate the cmtr-4n6e9j62-api-gwlp-lambda-contacts Lambda function with the erv7myh2nb API gateway to handle requests from the existing py00o9v route.
- Configure the cmtr-4n6e9j62-api-gwlp-lambda-contacts function to return a list of contacts when invoked through GET /contacts:


```
[
  {
    "id": 1,
    "name": "Elma Herring",
    "email": "elmaherring@unq.com",
    "phone": "+1 (913) 497-2020"
  },
  {
    "id": 2,
    "name": "Bell Burgess",
    "email": "bellburgess@unq.com",
    "phone": "+1 (887) 478-2693"
  },
  {
    "id": 3,
    "name": "Hobbs Ferrell",
    "email": "hobbsferrell@unq.com",
    "phone": "+1 (862) 581-3022"
  }
]
```

## Task Verification
To make sure everything is set up correctly, check to make sure the updated Lambda function returns the list of contacts. This can be done in the AWS Management Console or via the AWS CLI.

## Deployment Time
It should take about 2 minutes to deploy the task resources.

## Sandbox User Credentials
Use the credentials below to access the AWS environment:

## AWS Console
Console URL: https://418272778502.signin.aws.amazon.com/console?region=eu-west-1
IAM username: cmtr-4n6e9j62
Password: Qu3#3V6fKx3Y4ZkB
AWS environment variables
AWS_ACCESS_KEY_ID=AKIAWCYYADEDESGATYGT
AWS_SECRET_ACCESS_KEY=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