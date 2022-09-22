apt -y update
apt install -y apache2

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

apt -y install apt-transport-https

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

apt -y update 
apt -y install filebeat

pushd /usr/share/filebeat/bin

filebeat modules enable apache
filebeat modules enable system

popd

sed -i 's/false/true/g' /etc/filebeat/modules.d/apache.yml
sed -i 's/false/true/g' /etc/filebeat/modules.d/system.yml

# configure filebeat.yml

# systemctl daemon-reload
# systemctl enable --now filebeat.service