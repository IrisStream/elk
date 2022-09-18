wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

apt -y install apt-transport-https

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

apt -y update 
apt -y install elasticsearch

# heap size configuration
cat << EOF > /etc/elasticsearch/jvm.options.d/heap.options
-Xms256m
-Xmx256m
EOF

# start service
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

# Install kibana
apt -y install kibana 

cat << EOF > /etc/kibana/kibana.yml
server.port: 5601
server.host: "192.168.56.5"
EOF

cat << EOF > /etc/kibana/node.options
--max-old-space-size=512
EOF

systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service

# SSL configuration

# Generate rsa key
openssl genrsa -out /etc/ssl/private/logstash-forwarder.key 2048

# Get public key
openssl rsa -in /etc/ssl/private/logstash-forwarder.key -pubout -out /etc/ssl/public/logstash-forwarder.key

# Generate csr
openssl req -new -key /etc/ssl/private/logstash-forwarder.key -out /etc/ssl/certs/logstash-forwarder.csr

# Generate crt
openssl x509 -req -days 365 -in /etc/ssl/certs/logstash-forwarder.csr -signkey /etc/ssl/private/logstash-forwarder.key -out /etc/ssl/certs/logstash-forwarder.crt


# Install logstash
apt -y install logstash

cat << EOF > /etc/logstash/conf.d/02-beats-input.conf
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/ssl/certs/logstash-forwarder.crt"
    ssl_key => "/etc/ssl/private/logstash-forwarder.key"
  }
}
EOF 

cat << EOF > /etc/logstash/conf.d/10-syslog-filter.conf
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
EOF

cat << EOF > /etc/logstash/conf.d/30-elasticsearch-output.conf
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
EOF

cat << EOF > /etc/logstash/jvm.options
-Xms256m
-Xmx256m
EOF

systemctl daemon-reload
systemctl enable logstash.service
systemctl start logstash.service