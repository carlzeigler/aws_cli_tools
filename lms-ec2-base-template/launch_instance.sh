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
