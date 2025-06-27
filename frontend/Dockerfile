FROM node:latest

WORKDIR /app

# Installer les dépendances
COPY package*.json ./
RUN npm install

# Copier le code source
COPY . .

# Exposer le port 3000
EXPOSE 3000

# Définir les variables d'environnement pour Vite
ENV HOST=0.0.0.0
ENV PORT=3000

# Démarrer l'application en mode développement
CMD ["npm", "run", "dev"]