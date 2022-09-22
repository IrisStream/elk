usermod -aG sudo vagrant 
HOME=/home/vagrant

mkdir $HOME/elasticsearch
mkdir $HOME/kibana
mkdir $HOME/logstash

tar -xvzf /tmp/setup/elasticsearch-8.4.1-linux-x86_64.tar.gz -C $HOME/elasticsearch --strip-components=1
tar -xvzf /tmp/setup/kibana-8.4.1-linux-x86_64.tar.gz -C $HOME/kibana --strip-components=1
tar -xvzf /tmp/setup/logstash-8.4.1-linux-x86_64.tar.gz -C $HOME/logstash --strip-components=1


#ELASTICSEARCH CONFIGURATION

# heap size configuration
cat << EOF > $HOME/elasticsearch/config/jvm.options.d/heap.options
-Xms256m
-Xmx256m
EOF

# # Reset the password for the elastic user
# cat << EOF | $HOME/elasticsearch/bin/elasticsearch-reset-password -u elastic -is
# y
# Sondeptrai123
# Sondeptrai123
# EOF

# Configure elasticsearch
sed -i 's/#network.host:/network.host: 0.0.0.0/g' $HOME/elasticsearch/config/elasticsearch.yml
sed -i 's/#node.name: node-1/node.name: node-1/g' $HOME/elasticsearch/config/elasticsearch.yml
echo "xpack.security.enabled: false" >> $HOME/elasticsearch/config/elasticsearch.yml
echo "xpack.security.enrollment.enabled: true" >> $HOME/elasticsearch/config/elasticsearch.yml

# KIBANA CONFIGURATION
cat << EOF > $HOME/kibana/kibana.yml
server.port: 5601
server.host: "192.168.56.5"
EOF

cat << EOF > $HOME/kibana/config/node.options
--max-old-space-size=256
EOF

# LOGSTASH CONFIGURATION

# SSL configuration
 openssl req -config /etc/ssl/openssl.cnf \
             -x509 \
             -days 3650 \
             -batch \
             -nodes \
             -newkey rsa:2048 \
             -keyout /etc/ssl/private/logstash-forwarder.key \
             -out /etc/ssl/certs/logstash-forwarder.crt 


mkdir $HOME/logstash/conf.d

cat << EOF > $HOME/logstash/logstash.conf
input {
	file {
		path => "/home/vagrant/access_log"
		start_position => "beginning"
	}
}
filter {
	grok {
		match => { "message" => "%{COMBINEDAPACHELOG}"}
	}
	date {
		match => { "timestamp" => "dd/MMM/YYYY:HH:mm:ss Z"}
	}
}

output {
	elasticsearch {
		hosts => "localhost:9200"
	}
	stdout {
		codec => rubydebug
	}
}
EOF
cat << EOF > $HOME/logstash/conf.d/02-beats-input.conf
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/ssl/certs/logstash-forwarder.crt"
    ssl_key => "/etc/ssl/private/logstash-forwarder.key"
  }
}
EOF

cat << EOF > $HOME/logstash/conf.d/10-syslog-filter.conf
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

cat << EOF > $HOME/logstash/conf.d/30-elasticsearch-output.conf
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

sed -i 's/-Xms1g/-Xms256m/g' $HOME/logstash/config/jvm.options
sed -i 's/-Xmx1g/-Xmx256m/g' $HOME/logstash/config/jvm.options