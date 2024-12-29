#!/bin/bash

# Функция для записи данных в файл /etc/shadowsocks-libev/config.json
write_config() {
    local password=$1
    local method=$2

    cat <<EOF > /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "mode":"tcp_and_udp",
    "server_port":8388,
    "local_port":1080,
    "password":"$password",
    "fast_open": true,
    "timeout":20,
    "nameserver": "8.8.8.8",
    "method":"$method"
}
EOF
}

# Requesting a password and method from the user
read -p "Enter the password: " password
read -p "Enter the method (for example, chacha20): " method

# Сохранение данных в файл конфигурации
write_config "$password" "$method"

# Configuring iptables to open port 8388
systemctl enable shadowsocks-libev.service
iptables -4 -A INPUT -p tcp --dport 8388 -m comment --comment "Shadowsocks server listen port" -j ACCEPT
iptables -4 -A INPUT -p udp --dport 8388 -m comment --comment "Shadowsocks server listen port" -j ACCEPT
ufw allow proto tcp to 0.0.0.0/0 port 8388 comment "Shadowsocks server listen port"
ufw allow proto udp to 0.0.0.0/0 port 8388 comment "Shadowsocks server listen port"
ufw allow 8388 && ufw allow OpenSSH && ufw disable && ufw enable

# Configuring for network optimization
echo "
fs.file-max = 51200

net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.core.default_qdisc = fq

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla" | sudo tee /etc/sysctl.conf

# Applying sysctl settings and restarting the shadowsocks-libev service
sudo sysctl --system && systemctl restart shadowsocks-libev.service
