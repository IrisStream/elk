apt -y update
apt -y install apache2

usermod -aG sudo vagrant
HOME=/home/vagrant

# Configure elasticsearch
sed -i 's/#network.host:.*/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/#node.name: node-1/node.name: node-1/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/xpack.security.enabled: true/xpack.security.enabled: false/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/cluster.initial_master_nodes:.*/cluster.initial_master_nodes: ["node-1"]/g' /etc/elasticsearch/elasticsearch.yml

cat << EOF > /etc/elasticsearch/jvm.options.d/heap.options
-Xms512m
-Xmx512m
EOF

systemctl daemon-reload
systemctl enable --now elasticsearch.service

# Configure kibana
sed -i 's/#server.port: 5601/server.port: 5601/g' /etc/kibana/kibana.yml
sed -i 's/#server.host:.*/server.host: "0.0.0.0"/g' /etc/kibana/kibana.yml
sed -i 's/#--max-old-space-size=4096/--max-old-space-size=512/g' /etc/kibana/node.options

# Configure logstash
sed -i 's/-Xms1g/-Xms512m/g' /etc/logstash/jvm.options
sed -i 's/-Xmx1g/-Xmx512m/g' /etc/logstash/jvm.options

systemctl enable --now kibana.service

# SSL configuration
 openssl req -config /etc/ssl/openssl.cnf \
             -x509 \
             -days 3650 \
             -batch \
             -nodes \
             -newkey rsa:2048 \
             -keyout /etc/ssl/private/logstash-forwarder.key \
             -out /etc/ssl/certs/logstash-forwarder.crt 

cat << EOF > /etc/logstash/conf.d/02-beats-input.conf
input {
  beats {
    port => 5044
    ssl => true
    # ssl_certificate => "/etc/ssl/certs/logstash-forwarder.crt"
    # ssl_key => "/etc/ssl/private/logstash-forwarder.key"
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