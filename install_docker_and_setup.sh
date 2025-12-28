#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Instalando MACB+ com Docker ===${NC}"

# Verificar se é root ou sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Execute como root ou com sudo${NC}"
   exit 1
fi

# Atualizar o sistema
echo -e "${YELLOW}Atualizando sistema...${NC}"
apt-get update && apt-get upgrade -y

# Instalar pacotes necessários
echo -e "${YELLOW}Instalando dependências...${NC}"
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

# Adicionar a chave GPG oficial do Docker
echo -e "${YELLOW}Configurando repositório Docker...${NC}"
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adicionar o repositório do Docker (corrigido)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Adicionar usuário atual ao grupo docker
usermod -aG docker $SUDO_USER

# Criar arquivos de configuração do Docker Compose (VERSÃO COMPLETA)
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  mysql:
    image: mariadb:latest
    container_name: macb_plus_db
    environment:
      MYSQL_ROOT_PASSWORD: b18073518B@123
      MYSQL_DATABASE: macb_plus
      MYSQL_USER: macb
      MYSQL_PASSWORD: b18073518B@123
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    restart: always
    command:
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
    networks:
      - macb_network

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    container_name: macb_plus_phpmyadmin
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      PMA_USER: macb
      PMA_PASSWORD: b18073518B@123
    ports:
      - "8080:80"
    restart: always
    depends_on:
      - mysql
    networks:
      - macb_network

  nginx:
    image: nginx:alpine
    container_name: macb_plus_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    restart: always
    depends_on:
      - mysql
    networks:
      - macb_network

volumes:
  mysql_data:

networks:
  macb_network:
    driver: bridge
EOF

# Criar estrutura de pastas necessária
mkdir -p html ssl logs/nginx

# Criar index.html básico
cat <<EOF > html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>MACB+ Instalado com Sucesso</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        a { color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 MACB+ Instalado com Sucesso!</h1>
        
        <div class="status success">
            ✅ Docker e serviços iniciados com sucesso!
        </div>
        
        <h3>🔗 Acessos disponíveis:</h3>
        <ul>
            <li><strong>Site:</strong> <a href="http://localhost" target="_blank">http://localhost</a> ou <a href="http://$(curl -s ifconfig.me)" target="_blank">http://SEU_IP</a></li>
            <li><strong>phpMyAdmin:</strong> <a href="http://localhost:8080" target="_blank">http://localhost:8080</a></li>
            <li><strong>Database:</strong> localhost:3306 | User: macb | Pass: b18073518B@123</li>
        </ul>
        
        <div class="status info">
            <strong>⚠️ IMPORTANTE:</strong> Faça logout/login para usar docker sem sudo
        </div>
        
        <h3>🚀 Comandos úteis:</h3>
        <pre style="background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto;">
docker-compose ps
docker-compose logs
docker-compose down
        </pre>
    </div>
</body>
</html>
EOF

# Criar nginx.conf básico
cat <<EOF > nginx.conf
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html index.php;

        location / {
            try_files \$uri \$uri/ =404;
        }

        location /phpmyadmin {
            proxy_pass http://phpmyadmin:80;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF

# Iniciar os contêineres
echo -e "${YELLOW}Iniciando contêineres...${NC}"
docker-compose up -d

# Aguardar inicialização
sleep 10

# Verificar status
echo -e "${GREEN}=== STATUS DOS SERVIÇOS ===${NC}"
docker-compose ps

echo -e "${GREEN}=== IP DO SERVIDOR ===${NC}"
echo "IP público: $(curl -s ifconfig.me)"

echo -e "${GREEN}✅ INSTALAÇÃO CONCLUÍDA!${NC}"
echo -e "${YELLOW}🌐 Acesse:${NC}"
echo -e "   👉 Site: http://localhost ou http://$(curl -s ifconfig.me)"
echo -e "   👉 phpMyAdmin: http://localhost:8080"
echo -e "${YELLOW}⚠️  Logout/Login necessário para usar docker sem sudo${NC}"
