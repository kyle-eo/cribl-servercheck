#!/bin/bash

# Please review variables to check. . .

# Specify the username you want to check
USERNAME="cribl"

# Verify Cribl CDN Access
SITE_URL="cdn.cribl.io"
PORT=443

# Specify the internal and external test locations
INTERNAL_TEST_LOCATION="192.168.1.1"  # Replace with your internal test location
EXTERNAL_TEST_LOCATION="google.com"   # Replace with your external test location

# Check ports for Leader UI and Workers. . 
# Define leader server and workers
LEADER_SERVER="leader_server_ip"
WORKERS=("worker1_ip" "worker2_ip")  # Add more worker IPs as needed

# Define ports to check
LEADER_PORTS=(9000)  # Add other ports as needed
WORKER_PORTS=(9000 4200 443)  # Add other ports as needed

# NFS Checks. .
# Define the NFS location and the test file
NFS_LOCATION="/path/to/nfs/location"
TEST_FILE="$NFS_LOCATION/testfile.tmp"



# Use nc (netcat) to check connectivity on port 443
if nc -zv -w5 $SITE_URL $PORT; then
  echo "[X] Server can access $SITE_URL on port $PORT."
else
  echo "[ ] Server cannot access $SITE_URL on port $PORT."
fi



# Check if Git is installed
if command -v git &> /dev/null
then
    echo "[X] Git is installed"
else
    echo "[ ] Git is not installed"
fi



# Does cribl user exist?
user_exists() {
    local username=$1
    if id "$username" &>/dev/null; then
        echo "[X] User '$username' exists."
    else
        echo "[ ] User '$username' does not exist."
    fi
}

# Call the function to check if the user exists
user_exists "$USERNAME"



# General network connection tests
check_connection() {
    local test_location=$1
    if ping -c 1 "$test_location" &>/dev/null; then
        echo "[X] SUCCESSFUL connection to $test_location"
    else
        echo "[ ] FAILED connection to $test_location"
    fi
}

# Call the function to check the network connections
check_connection "$INTERNAL_TEST_LOCATION"
check_connection "$EXTERNAL_TEST_LOCATION"



# Function to check ports
check_ports() {
    local server=$1
    shift
    local ports=("$@")
    
    for port in "${ports[@]}"; do
        timeout 1 bash -c "cat < /dev/null > /dev/tcp/$server/$port" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "[X] Port $port is open on $server"
        else
            echo "[ ] Port $port is closed on $server"
        fi
    done
}

# Check ports for leader server
echo "Checking ports for leader server: $LEADER_SERVER"
check_ports $LEADER_SERVER "${LEADER_PORTS[@]}"

# Check ports for each worker
for WORKER in "${WORKERS[@]}"; do
    echo "Checking ports for worker: $WORKER"
    check_ports $WORKER "${WORKER_PORTS[@]}"
done



# Check if NFS location is mounted and accessible
if mount | grep " on $NFS_LOCATION " > /dev/null; then
    echo "[X] NFS location is mounted and accessible at: $NFS_LOCATION"
else
    echo "[ ] NFS location is not mounted or accessible at: $NFS_LOCATION"
    exit 1
fi

# Check if user "cribl" can write to the NFS location
sudo -u cribl bash -c "touch $TEST_FILE" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[X] User 'cribl' can write to the NFS location."
    # Clean up test file
    sudo -u cribl rm -f $TEST_FILE
else
    echo "[ ] User 'cribl' cannot write to the NFS location."
    exit 1
fi

exit 0
