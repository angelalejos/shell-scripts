#!/bin/bash
 
##################################################################################################
# Script Name : generateMFASecurityToken.sh                                                     
# Author : Prasad Domala (prasad.domala@gmail.com)                                              
# Purpose : This script is used to generate IAM Session Token based on the MFA code              
#           provided by the user. The session token is required to connect to AWS                
#           using MFA authentication. The Session Token is valid for 12 hours by default.        
#           This script checks the expiriration time of the existing session token and           
#           creates a new one if it is expired. It also updates the AWS credentials file         
#           located under user home.                                                             
# Usage : generateMFASecurityToken.sh arg1 arg2                                                  
# $ ./generateMFASecurityToken.sh default-mfa default 12312343                                   
# Arguements                                                                                     
#   Arg1 : This arguement specifies the MFA profile name which contains AccessKey,               
#          SecretAccessKey and SessionToken                                                      
#   Arg2 : This parameter specifies the profile name used to call STS service which              
#          contains AccessKey, SecretAccessKey of the IAM user                                   
#   Arg3 : This parameter specifies the account number 
##################################################################################################
 

cat ~/.aws/account # file acount aws
read -p "User: " BASE_PROFILE_NAME
read -p "Account: " ACCOUNT
MFA_PROFILE_NAME="$BASE_PROFILE_NAME@$ACCOUNT"
account_ex=`more ~/.aws/account | grep "$ACCOUNT" | wc -l`

if [ $account_ex -eq 0 ]; then
    read -p "Account Name: " account_name
    echo "$account $account_name" >> ~/.aws/account
fi

# Set default region
DEFAULT_REGION="us-east-1"
 
# Set default output
DEFAULT_OUTPUT="json"
 
# MFA Serial: Specify MFA_SERIAL of IAM User
# Example: arn:aws:iam::123456789123:mfa/iamusername
MFA_SERIAL="arn:aws:iam::$account:mfa/$BASE_PROFILE_NAME"
 
# Generate Security Token Flag
GENERATE_ST="true"
 
# Expiration Time: Each SessionToken will have an expiration time which by default is 12 hours and
# can range between 15 minutes and 36 hours
MFA_PROFILE_EXISTS=`more ~/.aws/credentials | grep "$MFA_PROFILE_NAME" | wc -l`
#echo $MFA_PROFILE_EXISTS

if [ $MFA_PROFILE_EXISTS -eq 1 ]; then
    EXPIRATION_TIME=$(aws configure get expiration --profile $MFA_PROFILE_NAME)
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    if [[ "$EXPIRATION_TIME" > "$NOW" ]]; then
        echo "The Session Token is still valid. New Security Token not required."
        GENERATE_ST="false"
        exit 1
     fi
fi

MFA_PROFILE_EXISTS2=`more ~/.aws/credentials | grep "$MFA_PROFILE_NAME" | wc -l`



if [ $MFA_PROFILE_EXISTS2 -eq 1 ]; then
    aws configure
  else
    aws configure     
fi

 
if [ "$GENERATE_ST" = "true" ];then
    read -p "Token code for MFA Device ($MFA_SERIAL): " TOKEN_CODE
    echo "Generating new IAM STS Token ..."
    #echo "aws sts get-session-token --profile $BASE_PROFILE_NAME --output text --query 'Credentials.*' --serial-number $MFA_SERIAL --token-code $TOKEN_CODE"
    read -r AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN EXPIRATION AWS_ACCESS_KEY_ID < <(aws sts get-session-token --duration-seconds 129600 --output text --query 'Credentials.*' --serial-number $MFA_SERIAL --token-code $TOKEN_CODE)
    if [ $? -ne 0 ];then
        echo "An error occured. AWS credentials file not updated"
    else
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile $MFA_PROFILE_NAME
        aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile $MFA_PROFILE_NAME
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile $MFA_PROFILE_NAME
        aws configure set expiration "$EXPIRATION" --profile $MFA_PROFILE_NAME
        aws configure set region "$DEFAULT_REGION" --profile $MFA_PROFILE_NAME
        aws configure set output "$DEFAULT_OUTPUT" --profile $MFA_PROFILE_NAME
        echo "STS Session Token generated and updated in AWS credentials file successfully."
    fi
fi