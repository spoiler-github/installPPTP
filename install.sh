#!/bin/bash
ip=$(ip a | grep inet | awk '{print$2}' | grep -E "/23|/24|/25" | rev | cut -c4- | rev)

apt install ppp pptpd -y

echo localip 172.16.0.1 >> /etc/pptpd.conf
echo remoteip 172.16.0.2-254 >> /etc/pptpd.conf

echo mtu 1400 >> /etc/ppp/pptpd-options
echo mru 1400 >> /etc/ppp/pptpd-options
echo auth >> /etc/ppp/pptpd-options
echo require-mppe >> /etc/ppp/pptpd-options
echo ms-dns 8.8.8.8 >> /etc/ppp/pptpd-options
echo ms-dns 8.8.4.4 >> /etc/ppp/pptpd-options

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -A INPUT -p gre -j ACCEPT
iptables -A INPUT -m tcp -p tcp --dport 1723 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -s 172.16.0.0/24 -j ACCEPT
iptables -A FORWARD -d 172.16.0.0/24 -j ACCEPT

echo 'Enable LAN between VPN clients? (1/0):'
read q;
if [[ q -eq 1 ]]
then 
  iptables --table nat --append POSTROUTING --out-interface ppp0 -j MASQUERADE
  iptables -I INPUT -s 172.16.0.0/24 -i ppp0 -j ACCEPT
  echo Lan has been enabled
fi

iptables-save

pass=$(openssl rand -base64 12)
echo -e 'user1 \t\tpptpd\t'$pass'\t"*"' >> /etc/ppp/chap-secrets

clear

echo VPN setup is successfully completed!
echo 'IP: ' $ip
echo Login: user1
echo 'Password: ' $pass

echo You can add more users in /etc/ppp/chap-secrets

systemctl restart pptpd
