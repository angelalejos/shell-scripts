#!/bin/bash

LATEST_RELEASE=$(curl https://api.github.com/repos/hashicorp/terraform/releases/latest | jq --raw-output '.tag_name' | cut -c 2-)
if [[ ! -e ${LATEST_RELEASE} ]]; then
   echo "Installing Terraform ${LATEST_RELEASE}..."
   rm terraform-*
   rm terraform
   echo "Download Latest Release..."
   wget https://releases.hashicorp.com/terraform/${LATEST_RELEASE}/terraform_${LATEST_RELEASE}_linux_amd64.zip
   echo "unzip files..."
   unzip terraform_${LATEST_RELEASE}_linux_amd64.zip
   rm terraform_${LATEST_RELEASE}_linux_amd64.zip
   touch ${LATEST_RELEASE}
   echo "Terraform file is moved..."
   mv /bin/terraform /bin/terraform_${LATEST_RELEASE}.back
   mv terraform /bin/
   echo terraform --version
else
   echo "Latest Terraform already installed."
fi