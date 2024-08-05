#!/bin/bash

# Function to check if a port is in use
is_port_in_use() {
  sudo lsof -i -P -n | grep ":$1 " > /dev/null
  return $?
}

# Prompt the user for the port number
while true; do
  read -p "Enter the port number to run the Flask app: " PORT

  if is_port_in_use $PORT; then
    echo "Port $PORT is already in use by another program. Please choose a different port."
  else
    break
  fi
done

# Define the URL of the repository or zip file containing the Flask app
REPO_URL="https://github.com/KingAshi/3x-ui-client-portal/archive/refs/tags/v0.1.zip"
APP_DIR="flask_app"

# Create the directory for the Flask app files
mkdir -p $APP_DIR

# Download and unzip the Flask app files into the directory
wget $REPO_URL -O $APP_DIR/flask_app.zip
unzip $APP_DIR/flask_app.zip -d $APP_DIR
rm $APP_DIR/flask_app.zip

# Change to the app directory
cd $APP_DIR/your-flask-app-repo-main  # Adjust according to the structure of the extracted files

# Update the app.py file with the user-provided port
sed -i "s/5000/$PORT/" app.py

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv lsof curl unzip

# Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate

# Install the required Python packages
pip install -r requirements.txt

# Make sure Flask app runs on startup
sudo tee /etc/systemd/system/flaskapp.service > /dev/null <<EOL
[Unit]
Description=Flask Application

[Service]
User=$USER
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/python3 app.py

[Install]
WantedBy=multi-user.target
EOL

# Start and enable the Flask app service
sudo systemctl daemon-reload
sudo systemctl start flaskapp.service
sudo systemctl enable flaskapp.service

# Get the VPS IP address
VPS_IP=$(curl -s ifconfig.me)

echo "Flask app has been installed. You can access it at http://$VPS_IP:$PORT"
