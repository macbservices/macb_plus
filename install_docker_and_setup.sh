#!/bin/bash

# Atualizar o sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar pacotes necessários
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Adicionar a chave GPG oficial do Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adicionar o repositório do Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar as instalações
docker --version
docker-compose --version

# Criar arquivos de configuração do Docker Compose
cat <<EOF > docker-compose.yml
version: '3.1'

services:

  mysql:
    image: mariadb:latest
    container_name: macb_plusdb
    environment:
      MYSQL_ROOT_PASSWORD: b18073518B@123
      MYSQL_DATABASE: macb_plus
      MYSQL_USER: macb
      MYSQL_PASSWORD: b18073518B@123
    ports:
      - "3306:3306"
    restart: always
    command:
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_bin

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      PMA_USER: macb
      PMA_PASSWORD: b18073518B@123
    ports:
      - "9000:80"
    restart: always
EOF

# Iniciar os contêineres
sudo docker-compose up -d

echo "Instalação concluída. Os contêineres do MySQL e phpMyAdmin estão em execução."
