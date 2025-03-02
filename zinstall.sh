#!/bin/bash

### SCRIPT: Instalación de Odoo 17 en Ubuntu 22.04 ###
# Instala Odoo 17, PostgreSQL y módulos de OCA con localización española

# Variables
ODOO_USER="odoo"
ODOO_HOME="/opt/$ODOO_USER"
ODOO_CONFIG="/etc/odoo.conf"
ODOO_PORT=8069
POSTGRES_USER="postgres"

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Agregar repositorio Deadsnakes para Python 3.10
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update

# Instalar dependencias necesarias
sudo apt install -y python3.10 python3.10-venv python3.10-dev python3.10-distutils python3.10-lib2to3 \
    git libpq-dev libxslt-dev libzip-dev libldap2-dev libsasl2-dev \
    libjpeg-dev zlib1g-dev libtiff5-dev libopenjp2-7-dev libssl-dev \
    libffi-dev libxml2-dev libxslt1-dev libjpeg-dev libpq-dev \
    build-essential wget nodejs npm curl libev-dev python3-pip python3-reportlab wkhtmltopdf

# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Crear usuario y base de datos para Odoo
sudo -u postgres createuser --createdb --username=postgres --no-superuser --no-createrole $ODOO_USER
sudo -u postgres psql -c "ALTER USER $ODOO_USER WITH PASSWORD 'odoo';"
**sudo -u postgres createdb -O $ODOO_USER odoo**

# Crear usuario del sistema para Odoo
sudo useradd -m -d $ODOO_HOME -U -r -s /bin/bash $ODOO_USER

# Descargar Odoo 17
sudo git clone --depth 1 --branch 17.0 https://github.com/odoo/odoo.git $ODOO_HOME/odoo

# Crear directorios necesarios
sudo mkdir -p /var/log/odoo $ODOO_HOME/custom_addons
sudo chown -R $ODOO_USER:$ODOO_USER /var/log/odoo $ODOO_HOME/custom_addons
sudo chmod -R 755 /var/log/odoo $ODOO_HOME/custom_addons

# Crear entorno virtual e instalar dependencias
sudo -u $ODOO_USER python3.10 -m venv $ODOO_HOME/venv
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --upgrade pip setuptools wheel cython werkzeug==2.2.3
**sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --no-cache-dir --force-reinstall rjsmin reportlab qrcode[pil]**

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

# Asignar permisos
sudo chown $ODOO_USER:$ODOO_USER $ODOO_CONFIG
sudo chmod 640 $ODOO_CONFIG

# Clonar módulos de OCA
OCA_REPOS=(
    "account-financial-tools" "account-payment" "bank-payment" "credit-control" "crm"
    "delivery-carrier" "hr" "mis-builder" "partner-contact" "product-attribute"
    "project" "purchase-workflow" "queue" "sale-workflow" "server-tools"
    "server-ux" "social" "stock-logistics-workflow" "stock-logistics-barcode"
    "stock-logistics-warehouse" "web"
)
for repo in "${OCA_REPOS[@]}"; do
    sudo -u $ODOO_USER git clone --depth 1 --branch 17.0 https://github.com/OCA/$repo.git $ODOO_HOME/custom_addons/OCA/$repo
done

# Crear base de datos y forzar instalación de módulos base
**sudo systemctl stop odoo**
**sudo -u postgres dropdb odoo**
**sudo -u postgres createdb -O odoo odoo**
**sudo -u odoo $ODOO_HOME/venv/bin/python3 $ODOO_HOME/odoo/odoo-bin -c $ODOO_CONFIG -d odoo --init=all --stop-after-init**

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

echo "Odoo 17 ha sido instalado correctamente con los módulos de OCA y la localización española."
