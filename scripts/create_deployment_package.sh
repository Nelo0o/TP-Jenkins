#!/bin/bash

APP_VERSION=$1
DOCKER_IMAGE_BACKEND=$2
DOCKER_IMAGE_FRONTEND=$3

mkdir -p deployment

cat > deployment/docker-compose.prod.yml << EOF
services:
  backend:
    image: ${DOCKER_IMAGE_BACKEND}:${APP_VERSION}
    restart: always

  frontend:
    image: ${DOCKER_IMAGE_FRONTEND}:${APP_VERSION}
    restart: always

  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - frontend
      - backend
EOF

cp -r nginx deployment/

cat > deployment/deploy.sh << EOF
#!/bin/bash
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

echo "✅ Application déployée avec succès!"
EOF

chmod +x deployment/deploy.sh

cat > deployment/README.md << EOF
# Package de déploiement jenkins-exo v${APP_VERSION}

Ce package contient tout le nécessaire pour déployer l'application jenkins-exo en production.

## Contenu
- \`docker-compose.prod.yml\`: Configuration des services Docker
- \`nginx/\`: Configuration du serveur web NGINX
- \`deploy.sh\`: Script de déploiement automatisé

## Comment déployer
1. Assurez-vous que Docker et Docker Compose sont installés
2. Exécutez le script de déploiement: \`./deploy.sh\`

## Architecture
- Frontend: React/Vite servi via NGINX
- Backend: Node.js/Express
- Proxy: NGINX pour routing et reverse-proxy

## Version
- Build: ${APP_VERSION}
- Date de création: $(date)
EOF

tar -czf jenkins-exo-deploy-${APP_VERSION}.tar.gz deployment/

echo "📦 Package de déploiement créé avec succès: jenkins-exo-deploy-${APP_VERSION}.tar.gz"
