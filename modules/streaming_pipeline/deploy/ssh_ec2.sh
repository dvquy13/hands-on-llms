#!/bin/bash

echo "Retrieving Public DNS of EC2 instance..."
PUBLIC_DNS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=streaming-pipeline-server" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicDnsName" --output text)

echo "PUBLIC_DNS=$PUBLIC_DNS"

echo "Connecting via SSH to the EC2 instance..."
KEY_FILE=deploy/AWSHandsOnLLmsKey.pem
chmod 400 $KEY_FILE
ssh -i "$KEY_FILE" ubuntu@$PUBLIC_DNS
