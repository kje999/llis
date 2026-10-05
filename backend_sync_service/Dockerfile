FROM node:20-slim

WORKDIR /app

# Install system build dependencies for native sqlite modules
RUN apt-get update && apt-get install -y python3 make g++ curl && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install --production

COPY . .

ENV PORT=8081
EXPOSE 8081

CMD ["npm", "start"]
