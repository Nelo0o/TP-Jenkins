#!/bin/bash

APP_VERSION=$1
DOCKER_IMAGE_BACKEND=$2
DOCKER_IMAGE_FRONTEND=$3

mkdir -p jenkins-exo-deploy-${APP_VERSION}

cat > jenkins-exo-deploy-${APP_VERSION}/docker-compose.prod.yml << EOF
version: '3.8'

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
      - "8080:80"
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

# Créer le répertoire nginx dans le package de déploiement
mkdir -p jenkins-exo-deploy-${APP_VERSION}/nginx

# Copier la configuration Nginx spécifique à la production
cp nginx/default.prod.conf jenkins-exo-deploy-${APP_VERSION}/nginx/default.conf

cat > jenkins-exo-deploy-${APP_VERSION}/deploy.sh << 'EOF'
#!/bin/bash

echo "🔍 Démarrage du déploiement de l'application jenkins-exo..."

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

# Vérifier si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

# Afficher la version de Docker et Docker Compose
echo "ℹ️ Docker version: $(docker --version)"
echo "ℹ️ Docker Compose version: $(docker-compose --version)"

# Arrêter les conteneurs existants si nécessaire
echo "🛑 Arrêt des conteneurs existants..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null

# Télécharger les images les plus récentes
echo "📥 Téléchargement des images Docker..."
docker-compose -f docker-compose.prod.yml pull

# Vérifier que les images sont bien téléchargées
echo "🖼️ Images Docker téléchargées:"
docker images | grep -E 'frontend|backend|nginx'

# Démarrer les conteneurs
echo "🚀 Démarrage des services..."
docker-compose -f docker-compose.prod.yml up -d

# Attendre que les conteneurs soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 5

# Vérifier que les conteneurs sont bien démarrés
if [ $(docker-compose -f docker-compose.prod.yml ps -q | wc -l) -eq 3 ]; then
    echo "✅ Application déployée avec succès! Accessible sur http://localhost:80"
    
    # Afficher les détails des conteneurs
    echo "📊 Détails des conteneurs:"
    docker-compose -f docker-compose.prod.yml ps
    
    # Vérifier la connectivité réseau entre les conteneurs
    echo "🔌 Vérification de la connectivité réseau entre les conteneurs..."
    
    # Tester la connexion au backend depuis nginx
    echo "🔄 Test de connexion au backend depuis nginx:"
    docker-compose -f docker-compose.prod.yml exec nginx wget -q -O - http://backend:5000/ || echo "⚠️ Impossible de se connecter au backend depuis nginx"
    
    # Tester la connexion au frontend depuis nginx
    echo "🔄 Test de connexion au frontend depuis nginx:"
    docker-compose -f docker-compose.prod.yml exec nginx wget -q -O - http://frontend/ || echo "⚠️ Impossible de se connecter au frontend depuis nginx"
    
    # Afficher les logs des conteneurs
    echo "📋 Logs des conteneurs:"
    echo "--- NGINX LOGS ---"
    docker-compose -f docker-compose.prod.yml logs nginx --tail=20
    echo "--- FRONTEND LOGS ---"
    docker-compose -f docker-compose.prod.yml logs frontend --tail=20
    echo "--- BACKEND LOGS ---"
    docker-compose -f docker-compose.prod.yml logs backend --tail=20
    
    echo "✅ Déploiement terminé avec succès. Vous pouvez accéder à l'application sur http://localhost:80"
    echo "ℹ️ En cas de problème, exécutez: docker-compose -f docker-compose.prod.yml logs"
else
    echo "❌ Erreur lors du déploiement. Vérifiez les logs:"
    docker-compose -f docker-compose.prod.yml ps
    docker-compose -f docker-compose.prod.yml logs
    
    echo "🔍 Diagnostic des problèmes potentiels:"
    
    # Vérifier si les ports sont déjà utilisés
    if netstat -tuln | grep -q ':80'; then
        echo "⚠️ Le port 80 est déjà utilisé par un autre processus. Cela peut empêcher nginx de démarrer."
    fi
    
    # Vérifier l'espace disque
    echo "💾 Espace disque disponible:"
    df -h
    
    # Vérifier la mémoire disponible
    echo "🧠 Mémoire disponible:"
    free -h
    
    echo "❌ Le déploiement a échoué. Veuillez résoudre les problèmes ci-dessus et réessayer."
    exit 1
fi
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