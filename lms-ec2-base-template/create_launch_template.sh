#!/bin/bash
################################################################################
# Script Name: create_launch_template.sh
# Description:
#   Creates or updates an EC2 Launch Template for a hardened RHEL 8 instance.
#   Features:
#     - Resolves Security Group Name -> ID automatically.
#     - Validates Key Pair existence automatically.
#     - Base64 encodes a provided user data script.
#     - Allows specifying AWS region via --region flag.
#     - Updates existing Launch Template by creating a new version.
#     - Optionally sets the new version as the default (--overwrite).
#     - Allows setting a custom description for the new version (--desc).
# Usage:
#   ./create_launch_template.sh [--region us-west-2] [--overwrite] [--desc "My description"]
################################################################################

set -e

# ======== Defaults ========
TEMPLATE_NAME="LMS-Base-Launch-Template"
AMI_ID="ami-0c94855ba95c71c99"   # RHEL 8 in us-east-1
INSTANCE_TYPE="t3.micro"
KEY_NAME="lms-pem-7"              # Key Pair name (not ID)
SECURITY_GROUP_NAME="launch-wizard-1"  # Security Group name
REGION="us-east-1"
ENABLE_CLOUDWATCH=false  # <---- Set to true to enable CloudWatch logging
OVERWRITE_DEFAULT=false
VERSION_DESC="Hardened RHEL8 Web Server"

# ======== Parse Flags ========
while [[ $# -gt 0 ]]; do
  case $1 in
    --region)
      REGION="$2"
      shift 2
      ;;
    --overwrite)
      OVERWRITE_DEFAULT=true
      shift
      ;;
    --desc)
      VERSION_DESC="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--region region-name] [--overwrite] [--desc \"Description\"]"
      exit 1
      ;;
  esac
done

# ======== Resolve Security Group Name -> ID ========
echo "Resolving Security Group '$SECURITY_GROUP_NAME' in $REGION..."
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" \
  --query "SecurityGroups[0].GroupId" \
  --output text --region "$REGION" | tr -d '\r')
# the tr -d '\r' above is necessary under cygwin on windows 10. --jcz

if [[ "$SECURITY_GROUP_ID" == "None" || -z "$SECURITY_GROUP_ID" ]]; then
    echo "Error: Security group '$SECURITY_GROUP_NAME' not found in region $REGION."
    exit 1
fi
echo "Resolved Security Group ID: $SECURITY_GROUP_ID"

# ======== Validate Key Pair ========
echo "Validating Key Pair '$KEY_NAME' in $REGION..."
KEY_CHECK=$(aws ec2 describe-key-pairs \
  --key-names "$KEY_NAME" \
  --query "KeyPairs[0].KeyName" \
  --output text --region "$REGION" 2>/dev/null  | tr -d '\r' || true)
# the tr -d '\r' above is necessary under cygwin on windows 10. --jcz

if [[ "$KEY_CHECK" != "$KEY_NAME" ]]; then
    echo "Error: Key pair '$KEY_NAME' not found in region $REGION."
    exit 1
fi
echo "Key Pair validated: $KEY_NAME"

# ======== Select User Data Script ========
if [ "$ENABLE_CLOUDWATCH" = true ]; then
    USERDATA_FILE="hardened_userdata_with_cw.sh"
else
    USERDATA_FILE="hardened_userdata.sh"
fi

if [ ! -f "$USERDATA_FILE" ]; then
    echo "Error: User data file '$USERDATA_FILE' not found."
    exit 1
fi

USER_DATA=$(base64 -w0 "$USERDATA_FILE")

# ======== Check if Launch Template Exists ========
EXISTING_TEMPLATE=$(aws ec2 describe-launch-templates \
  --launch-template-names "$TEMPLATE_NAME" \
  --query "LaunchTemplates[0].LaunchTemplateName" \
  --output text --region "$REGION" 2>/dev/null || true)

if [[ "$EXISTING_TEMPLATE" == "$TEMPLATE_NAME" ]]; then
    echo "Launch Template '$TEMPLATE_NAME' exists. Creating a new version..."
    VERSION_ID=$(aws ec2 create-launch-template-version \
      --launch-template-name "$TEMPLATE_NAME" \
      --version-description "$VERSION_DESC" \
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
      }" --query 'LaunchTemplateVersion.VersionNumber' --output text --region "$REGION")
    echo "New version $VERSION_ID created for '$TEMPLATE_NAME'."

    if [ "$OVERWRITE_DEFAULT" = true ]; then
        echo "Setting version $VERSION_ID as the default for '$TEMPLATE_NAME'..."
        aws ec2 modify-launch-template \
          --launch-template-name "$TEMPLATE_NAME" \
          --default-version "$VERSION_ID" \
          --region "$REGION"
        echo "Default version updated to $VERSION_ID."
    fi
else
    echo "Creating new Launch Template '$TEMPLATE_NAME'..."
    aws ec2 create-launch-template \
      --launch-template-name "$TEMPLATE_NAME" \
      --version-description "$VERSION_DESC" \
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
      }" --region "$REGION"
    echo "Launch Template '$TEMPLATE_NAME' created successfully."
fi

