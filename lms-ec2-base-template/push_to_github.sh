#!/bin/bash
################################################################################
# Script Name: push_to_github.sh
# Description:
#   Automates initial extraction and push of this repository to GitHub.
# Usage:
#   ./push_to_github.sh <github-org-or-username> <repository-name>
################################################################################

if [ $# -ne 2 ]; then
    echo "Usage: $0 <github-org-or-username> <repository-name>"
    exit 1
fi

ORG=$1
REPO=$2

# Extract archive
tar -xvzf lms-ec2-base-template.tar.gz
cd lms-ec2-base-template || exit 1

# Initialize and push
git init
git branch -M main
git remote add origin git@github.com:$ORG/$REPO.git
git add .
git commit -m "Initial commit: v1.0.0"
git push -u origin main

echo "Repository pushed to https://github.com/$ORG/$REPO"
