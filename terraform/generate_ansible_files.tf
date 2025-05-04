resource "local_file" "ansible_inventory" {
  filename = "ansible/inventory.ini"
  content  = <<-EOF
[web_servers]
%{ for ip in aws_instance.ubuntu-vm-instance[*].private_ip ~}
${ip} ansible_ssh_user=ubuntu
%{ endfor ~}
EOF
}

resource "local_file" "ansible_playbook" {
  filename = "ansible/playbook.yml"
  content  = <<-EOF
---
- hosts: web_servers
  become: yes
  vars:
    api_gateway_url: "${aws_api_gateway_stage.api_stage.invoke_url}${aws_api_gateway_resource.read_resource.path}"

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install required packages
      apt:
        name: 
          - apache2
          - php
          - php-curl
        state: present

    - name: Create web directory
      file:
        path: /var/www/html
        state: directory
        mode: '0755'

    - name: Copy index.php
      copy:
        src: ../html/index.php
        dest: /var/www/html/index.content.php
        mode: '0644'

    - name: Copy hostname.php
      copy:
        src: ../html/hostname.php
        dest: /var/www/html/hostname.php
        mode: '0644'

    - name: Create main index.php
      copy:
        content: |
          <?php include('/var/www/html/index.content.php'); ?>
        dest: /var/www/html/index.php
        mode: '0644'

    - name: Configure Apache environment
      copy:
        content: |
          SetEnv API_GATEWAY_URL "{{ api_gateway_url }}"
        dest: /etc/apache2/conf-enabled/environment.conf
        mode: '0644'

    - name: Ensure Apache is running
      service:
        name: apache2
        state: restarted
        enabled: yes
EOF
}

resource "local_file" "ansible_config" {
  filename = "ansible/ansible.cfg"
  content  = <<-EOF
[defaults]
host_key_checking = False
inventory = inventory.ini
private_key_file = ../devops-key

[ssh_connection]
pipelining = True
EOF
} 