#!/bin/bash

# Task 4: KMS Encryption для S3 Bucket
# Готовые команды для ручного выполнения

# ===========================================
# CREDENTIALS
# ===========================================

export AWS_ACCESS_KEY_ID=AKIAXTORPMOMXL3LT7RQ
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# ===========================================
# ПЕРЕМЕННЫЕ
# ===========================================

ROLE_NAME="cmtr-4n6e9j62-iam-sewk-iam_role"
BUCKET_1="cmtr-4n6e9j62-iam-sewk-bucket-695267-1"
BUCKET_2="cmtr-4n6e9j62-iam-sewk-bucket-695267-2"
KMS_KEY_ARN="arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5"
KMS_KEY_ID="cac96933-72ff-49e0-8734-753dcd4a0ff5"
FILE_NAME="confidential_credentials.csv"
POLICY_NAME="KMSAccessPolicy"

# ===========================================
# ШАГ 1: ATTACH KMS POLICY К РОЛИ
# ===========================================

# 1.1 Проверить роль существует
aws iam get-role --role-name "$ROLE_NAME"

# 1.2 Создать inline policy для KMS доступа
aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME" \
    --policy-document file://kms-policy.json

# 1.3 Проверить policy создан
aws iam get-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME"

# 1.4 Policy Simulator - проверка KMS доступа
aws iam simulate-principal-policy \
    --policy-source-arn "arn:aws:iam::522814710681:role/$ROLE_NAME" \
    --action-names kms:Encrypt kms:Decrypt kms:GenerateDataKey \
    --resource-arns "$KMS_KEY_ARN"

# ===========================================
# ШАГ 2: ENABLE SERVER-SIDE ENCRYPTION
# ===========================================

# 2.1 Проверить bucket существует
aws s3 ls "s3://$BUCKET_2"

# 2.2 Включить server-side encryption с KMS
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_2" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "aws:kms",
                    "KMSMasterKeyID": "arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

# 2.3 Проверить encryption настроен
aws s3api get-bucket-encryption --bucket "$BUCKET_2"

# 2.4 Проверить KMS key details
aws kms describe-key --key-id "$KMS_KEY_ID"

# ===========================================
# ШАГ 3: КОПИРОВАНИЕ ФАЙЛА
# ===========================================

# 3.1 Проверить файл существует в bucket-1
aws s3 ls "s3://$BUCKET_1/$FILE_NAME"

# 3.2 Скопировать файл из bucket-1 в bucket-2 с KMS encryption
aws s3 cp "s3://$BUCKET_1/$FILE_NAME" "s3://$BUCKET_2/$FILE_NAME" \
    --sse aws:kms \
    --sse-kms-key-id "$KMS_KEY_ARN"

# 3.3 Проверить файл в bucket-2
aws s3 ls "s3://$BUCKET_2/$FILE_NAME"

# 3.4 Проверить encryption файла
aws s3api head-object \
    --bucket "$BUCKET_2" \
    --key "$FILE_NAME"

# ===========================================
# АЛЬТЕРНАТИВНЫЙ МЕТОД: DOWNLOAD + UPLOAD
# ===========================================

# Метод 1: Через S3 CP (рекомендуется)
aws s3 cp "s3://$BUCKET_1/$FILE_NAME" "s3://$BUCKET_2/$FILE_NAME" \
    --sse aws:kms \
    --sse-kms-key-id "$KMS_KEY_ARN"

# Метод 2: Download локально + Upload
# 2.1 Download файл
aws s3 cp "s3://$BUCKET_1/$FILE_NAME" ./confidential_credentials.csv

# 2.2 Upload с encryption
aws s3 cp ./confidential_credentials.csv "s3://$BUCKET_2/$FILE_NAME" \
    --sse aws:kms \
    --sse-kms-key-id "$KMS_KEY_ARN"

# 2.3 Очистить локальный файл
rm ./confidential_credentials.csv

# ===========================================
# ВЕРИФИКАЦИЯ
# ===========================================

# Тест 1: Проверить KMS policy на роли
aws iam get-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME"

# Тест 2: Проверить bucket encryption
aws s3api get-bucket-encryption --bucket "$BUCKET_2"

# Тест 3: Проверить файл и его encryption
aws s3api head-object \
    --bucket "$BUCKET_2" \
    --key "$FILE_NAME" \
    --query '{ServerSideEncryption:ServerSideEncryption,SSEKMSKeyId:SSEKMSKeyId}'

# Тест 4: Список всех файлов в bucket-2
aws s3 ls "s3://$BUCKET_2/" --recursive

# ===========================================
# ДОПОЛНИТЕЛЬНЫЕ КОМАНДЫ
# ===========================================

# Проверить все inline policies роли
aws iam list-role-policies --role-name "$ROLE_NAME"

# Проверить attached managed policies
aws iam list-attached-role-policies --role-name "$ROLE_NAME"

# Проверить KMS key policy
aws kms get-key-policy \
    --key-id "$KMS_KEY_ID" \
    --policy-name default

# Проверить grants для KMS key
aws kms list-grants --key-id "$KMS_KEY_ID"

# Decrypt файл (если нужно)
aws kms decrypt \
    --ciphertext-blob fileb://encrypted-file \
    --key-id "$KMS_KEY_ARN" \
    --output text \
    --query Plaintext

# ===========================================
# CLEANUP (ОПЦИОНАЛЬНО)
# ===========================================

# Удалить файл из bucket-2
aws s3 rm "s3://$BUCKET_2/$FILE_NAME"

# Отключить bucket encryption
aws s3api delete-bucket-encryption --bucket "$BUCKET_2"

# Удалить inline policy
aws iam delete-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME"

# ===========================================
# ПРАКТИЧЕСКОЕ ТЕСТИРОВАНИЕ
# ===========================================

# 1. Upload нового файла с encryption
echo "test data" > test-file.txt
aws s3 cp test-file.txt "s3://$BUCKET_2/test-file.txt" \
    --sse aws:kms \
    --sse-kms-key-id "$KMS_KEY_ARN"

# 2. Проверить encryption
aws s3api head-object \
    --bucket "$BUCKET_2" \
    --key "test-file.txt"

# 3. Download и проверить содержимое
aws s3 cp "s3://$BUCKET_2/test-file.txt" ./downloaded-test.txt
cat ./downloaded-test.txt

# 4. Cleanup
rm test-file.txt downloaded-test.txt
aws s3 rm "s3://$BUCKET_2/test-file.txt"

# ===========================================
# ПОЛЕЗНЫЕ ССЫЛКИ
# ===========================================

# AWS KMS Documentation:
# https://docs.aws.amazon.com/kms/latest/developerguide/overview.html

# S3 Encryption:
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html

# IAM Policies for KMS:
# https://docs.aws.amazon.com/kms/latest/developerguide/iam-policies.html
