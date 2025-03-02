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
    build-essential wget nodejs npm curl libev-dev python3-pip python3-reportlab

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

# Asegurar versión correcta de Werkzeug
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --upgrade werkzeug==2.2.3

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

# Clonar módulos de OCA - Localización Española
sudo -u $ODOO_USER git clone --depth 1 --branch 17.0 https://github.com/OCA/l10n-spain.git $ODOO_HOME/custom_addons/l10n-spain

# Instalar dependencias de Odoo con versión corregida de gevent
cat <<EOF | sudo tee $ODOO_HOME/odoo/requirements.txt
Babel==2.9.1 ; python_version < '3.11'
Babel==2.10.3 ; python_version >= '3.11'
chardet==4.0.0 ; python_version < '3.11'
chardet==5.2.0 ; python_version >= '3.11'
cryptography==3.4.8; python_version < '3.12'
cryptography==42.0.8 ; python_version >= '3.12'
decorator==4.4.2  ; python_version < '3.11'
decorator==5.1.1  ; python_version >= '3.11'
docutils==0.17 ; python_version < '3.11'
docutils==0.20.1 ; python_version >= '3.11'
ebaysdk==2.1.5
freezegun==1.1.0 ; python_version < '3.11'
freezegun==1.2.1 ; python_version >= '3.11'
geoip2==2.9.0
gevent==21.12.0 ; sys_platform != 'win32' and python_version == '3.10'
greenlet==1.1.2 ; sys_platform != 'win32' and python_version == '3.10'
idna==2.10 ; python_version < '3.12'
idna==3.6 ; python_version >= '3.12'
Jinja2==3.0.3 ; python_version <= '3.10'
Jinja2==3.1.2 ; python_version > '3.10'
libsass==0.20.1 ; python_version < '3.11'
libsass==0.22.0 ; python_version >= '3.11'
lxml==4.8.0 ; python_version <= '3.10'
lxml==4.9.3 ; python_version > '3.10' and python_version < '3.12'
MarkupSafe>=2.1.1
num2words==0.5.10 ; python_version < '3.12'
ofxparse==0.21
passlib==1.7.4
Pillow==9.0.1 ; python_version <= '3.10'
polib==1.1.1
psutil==5.9.0 ; python_version <= '3.10'
pydot==1.4.2
pyopenssl==21.0.0 ; python_version < '3.12'
PyPDF2==1.26.0 ; python_version <= '3.10'
pyserial==3.5
python-dateutil==2.8.1 ; python_version < '3.11'
psycopg2-binary==2.9.9
EOF

# Instalar dependencias
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --no-cache-dir -r $ODOO_HOME/odoo/requirements.txt

# Crear servicio systemd para Odoo
cat <<EOF | sudo tee /etc/systemd/system/odoo.service
[Unit]
Description=Odoo
After=network.target postgresql.service

[Service]
Type=simple
User=$ODOO_USER
ExecStart=$ODOO_HOME/venv/bin/python3 $ODOO_HOME/odoo/odoo-bin -c $ODOO_CONFIG
Restart=always

[Install]
WantedBy=multi-user.target
EOF


# Habilitar y arrancar Odoo
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo


# Configurar firewall
sudo ufw allow 8069
sudo ufw allow OpenSSH
sudo ufw enable

# Verificar estado del servicio
sudo systemctl status odoo

echo "Odoo 17 ha sido instalado correctamente con los módulos de OCA y la localización española. Ejecuta el siguiente script para configurar Nginx."
