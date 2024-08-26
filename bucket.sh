#!/bin/bash

# Set the cluster name
CLUSTER_NAME=o2

# Get the AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# Get the AWS region
AWS_REGION=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.arn' --output text | cut -d: -f4)

# Get the OIDC ID
OIDC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.identity.oidc.issuer' --output text | cut -d/ -f5)

# Generate random 5 digit number
random_number=$((RANDOM%90000+10000))
bucket="openobserve-$random_number"

# Create s3 bucket for OpenObserve
aws s3 mb s3://$bucket



# Set the policy name and description
POLICY_NAME="OpenObservePolicy"
POLICY_DESCRIPTION="Policy for S3 access by OpenObserve"

# Set the policy document
POLICY_DOCUMENT='{
  "Id": "Policy1678319681097",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1678319677242",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::'$bucket'/*"
    }
  ]
}'

# Create the policy
echo 'Creating policy'
aws iam create-policy --policy-name $POLICY_NAME --policy-document "$POLICY_DOCUMENT" --description "$POLICY_DESCRIPTION"

# Set the role name and description
ROLE_NAME="OpenObserveRole"
ROLE_DESCRIPTION="Role for EKS service account"

# Create the role
echo 'Creating role'
aws iam create-role --role-name $ROLE_NAME --description "$ROLE_DESCRIPTION" --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::'$AWS_ACCOUNT_ID':oidc-provider/oidc.eks.'$AWS_REGION'.amazonaws.com/id/'$OIDC_ID'"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "oidc.eks.'$AWS_REGION'.amazonaws.com/id/'$OIDC_ID':aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}'

echo "Role created: $ROLE_NAME"
# Get the role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

# Attach the policy to the role
echo 'Attaching policy to role'
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME

echo "S3 bucket created: $bucket"
echo "Role ARN: $ROLE_ARN"
