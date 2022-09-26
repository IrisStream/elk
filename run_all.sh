#/bin/bash

vagrant up

ssh-keygen -R "elk-server"
ssh-keygen -R "client-logstash"
ssh-keygen -R "clieng-elasticsearch"

ansible-playbook -i inventory.txt main.yaml