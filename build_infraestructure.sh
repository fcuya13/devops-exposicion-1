#!/bin/bash

sudo rm -rf keys
mkdir keys
ssh-keygen -t rsa -N "" -f keys/devops-key
cp keys/devops-key ~/.ssh/devops-key 
chmod 600 ~/.ssh/devops-key

cd lambda_python
zip lambda_read.zip read_lambda.py
zip lambda_seed.zip seed_lambda.py
cd ../

cd terraform
terraform init
sudo terraform validate
sudo terraform plan -out=plan.tfplan
sudo terraform apply plan.tfplan

# Wait for SSH to be available on the control node
echo "Waiting for Ansible control node to be ready..."
while ! ssh -o StrictHostKeyChecking=no -i ~/.ssh/devops-key ubuntu@$(terraform output -raw ansible_control_public_ip) 'echo "SSH Ready"' 2>/dev/null; do
    sleep 5
done

# Copy necessary files to control node
echo "Copying files to Ansible control node..."
scp -i ~/.ssh/devops-key -r ansible html ~/.ssh/devops-key ubuntu@$(terraform output -raw ansible_control_public_ip):~/

# Run Ansible playbook
echo "Running Ansible playbook..."
ssh -i ~/.ssh/devops-key ubuntu@$(terraform output -raw ansible_control_public_ip) 'cd ~/ansible && chmod 755 . && chmod 644 ansible.cfg inventory.ini playbook.yml && chmod 600 ../devops-key && ansible-playbook playbook.yml -vv' 

# Get the load balancer URL
echo "Load Balancer URL: http://$(terraform output -raw load_balancer_url)/index.php"
