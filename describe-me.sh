#!/bin/bash
# describe-me.sh
# Show basic info about the current EC2 instance (if running on EC2)

METADATA_URL="http://169.254.169.254/latest"
CURL_OPTS="--connect-timeout 2 --silent"

# Try to get the instance ID
INSTANCE_ID=$(curl $CURL_OPTS $METADATA_URL/meta-data/instance-id)

if [[ -z "$INSTANCE_ID" ]]; then
    echo "Not running on an EC2 instance (metadata service unavailable)."
    exit 1
fi

# Try to get the region from instance identity
REGION=$(curl $CURL_OPTS $METADATA_URL/dynamic/instance-identity/document | grep -oP '(?<="region" : ")[^"]+')

if [[ -z "$REGION" ]]; then
    echo "Could not determine AWS region from metadata."
    exit 1
fi

# Use AWS CLI to describe the instance
aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].[InstanceId, Tags[?Key=='Name']|[0].Value, PrivateIpAddress, PublicIpAddress, InstanceType, State.Name]" \
  --output table

