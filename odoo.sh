#!/bin/bash

### SCRIPT 1: Instalación de Odoo 17 en Ubuntu 22.04 ###
# Este script instalará Odoo 17, PostgreSQL y descargará los módulos de OCA con la localización española

# Variables
ODOO_USER="odoo"
ODOO_HOME="/opt/$ODOO_USER"
ODOO_CONFIG="/etc/odoo.conf"
ODOO_PORT=8069
POSTGRES_USER="postgres"

# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Agregar el repositorio de Deadsnakes para instalar Python 3.10
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update

# Instalar dependencias necesarias
sudo apt install -y python3.10 python3.10-venv python3.10-dev python3.10-distutils python3.10-lib2to3 \
    git libpq-dev libxslt-dev libzip-dev libldap2-dev libsasl2-dev \
    libjpeg-dev zlib1g-dev libtiff5-dev libopenjp2-7-dev libssl-dev \
    libffi-dev libxml2-dev libxslt1-dev libjpeg-dev libpq-dev \
    build-essential wget nodejs npm curl libev-dev \
    python3-pip python3-reportlab

# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Crear usuario de PostgreSQL para Odoo
sudo -u postgres createuser --createdb --username=postgres --no-superuser --no-createrole $ODOO_USER
sudo -u postgres psql -c "ALTER USER $ODOO_USER WITH PASSWORD 'odoo';"

# Crear usuario del sistema para Odoo
sudo useradd -m -d $ODOO_HOME -U -r -s /bin/bash $ODOO_USER

# Descargar Odoo 17
sudo git clone --depth 1 --branch 17.0 https://github.com/odoo/odoo.git $ODOO_HOME/odoo

# Crear entorno virtual e instalar dependencias
sudo -u $ODOO_USER python3.10 -m venv $ODOO_HOME/venv
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --upgrade pip setuptools wheel cython

# Instalar dependencias adicionales necesarias para Odoo
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install psycopg2-binary werkzeug MarkupSafe>=2.1.1 reportlab rjsmin

# Crear archivo de configuración de Odoo
cat <<EOF | sudo tee $ODOO_CONFIG
[options]
admin_passwd = admin
db_host = False
db_port = False
db_user = $ODOO_USER
db_password = odoo
addons_path = $ODOO_HOME/odoo/addons,$ODOO_HOME/custom_addons
xmlrpc_port = $ODOO_PORT
xmlrpc_interface = 0.0.0.0
EOF

# Asignar permisos correctos
sudo chown $ODOO_USER:$ODOO_USER $ODOO_CONFIG
sudo chmod 640 $ODOO_CONFIG

# Crear directorio para custom_addons
sudo mkdir -p $ODOO_HOME/custom_addons
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME/custom_addons
sudo chmod -R 755 $ODOO_HOME/custom_addons

# Crear el servicio systemd para Odoo
cat <<EOF | sudo tee /etc/systemd/system/odoo.service
[Unit]
Description=Odoo
After=network.target postgresql.service

[Service]
Type=simple
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$ODOO_HOME/venv/bin/python3 $ODOO_HOME/odoo/odoo-bin -c $ODOO_CONFIG
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar el servicio
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

# Verificar estado del servicio
sudo systemctl status odoo

echo "Odoo 17 ha sido instalado correctamente con los módulos de OCA y la localización española. Ejecuta el siguiente script para configurar Nginx."
