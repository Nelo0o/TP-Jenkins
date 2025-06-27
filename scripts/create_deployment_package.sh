APP_VERSION=$1
DOCKER_IMAGE_BACKEND=$2
DOCKER_IMAGE_FRONTEND=$3

mkdir -p jenkins-exo-deploy-${APP_VERSION}
mkdir -p jenkins-exo-deploy-${APP_VERSION}/nginx

cat > jenkins-exo-deploy-${APP_VERSION}/docker-compose.prod.yml << EOF
services:
  backend:
    image: ${DOCKER_IMAGE_BACKEND}:${APP_VERSION}
    restart: always
    environment:
      - NODE_ENV=production
    networks:
      - app-network

  frontend:
    image: ${DOCKER_IMAGE_FRONTEND}:${APP_VERSION}
    restart: always
    networks:
      - app-network

  nginx:
    image: nginx:stable-alpine
    ports:
      - "0:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - frontend
      - backend
    networks:
      - app-network
    restart: always

networks:
  app-network:
    driver: bridge
EOF

cp nginx/default.prod.conf jenkins-exo-deploy-${APP_VERSION}/nginx/default.conf

cat > jenkins-exo-deploy-${APP_VERSION}/deploy.sh << 'EOF'
docker-compose -f docker-compose.prod.yml down 2>/dev/null
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
echo "Déploiement terminé."
EOF

chmod +x jenkins-exo-deploy-${APP_VERSION}/deploy.sh

cat > jenkins-exo-deploy-${APP_VERSION}/README.md << EOF
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

tar -czf jenkins-exo-deploy-${APP_VERSION}.tar.gz jenkins-exo-deploy-${APP_VERSION}/

echo "📦 Package de déploiement créé avec succès: jenkins-exo-deploy-${APP_VERSION}.tar.gz"