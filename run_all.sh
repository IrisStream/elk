#/bin/bash

vagrant up

rm -rf ~/.ssh/known_hosts

ansible-playbook -i ansible/inventory.txt ansible/main.yaml
