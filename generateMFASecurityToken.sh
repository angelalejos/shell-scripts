#!/bin/bash

################################################################################
# Script Name : generateMFASecurityToken.sh
# Author      : Prasad Domala (prasad.domala@gmail.com)
# Purpose     : Generate IAM Session Token based on the MFA code provided by the user.
# Usage       : ./generateMFASecurityToken.sh default-mfa default 12312343
# Arguments   : 
#   Arg1 : MFA profile name containing AccessKey, SecretAccessKey, and SessionToken.
#   Arg2 : Profile name used to call STS service containing AccessKey and SecretAccessKey of the IAM user.
#   Arg3 : Account number.
################################################################################

# Set default region and output format
DEFAULT_REGION="us-east-1"
DEFAULT_OUTPUT="json"

# Read user inputs
read -p "User: " BASE_PROFILE_NAME
read -p "Account: " ACCOUNT
MFA_PROFILE_NAME="${BASE_PROFILE_NAME}@${ACCOUNT}"

# Check if the account exists in the local file, if not, add it
if ! grep -q "$ACCOUNT" ~/.aws/account; then
    read -p "Account Name: " account_name
    echo "$ACCOUNT $account_name" >> ~/.aws/account
fi

# Construct MFA serial ARN
MFA_SERIAL="arn:aws:iam::$ACCOUNT:mfa/$BASE_PROFILE_NAME"

# Initialize the flag to generate a new session token
GENERATE_ST="true"

# Check if the session token exists and is still valid
if aws configure get expiration --profile "$MFA_PROFILE_NAME" &> /dev/null; then
    EXPIRATION_TIME=$(aws configure get expiration --profile "$MFA_PROFILE_NAME")
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    if [[ "$EXPIRATION_TIME" > "$NOW" ]]; then
        echo "The Session Token is still valid. New Security Token not required."
        GENERATE_ST="false"
    fi
fi

# Generate a new session token if required
if [ "$GENERATE_ST" = "true" ]; then
    read -p "Token code for MFA Device ($MFA_SERIAL): " TOKEN_CODE
    echo "Generating new IAM STS Token ..."
    
    # Get session token and handle errors
    read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN EXPIRATION < <(aws sts get-session-token --duration-seconds 129600 --output text --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken,Expiration]' --serial-number "$MFA_SERIAL" --token-code "$TOKEN_CODE")
    
    if [ $? -ne 0 ]; then
        echo "An error occurred. AWS credentials file not updated."
        exit 1
    else
        # Update AWS credentials file with new session token
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$MFA_PROFILE_NAME"
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$MFA_PROFILE_NAME"
        aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile "$MFA_PROFILE_NAME"
        aws configure set expiration "$EXPIRATION" --profile "$MFA_PROFILE_NAME"
        aws configure set region "$DEFAULT_REGION" --profile "$MFA_PROFILE_NAME"
        aws configure set output "$DEFAULT_OUTPUT" --profile "$MFA_PROFILE_NAME"
        echo "STS Session Token generated and updated in AWS credentials file successfully."
    fi
fi
