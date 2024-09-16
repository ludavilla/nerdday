#!/bin/bash

echo "Inciando o terrform"
terraform init

echo ""

echo "Criando instancia IBM cloud"
terraform apply --auto-approve

echo ""

echo "Criando arquivo hosts"
touch hosts


echo "buscando ip da instancia"
terraform output |grep -i IP_floating |cut -d "=" -f2 > hosts1

echo "Criando grupo de IPs com nome de nerday e inserindo ip da instancia no arquivo hosts"
echo "[nerdday]" > hosts
sed 's/"//g' hosts1 >> hosts
echo " " >> hosts
echo "[nerdday:vars]" >> hosts
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> hosts
rm -f hosts1

ansible-playbook -i hosts main.yml -v
