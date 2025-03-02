#!/bin/bash

# Variables
otip="odoo"
odoo_user="odoo"
odoo_home="/opt/$otip"
odoo_home_ext="/opt/$otip/$otip-server"
odoo_config="/etc/$otip.conf"
odoo_port="8069"
odoo_log="/var/log/$otip/$otip.log"
odoo_repo="https://github.com/odoo/odoo.git"
odoo_version="17.0"
oca_dir="/opt/oca_modules"

# Actualizar el sistema
echo "📌 Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
echo "📌 Instalando dependencias..."
sudo apt install -y python3.10 python3.10-venv python3.10-dev \
    git wget nodejs npm libpq-dev \
    libxml2-dev libxslt1-dev libldap2-dev \
    libsasl2-dev libjpeg-dev zlib1g-dev \
    libevent-dev libffi-dev \
    libpq-dev build-essential \
    libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev \
    wkhtmltopdf

# Configurar Node.js y Less
echo "📌 Configurando Node.js y Less..."
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css
sudo apt install -y node-less

# Instalar y verificar PostgreSQL
echo "📌 Instalando PostgreSQL..."
sudo apt install -y postgresql
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Crear usuario Odoo en PostgreSQL si no existe
echo "📌 Creando rol odoo en PostgreSQL..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='odoo'" | grep -q 1 || sudo -u postgres psql -c "CREATE ROLE odoo WITH SUPERUSER LOGIN PASSWORD 'odoo';"

# Crear base de datos para Odoo
echo "📌 Creando base de datos Odoo..."
sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = 'odoo'" | grep -q 1 || sudo -u postgres psql -c "CREATE DATABASE odoo OWNER odoo;"

# Crear usuario Odoo en el sistema si no existe
echo "📌 Verificando usuario $odoo_user..."
id -u $odoo_user &>/dev/null || sudo adduser --system --home=$odoo_home --group $odoo_user

# Descargar Odoo
echo "📌 Descargando Odoo 17..."
sudo git clone --depth 1 --branch $odoo_version $odoo_repo $odoo_home_ext
sudo chown -R $odoo_user:$odoo_user $odoo_home_ext

# Crear entorno virtual e instalar dependencias de Odoo
echo "📌 Configurando entorno virtual de Odoo..."
python3.10 -m venv $odoo_home_ext/venv
source $odoo_home_ext/venv/bin/activate
pip install --upgrade pip
pip install wheel

# Modificar requirements.txt para evitar errores de instalación
echo "📌 Modificando requirements.txt..."
sed -i '/gevent/d' $odoo_home_ext/requirements.txt
sed -i '/psycopg2/d' $odoo_home_ext/requirements.txt
sed -i '/greenlet/d' $odoo_home_ext/requirements.txt
sed -i '/python-ldap/d' $odoo_home_ext/requirements.txt

# Instalar dependencias desde requirements.txt
echo "📌 Instalando dependencias de Odoo..."
pip install -r $odoo_home_ext/requirements.txt

# Instalar dependencias problemáticas por separado
echo "📌 Instalando dependencias problemáticas por separado..."
pip install gevent==21.12.0 psycopg2-binary greenlet python-ldap

deactivate

# Crear directorio de logs
echo "📌 Creando directorio de logs..."
sudo mkdir -p /var/log/$otip/
sudo touch $odoo_log
sudo chown -R $odoo_user:$odoo_user /var/log/$otip/

# Clonar módulos OCA
echo "📌 Descargando módulos de la OCA..."
sudo mkdir -p $oca_dir
sudo chown -R $odoo_user:$odoo_user $oca_dir
cd $oca_dir

declare -a oca_repos=(
    "account-financial-tools"
    "bank-payment"
    "account-closing"
    "account-invoicing"
    "server-tools"
    "web"
    "sale-workflow"
    "stock-logistics-workflow"
    "hr"
    "l10n-spain"
    "contract"
)

for repo in "${oca_repos[@]}"; do
    echo "📌 Clonando repositorio OCA: $repo..."
    sudo git clone --depth 1 --branch 17.0 https://github.com/OCA/$repo.git
    sudo chown -R $odoo_user:$odoo_user $repo
    echo "✅ $repo instalado."
done

# Crear archivo de configuración si no existe
echo "📌 Creando archivo de configuración $odoo_config..."
sudo tee $odoo_config > /dev/null <<EOL
[options]
admin_passwd = admin
db_host = False
db_port = False
db_user = odoo
db_password = odoo
addons_path = $odoo_home_ext/addons,$oca_dir
logfile = $odoo_log
xmlrpc_interface = 0.0.0.0
EOL

sudo chown $odoo_user:$odoo_user $odoo_config
sudo chmod 640 $odoo_config

# Inicializar la base de datos si no está configurada
echo "📌 Verificando inicialización de la base de datos..."
sudo -u postgres psql -d odoo -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'ir_module_module';" | grep -q 1 || \
    sudo -u odoo $odoo_home_ext/venv/bin/python3 $odoo_home_ext/odoo-bin -c $odoo_config -d odoo -i base --without-demo=all --stop-after-init

# Reiniciar Odoo
echo "📌 Reiniciando Odoo..."
sudo systemctl restart odoo

# Verificar que Odoo se está ejecutando correctamente
if systemctl is-active --quiet $otip; then
    echo "✅ Odoo 17 está corriendo correctamente en el puerto $odoo_port"
else
    echo "❌ Odoo 17 NO se está ejecutando. Revisa los logs en: $odoo_log"
fi
