wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

apt -y install apt-transport-https

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

apt -y update 
apt -y install elasticsearch

# heap size configuration
cat << EOF > /etc/elasticsearch/jvm.options.d/heap.options
-Xms1g
-Xmx1g
EOF

# start service
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service