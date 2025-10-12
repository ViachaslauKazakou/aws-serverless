Task Resources
Region-specific resources are created in the eu-west-1 region. For more details about regional services, see AWS Services by Region.

In this task, you should work with the following resources:

IAM Role cmtr-4n6e9j62-iam-sewk-iam_role: A role with full access to IAM and S3 services. CloudMentor will assume this role during the task validation.
S3 Buckets cmtr-4n6e9j62-iam-sewk-bucket-695267-1 and cmtr-4n6e9j62-iam-sewk-bucket-695267-2: The first bucket contains an object, which you need to copy to the second bucket.
KMS Key arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5: This key can only be used to encrypt objects in the second bucket; encrypting objects and the bucket itself with other keys is prohibited.
Objectives
In three moves, you must:

Grant all the necessary permissions for the cmtr-4n6e9j62-iam-sewk-iam_role role to work with the key. Do not grant full administrator access! 
Enable server-side encryption for the cmtr-4n6e9j62-iam-sewk-bucket-695267-2 bucket using the AWS KMS key with the arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5 ARN.
Check to make sure you can put a new encrypted object in the encrypted bucket. To do this, copy the confidential_credentials.csv file from the cmtr-4n6e9j62-iam-sewk-bucket-695267-1 bucket to the cmtr-4n6e9j62-iam-sewk-bucket-695267-2 bucket using AWS CLI or by downloading an object from cmtr-4n6e9j62-iam-sewk-bucket-695267-1 and uploading it to cmtr-4n6e9j62-iam-sewk-bucket-695267-2. As a result, the copied file confidential_credentials.csv should be encrypted.
One move is to create, update, or delete an AWS resource. Some verification steps may pass without any action being applied, but to complete the task you must ensure that all the steps are passed.

Deployment Time
It should take about 2 minutes to deploy the task resources.

Sandbox User Credentials
Use the credentials below to access the AWS environment:

AWS Console
Console URL: https://522814710681.signin.aws.amazon.com/console?region=eu-west-1
IAM username: cmtr-4n6e9j62
Password: Zm5#15gKNAxtprdS
AWS environment variables
AWS_ACCESS_KEY_ID=AKIAXTORPMOMXL3LT7RQ
AWS_SECRET_ACCESS_KEY=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