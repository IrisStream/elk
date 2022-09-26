FROM ubuntu:latest

RUN apt -y update && apt -y upgrade
RUN apt install -y gcc libffi-devel python3 epel-release; \
    apt install -y python3-pip; \
    apt install -y wget; \
	apt install -y vim; \
	apt install -y openssh-client openssh-server; \
    apt clean all


RUN pip3 install --upgrade pip; \
    pip3 install --upgrade virtualenv; \
    pip3 install pywinrm[kerberos]; \
    pip3 install pywinrm; \
    pip3 install jmspath; \
    pip3 install requests; \
    python3 -m pip install ansible