#!/bin/bash

echo "Updating system packages..."
apt-get update -y || { echo "Failed to update system packages"; exit 1; }


if ! command -v apache2 &> /dev/null; then
    echo "Installing Apache2..."
    apt-get install -y apache2 || { echo "Failed to install Apache2"; exit 1; }
else
    echo "Apache2 is already installed."
fi



echo "Installing AWS CloudWatch Agent..."

if ! command -v wget &> /dev/null; then
    echo "Installing wget..."
    apt-get install -y wget || { echo "Failed to install wget"; exit 1; }
fi


wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb || { echo "Failed to download CloudWatch Agent"; exit 1; }
dpkg -i amazon-cloudwatch-agent.deb || { echo "Failed to install CloudWatch Agent"; exit 1; }

echo "Configuring AWS CloudWatch Agent..."
cat << EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "TrustSoft/EC2",
    "append_dimensions": {
      "InstanceId": "\${aws:InstanceId}",
      "AvailabilityZone": "\${aws:AvailabilityZone}"
    },
    "aggregation_dimensions": [["InstanceId"]],
    "metrics_collected": {
      "mem": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"],
        "metrics_collection_interval": 60
      },
      "cpu": {
        "measurement": ["usage_active"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

 Agentecho "Starting AWS CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s || { echo "CloudWatch Agent failed to start"; exit 1; }

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