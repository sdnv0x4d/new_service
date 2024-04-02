#!/bin/bash

NGINX_PATH=/srv/docker/nginx/docker-compose.yml
NGINX_CONF_PATH=/srv/docker/nginx/config/conf.d/default.conf
MIKROTIK_USER=sdnv
MIKROTIK_IP=10.0.0.1
DOCKER_IP=10.0.0.2
LOCAL_NET=10.0.0.0/24
DOMAIN=example.com

# Add server record to NGINX confguration
add_nginx_rec() {
  local path=$1

  if [[ $path == "" ]]
  then
    echo "Set path to nginx.conf: "
    readline "NGINX_CONF_PATH"
  else
    NGINX_CONF_PATH=$path
  fi

  cat << EOF >> $NGINX_CONF_PATH
  
server {
   listen 80;
   server_name $SERVICE_DOMAIN.$DOMAIN;

   access_log  /var/log/nginx/$SERVICE_DOMAIN.access.log;
   error_log  /var/log/nginx/$SERVICE_DOMAIN.error.log;

   location / {
        proxy_pass http://$SERVICE_IP:$SERVICE_PORT;
        proxy_set_header host $SERVICE_DOMAIN.$DOMAIN;
        proxy_pass_request_headers on;
        proxy_http_version 1.1;
        proxy_set_header upgrade \$http_upgrade;
        proxy_set_header connection 'upgrade';
        proxy_set_header x-real-ip \$remote_addr;
        proxy_set_header x-forwarded-for \$proxy_add_x_forwarded_for;
        proxy_set_header x-forwarded-proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        allow $LOCAL_NET;
        deny all;
   }
}
EOF
}

# Validate IP address
valid_ip() {
  local  ip=$1
  local  stat=1
  
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    stat=$?
  fi
  return $stat
}

# Interactive read
readline() {
  trap "history -r; trap - SIGINT; return" SIGINT
  history -w
  history -c
  read -e "$1" $2
  history -r
  trap - SIGINT
}

echo "Create new service in NGINX & DNS Record" && echo ""

echo "Enter service domain name: "
readline "SERVICE_DOMAIN"

echo "Service IP w/o mask: "
readline "SERVICE_IP"

echo "Service port: "
readline "SERVICE_PORT"

# Validate Domain name
while true; do
  if [[ $SERVICE_DOMAIN =~ ^[a-z0-9]+$ ]]; then
    break
  else
    echo "Domain name is not valid, try again: "
    readline "SERVICE_DOMAIN"
  fi
done

# Validate IP address
while true; do
  if valid_ip $SERVICE_IP; then
    break
  else
    echo "IP is not valid, try again: "
    readline "SERVICE_IP"
  fi
done

cat << EOF
_____________________

Config of new service.

Domain Name: $SERVICE_DOMAIN
Service IP: $SERVICE_IP
Service Port: $SERVICE_PORT
_____________________

EOF

read -p "Continue? Enter 'y' or 'n': " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Exit..."
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

# Add record & restart nginx
read -p "Add record to reverse proxy? Enter 'y' or 'n': " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  add_nginx_rec $NGINX_CONF_PATH
  docker compose -f $NGINX_PATH down && docker compose -f $NGINX_PATH up -d
fi

# Connect to mikrotik via SSH & add DNS record
read -p "Add DNS record? Enter 'y' or 'n': " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  ssh $MIKROTIK_USER@$MIKROTIK_IP "ip/dns/static/add name=$SERVICE_DOMAIN.$DOMAIN type=A address=$DOCKER_IP"
fi
