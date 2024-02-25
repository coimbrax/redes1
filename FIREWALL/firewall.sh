#!/bin/bash

local(){ 
# Libera a comunicacao (I/O) do servidr com a rede local e com a internet
# Libera o acesso as portas 80, 443, 123, 53 e 3128
iptables -t filter -A INPUT -i enp0s3 -p tcp -m multiport --sports 80,443 -j ACCEPT
iptables -t filter -A INPUT -i enp0s3 -p udp -m multiport --sports 53,123 -j ACCEPT
iptables -t filter -A OUTPUT -o enp0s3 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -t filter -A OUTPUT -o enp0s3 -p udp -m multiport --dports 53,123 -j ACCEPT

#Libera o trafego da lo na rede
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -o lo -j ACCEPT


#Libera o ping na rede local (protocolo icmp)
iptables -t filter -A INPUT -i enp0s3 -p icmp --icmp-type 8 -s 0/0 -j ACCEPT
iptables -t filter -A OUTPUT -o enp0s3 -p icmp --icmp-type 0 -d 0/0 -j ACCEPT

#Squid
iptables -t filter -A INPUT -i enp0s8 -p tcp --dport 3128 -j ACCEPT
iptables -t filter -A OUTPUT -o enp0s8 -p tcp --sport 3128 -j ACCEPT
}

forward(){
# Libera a comunicacao entre o servidor e a rede local redirecionando os pacotes entre 
# as placas de rede enp0s3(WAN) e enp0s8(LAN)
iptables -t filter -A FORWARD -i enp0s3 -p tcp -m multiport --sports 80,443 -d 192.168.15.0/24 -j ACCEPT
iptables -t filter -A FORWARD -i enp0s3 -p udp -m multiport --sports 53,123 -d 192.168.15.0/24 -j ACCEPT
iptables -t filter -A FORWARD -i enp0s8 -p tcp -m multiport --dports 80,443 -s 192.168.15.0/24 -j ACCEPT
iptables -t filter -A FORWARD -i enp0s8 -p udp -m multiport --dports 53,123 -s 192.168.15.0/24 -j ACCEPT

# Libera o ping entre a interface enp0s8 e a rede interna
iptables -t filter -A FORWARD -i enp0s8 -p icmp --icmp-type 8 -s 192.168.15.0/0 -d 0/0 -j ACCEPT
iptables -t filter -A FORWARD -o enp0s8 -p icmp --icmp-type 0 -d 192.168.15.0/0 -s 0/0 -j ACCEPT
}


internet(){
# Habilita o compartilhamento da internet entre as redes
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -s 192.168.15.0/24 -o enp0s3 -j MASQUERADE

#Direcionar navegacao para a porta do proxy/squid (3128)
iptables -t nat -A PREROUTING -i enp0s8 -p tcp --dport 80 -j REDIRECT --to-port 3128
}

default(){
# Determinar as regras padroes para o firewall
# Regra padrao = bloquear TUDO!
iptables -t filter -P INPUT DROP
iptables -t filter -P OUTPUT DROP
iptables -t filter -P FORWARD DROP
}

iniciar(){
# Executa todas as funcoes criadas aplicando
# as regras de protecao
local
forward
default
internet
}

parar(){
# Desabilita o firewall, liberando comunicacao sem 
# protecao entre as redes
iptables -t filter -P INPUT ACCEPT
iptables -t filter -P OUTPUT ACCEPT
iptables -t filter -P FORWARD ACCEPT
iptables -t filter -F
}

# Script para permitir executar start, stop, restart
# no comando systemctl.
case $1 in
start|Start|START)iniciar;;
stop|Stop|STOP)parar;;
restart|Restart|RESTART)parar;iniciar;;
listar)iptables -t filter -nvL;;
*)echo "Execute o comando firewall.sh com os parametros start, stop, restart ou listar";;
esac

##KBO##



























































































































