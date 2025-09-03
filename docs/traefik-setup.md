# 🌐 Configuration Traefik pour MASLDatlas

## 📁 Structure Traefik sur le serveur

Créez cette structure sur votre serveur :

```
/opt/traefik/
├── docker-compose.yml
├── traefik.yml
└── acme.json (chmod 600)
```

## 📄 /opt/traefik/docker-compose.yml

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - web
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard (optionnel)
    environment:
      - CF_API_EMAIL=your-email@domain.com  # Si vous utilisez Cloudflare
      - CF_DNS_API_TOKEN=your-cloudflare-token
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
      - ./acme.json:/acme.json
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.entrypoints=web"
      - "traefik.http.routers.traefik.rule=Host(`traefik.yourdomain.com`)"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=admin:$$2y$$10$$..."
      - "traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto=https"
      - "traefik.http.routers.traefik.middlewares=traefik-https-redirect"
      - "traefik.http.routers.traefik-secure.entrypoints=websecure"
      - "traefik.http.routers.traefik-secure.rule=Host(`traefik.yourdomain.com`)"
      - "traefik.http.routers.traefik-secure.middlewares=traefik-auth"
      - "traefik.http.routers.traefik-secure.tls=true"
      - "traefik.http.routers.traefik-secure.tls.certresolver=cloudflare"
      - "traefik.http.routers.traefik-secure.service=api@internal"

networks:
  web:
    external: true
```

## 📄 /opt/traefik/traefik.yml

```yaml
api:
  dashboard: true
  debug: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
          permanent: true

  websecure:
    address: ":443"

serversTransport:
  insecureSkipVerify: true

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: web
  file:
    filename: /traefik.yml

certificatesResolvers:
  cloudflare:
    acme:
      tlsChallenge: {}
      email: your-email@domain.com
      storage: acme.json
      # caServer: https://acme-staging-v02.api.letsencrypt.org/directory # staging
      caServer: https://acme-v02.api.letsencrypt.org/directory # production

log:
  level: INFO

accessLog: {}
```

## 🚀 Commandes de démarrage

```bash
# Sur le serveur
cd /opt/traefik
sudo touch acme.json
sudo chmod 600 acme.json
sudo docker-compose up -d
```
