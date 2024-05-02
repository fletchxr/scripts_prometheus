#/!bin/bash

read -p "Введите версию prometheus: " PROMETHEUS_VERSION
PROMETHEUS_FOLDER="/etc/prometheus"
PROMETHEUS_TSDB_FOLDER="/etc/prometheus/data"

wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
tar xvfz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
cd prometheus-$PROMETHEUS_VERSION.linux-amd64

mv prometheus /usr/bin
cd ..
rm -rf ./prometheus*

mkdir -p $PROMETHEUS_FOLDER
mkdir -p $PROMETHEUS_TSDB_FOLDER


cat <<EOF > $PROMETHEUS_FOLDER/prometheus.yml
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: "myprometheus"
    static_configs:
      - targets:
        - localhost:9090
EOF

useradd -rs /bin/false prometheus

chown prometheus:prometheus /usr/bin/prometheus
chown prometheus:prometheus $PROMETHEUS_FOLDER
chown prometheus:prometheus $PROMETHEUS_FOLDER/prometheus.yml
chown prometheus:prometheus $PROMETHEUS_TSDB_FOLDER


cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
ExecStart=/usr/bin/prometheus \
  --config.file         /etc/prometheus/prometheus.yml \
  --storage.tsdb.path   /etc/prometheus/data

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
systemctl status prometheus --no-pager
prometheus --version