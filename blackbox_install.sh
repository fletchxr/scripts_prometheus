#/!bin/bash

read -p "Введите версию blackbox: " BLACKBOX_VERSION

wget https://github.com/prometheus/blackbox_exporter/releases/download/v$BLACKBOX_VERSION/blackbox_exporter-$BLACKBOX_VERSION.linux-amd64.tar.gz
tar xvfz blackbox_exporter-$BLACKBOX_VERSION.linux-amd64.tar.gz
cd blackbox_exporter-$BLACKBOX_VERSION.linux-amd64

mv blackbox_exporter /usr/bin
mv blackbox.yml /etc
cd ..
rm -rf ./blackbox_exporter*

useradd -rs /bin/false blackbox_exporter
chown blackbox_exporter:blackbox_exporter /usr/bin/blackbox_exporter
chown blackbox_exporter:blackbox_exporter /etc/blackbox.yml

cat <<EOF > /etc/systemd/system/blackbox_exporter.service
[Unit]
Description=blackbox_exporter
After=network.target

[Service]
User=blackbox_exporter
Group=blackbox_exporter
Type=simple
ExecStart=/usr/bin/blackbox_exporter --config.file=/etc/blackbox.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >> /etc/prometheus/prometheus.yml

  - job_name: "ICMP"
    scrape_interval: 1m
    metrics_path: /probe
    params:
     module: [icmp]
    static_configs:
      - targets:
        - 192.168.1.112
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115
EOF

systemctl daemon-reload
systemctl start blackbox_exporter
systemctl enable blackbox_exporter
systemctl status blackbox_exporter --no-page
systemctl restart prometheus