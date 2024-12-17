#!/bin/bash

echo "Updating system packages..."
apt-get update -y || { echo "Failed to update system packages"; exit 1; }


if ! command -v apache2 &> /dev/null; then
    echo "Installing Apache2..."
    apt-get install -y apache2 || { echo "Failed to install Apache2"; exit 1; }
else
    echo "Apache2 is already installed."
fi


echo "Configuring the web page for this instance..."
echo "Hello from server with ID: $INSTANCE_ID" > /var/www/html/index.html


echo "Starting and enabling Apache service..."
systemctl start apache2 || { echo "Failed to start Apache2"; exit 1; }
systemctl enable apache2 || { echo "Failed to enable Apache2"; exit 1; }

echo "Checking status of AWS SSM Agent..."

if systemctl is-active --quiet amazon-ssm-agent; then
    echo "SSM Agent is running."
else
    echo "SSM Agent is not running."
    exit 1
fi

echo "Server setup complete for server with ID: $INSTANCE_ID!"