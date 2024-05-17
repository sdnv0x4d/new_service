# new_service

Script for add nginx record and mikrotik dns record

## How-to
Set variables to begin of script

| Variable | Example | Explanation
| :-| :-| :-
| NGINX_PATH | `/srv/docker/nginx/docker-compose.yml` | NGINX docker-compose.yml path
| NGINX_CONF_PATH | `/srv/docker/nginx/config/conf.d/default.conf` | NGINX config path
| MIKROTIK_USER  | `sdnv` | Mikrotik SSH user
| MIKROTIK_IP | `10.0.0.1` | Mikrotik IP
| DOCKER_IP | `10.0.0.2` | Docker host ip
| LOCAL_NET | `10.0.0.0/24` | Local network for allow to service, deny all
| DOMAIN | `domain.com` | Domain for dns
| CF_ZONE_ID | `f8b9bd93470c83dd764e2c5a036e82b8` | Cloudflare Zone ID from Overiew page
| CF_EMAIL | `email.domain.com` | Cloudflare Email
| CF_API_TOKEN | `0F873089-f95acdac8c355fc4cc2cdcd6` | Cloudflare API Token with Permissions "Zone.DNS"
