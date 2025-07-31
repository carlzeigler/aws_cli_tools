#!/bin/bash
################################################################################
# Script Name: launch_instance.sh
# Description:
#   Helper script to launch an EC2 instance using the LMS-Base-Launch-Template.
#   Arguments:
#     $1 - Hostname (required)
#     $2 - Domain (optional, default: lms4all.com)
#     $3 - WebServer (optional: apache|nginx, default: apache)
################################################################################

if [ -z "$1" ]; then
    echo "Usage: $0 <Hostname> [Domain] [WebServer]"
    exit 1
fi

HOSTNAME=$1
DOMAIN=${2:-lms4all.com}
WEBSERVER=${3:-apache}

aws ec2 run-instances   --launch-template LaunchTemplateName=LMS-Base-Launch-Template   --tag-specifications "ResourceType=instance,Tags=[{Key=Hostname,Value=$HOSTNAME},{Key=Domain,Value=$DOMAIN},{Key=WebServer,Value=$WEBSERVER}]"


#!/bin/bash
################################################################################
# Script Name: create_launch_template.sh
# Description:
#   Creates an EC2 Launch Template for a hardened RHEL 8 instance.
#   This script:
#     - Base64 encodes a provided user data script.
#     - Uses the RHEL 8 AMI in us-east-1.
#     - Sets up a t3.micro instance type (free tier eligible).
#     - Configures two EBS volumes (10GB root, 20GB /data/v1).
#     - Uses existing key pair and security group.
#     - Optionally includes a version of user data with CloudWatch logging.
# Usage:
#   ./create_launch_template.sh
#   Adjust ENABLE_CLOUDWATCH flag to true to include CloudWatch agent setup.
################################################################################

set -e

# Config
TEMPLATE_NAME="LMS-Base-Launch-Template"
AMI_ID="ami-0c94855ba95c71c99"   # RHEL 8 in us-east-1
INSTANCE_TYPE="t3.micro"
KEY_NAME="lms-pem-7"
SECURITY_GROUP_ID="launch-wizard-1"
ENABLE_CLOUDWATCH=false  # <---- Set to true to enable CloudWatch logging

# Select user data script based on flag
if [ "$ENABLE_CLOUDWATCH" = true ]; then
    USERDATA_FILE="hardened_userdata_with_cw.sh"
else
    USERDATA_FILE="hardened_userdata.sh"
fi

# Base64 encode the user data
USER_DATA=$(base64 -w0 "$USERDATA_FILE")

# Create the launch template
aws ec2 create-launch-template \
  --launch-template-name "$TEMPLATE_NAME" \
  --version-description "Initial Hardened RHEL8 Web Server" \
  --launch-template-data "{
    \"ImageId\": \"$AMI_ID\",
    \"InstanceType\": \"$INSTANCE_TYPE\",
    \"KeyName\": \"$KEY_NAME\",
    \"SecurityGroupIds\": [\"$SECURITY_GROUP_ID\"],
    \"BlockDeviceMappings\": [
      {\"DeviceName\": \"/dev/xvda\", \"Ebs\": {\"VolumeSize\": 10, \"VolumeType\": \"gp3\", \"DeleteOnTermination\": true}},
      {\"DeviceName\": \"/dev/sdb\", \"Ebs\": {\"VolumeSize\": 20, \"VolumeType\": \"gp3\", \"DeleteOnTermination\": true}}
    ],
    \"UserData\": \"$USER_DATA\"
  }"

