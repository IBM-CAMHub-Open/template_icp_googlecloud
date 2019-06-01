#!/bin/bash

# Get script parameters
SSH_USER=`cat /opt/ibm/scripts/.ssh_user`
DOCKER_REGISTRY=`cat /opt/ibm/scripts/.registry_name`
MASTER_IP=`cat /opt/ibm/scripts/.master_ip`

echo "DOCKER_REGISTRY=$DOCKER_REGISTRY"
echo "SSH_USER=$SSH_USER"
echo "MASTER_IP=$MASTER_IP"

CERT_PATH=/etc/docker/certs.d/$DOCKER_REGISTRY:8500

sudo mkdir -p $CERT_PATH
echo "certificate path is $CERT_PATH"

#prepare to copy cert
sudo ssh -o StrictHostKeyChecking=no -i /opt/ibm/scripts/.master_ssh $SSH_USER@$MASTER_IP sudo cp $CERT_PATH/ca.crt /tmp/ca.crt      
sudo ssh -o StrictHostKeyChecking=no -i /opt/ibm/scripts/.master_ssh $SSH_USER@$MASTER_IP sudo chown $SSH_USER /tmp/ca.crt      

#get cert
sudo scp -o StrictHostKeyChecking=no -i /opt/ibm/scripts/.master_ssh $SSH_USER@$MASTER_IP:/tmp/ca.crt $CERT_PATH       

#clean up cert on master
sudo ssh -o StrictHostKeyChecking=no -i /opt/ibm/scripts/.master_ssh $SSH_USER@$MASTER_IP sudo rm -rf /tmp/ca.crt 
     
