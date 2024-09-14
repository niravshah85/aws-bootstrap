#!/bin/bash

DOMAIN=travelguy.life

STACK_NAME=awsbootstrap
REGION=us-east-2
CLI_PROFILE=awsbootstrap

EC2_INSTANCE_TYPE=t2.micro

AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile awsbootstrap \
    --query "Account" --output text`

CODEPIPELINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"
CFN_BUCKET="$STACK_NAME-cfn-$AWS_ACCOUNT_ID"

GH_ACCESS_TOKEN=$(cat ~/dev/.github/aws-bootstrap-access-token)
GH_OWNER=$(cat ~/dev/.github/aws-bootstrap-owner)
GH_REPO=$(cat ~/dev/.github/aws-bootstrap-repo)
GH_BRANCH=master

#Deploy static resources
echo -e "\n\n=========== Deploying setup.yml ===========\n"

aws cloudformation deploy \
    --region $REGION \
    --profile $CLI_PROFILE \
    --stack-name $STACK_NAME-setup \
    --template-file setup.yml \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
    CodePipelineBucket=$CODEPIPELINE_BUCKET \
    CloudFormationBucket=$CFN_BUCKET

#package up Cloudformation templates into an S3 bucket
echo -e "\n\n=========== Packaging main.yml ===========\n"
mkdir -p ./cfn_output

PACKAGE_ERR="$(aws cloudformation package \
    --region $REGION \
    --profile $CLI_PROFILE \
    --template main.yml \
    --s3-bucket $CFN_BUCKET \
    --output-template-file ./cfn_output/main.yml 2>&1)"

if ! [[ $PACKAGE_ERR =~ "Successfully packaged artifacts" ]]; then
    echo "ERROR while running 'aws cloudformation package' command: "
    echo $PACKAGE_ERR
    exit 1
fi


#Deploy the CloudFormation template

echo -e "\n\n=========== Deploying main.yml ===========\n"

#--disable-rollback \

aws cloudformation deploy \
    --region $REGION \
    --profile $CLI_PROFILE \
    --stack-name $STACK_NAME \
    --template-file ./cfn_output/main.yml \
    --disable-rollback \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
    EC2InstanceType=$EC2_INSTANCE_TYPE \
    GitHubOwner=$GH_OWNER \
    GitHubRepo=$GH_REPO \
    GitHubBranch=$GH_BRANCH \
    GitHubPersonalAccessToken=$GH_ACCESS_TOKEN \
    CodePipelineBucket=$CODEPIPELINE_BUCKET \
    Domain=$DOMAIN


# If the deploy succeeded, show the DNS name of the endpoints
if [ $? -eq 0 ]; then
  aws cloudformation list-exports \
    --profile awsbootstrap \
    --query "Exports[?ends_with(Name,'LBEndpoint')].Value"
  # starts_with is not necessary right now, but will be useful when we get to the Production section
fi
