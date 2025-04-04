#!/bin/bash

# Define variables
REPO="hashicorp/terraform"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
DOWNLOAD_URL_BASE="https://releases.hashicorp.com/terraform"

# Function to fetch the latest release version
get_latest_release() {
  curl -s ${API_URL} | jq --raw-output '.tag_name' | cut -c 2-
}

# Function to download and install Terraform
install_terraform() {
  local version=$1
  echo "Installing Terraform ${version}..."
  
  # Remove any existing Terraform binaries
  rm -f terraform-*
  rm -f terraform
  
  # Download the latest release
  echo "Downloading Terraform ${version}..."
  wget ${DOWNLOAD_URL_BASE}/${version}/terraform_${version}_linux_amd64.zip
  
  # Unzip the downloaded file
  echo "Unzipping files..."
  unzip terraform_${version}_linux_amd64.zip
  
  # Clean up the zip file
  rm terraform_${version}_linux_amd64.zip
  
  # Mark the installed version
  touch ${version}
  
  # Backup existing Terraform binary and move new one
  echo "Moving Terraform binary..."
  if [[ -f /bin/terraform ]]; then
    mv /bin/terraform /bin/terraform_${version}.back
  fi
  mv terraform /bin/
  
  # Verify the installation
  echo "Terraform --version"
  terraform --version
}

# Main script
LATEST_RELEASE=$(get_latest_release)
if [[ ! -e ${LATEST_RELEASE} ]]; then
  install_terraform ${LATEST_RELEASE}
else
  echo "Latest Terraform (${LATEST_RELEASE}) already installed."
fi
