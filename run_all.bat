@echo off
setlocal enableextensions enabledelayedexpansion

vagrant up

SET _cmd=vagrant hosts list
SET _docker_run=docker run --rm -it -d --name ansible_container
FOR /f "tokens=1-2" %%G IN ('%_cmd%') DO (
	SET _docker_run=!_docker_run! --add-host %%H:%%G
)

SET _docker_run=!_docker_run! ansible_image bash

%_docker_run%

docker cp . ansible_container:/tmp

docker exec -it ansible_container ansible-playbook -i inventory.txt playbook.yml

docker stop ansible_container