echo 'Use alpine:3.6 version only.'

ODOO_VERSION="10.0"
ODOO_REPO="odoo/odoo"
ODOO_CONFIG_FILE="odoo.conf"
ODOO_CONFIG_DIR="/etc/odoo"
WKHTMLTOX_VERSION="0.12"
WKHTMLTOX_SUBVERSION="4"

ODOO_LOG="/var/log/odoo.log"
EODOO_CONFIG="${ODOO_CONFIG_DIR}/${ODOO_CONFIG_FILE}"
EWKHTMLTOX_RELEASE="${WKHTMLTOX_VERSION}.${WKHTMLTOX_SUBVERSION}"
EWKHTMLTOX_URI="http://download.gna.org/wkhtmltopdf/${WKHTMLTOX_VERSION}/${WKHTMLTOX_RELEASE}/wkhtmltox-${WKHTMLTOX_RELEASE}_linux-generic-amd64.tar.xz"

ODOO_URI="https://github.com/${ODOO_REPO}/archive/${ODOO_VERSION}.tar.gz"

MQT_URI="https://github.com/LasLabs/maintainer-quality-tools/archive/bugfix/script-shebang.tar.gz"

apk add --no-cache \
        git \
        ghostscript \
        icu \
        libev \
        nodejs \
        nodejs-npm \
        openssl \
        postgresql-client \
        postgresql-libs \
        poppler-utils \
        ruby \
        su-exec

apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing wkhtmltopdf
apk add --no-cache xvfb ttf-dejavu ttf-freefont fontconfig dbus
cp bin/wkhtmltox.sh /usr/local/bin/wkhtmltoimage
cp python-ldap.patch /tmp/setup.cfg.diff
ln /usr/local/bin/wkhtmltoimage /usr/local/bin/wkhtmltopdf

apk add --no-cache --virtual .build-deps \
    curl \
    # Common to all Python packages
    build-base \
    tar \
    python-dev \
    lxml
    libxml2-dev \
    libxslt-dev \
    Pillow
    freetype-dev \
    jpeg-dev \
    lcms2-dev \
    openjpeg-dev \
    tcl-dev \
    tiff-dev \
    tk-dev \
    zlib-dev \
    psutil
    linux-headers \
    psycopg2 \
    postgresql \
    postgresql-dev \
    # python-ldap
    openldap-dev \
    # Sass, compass
    libffi-dev \
    ruby-dev

gem install --clear-sources --no-document bootstrap-sass compass
npm install -g less
PYTHONOPTIMIZE=1 pip install --no-cache-dir psutil==2.2.0 pydot==1.0.2 psycopg2==2.5.4  vobject==0.6.6

adduser -D odoo \
&& mkdir -p /opt/odoo \
&& curl -sL "$ODOO_URI" | tar xz -C /opt/odoo --strip 1 \
&& cd /opt/odoo \
&& pip install --no-cache-dir -r ./requirements.txt \
&& pip install --no-cache-dir . \
&& chown -R odoo /opt/odoo \
&& mkdir -p \
/etc/odoo \
/mnt/addons \
/opt/addons \
/opt/community \
/var/lib/odoo \
/var/log/odoo \
&& ln -sf /dev/stdout "$ODOO_LOG" \
&& chown odoo -R \
/etc/odoo \
/mnt/addons \
/opt/addons \
/opt/community \
/var/lib/odoo \
/var/log/odoo

CFLAGS="$CFLAGS -L/lib" pip install --no-cache-dir --upgrade pillow
curl -sL "$MQT_URI" | tar -xz -C /opt/ \
&& ln -s /opt/maintainer-quality-tools-*/travis/clone_oca_dependencies /usr/bin \
&& ln -s /opt/maintainer-quality-tools-*/travis/getaddons.py /usr/bin/get_addons \
&& chmod +x /usr/bin/get_addons

pip install --no-cache-dir wdb
apk add --no-cache bash gettext postgresql-client
pip install --no-cache-dir openupgradelib

cp ./etc/odoo-server.conf /root"$ODOO_CONFIG"
chown odoo /docker-entrypoint.sh \
&& chmod +x /docker-entrypoint.sh \
&& chown odoo -R "$ODOO_CONFIG_DIR"

if [ "$ODOO_VERSION" != "10.0" ]; \
    then \
        mv /usr/local/bin/openerp-server /usr/local/bin/odoo && \
        ln -s /usr/local/bin/odoo /usr/local/bin/openerp-server; \
fi
awk '/import odoo/ { print; print "import threading; threading.stack_size(4*80*1024)"; next }1' /usr/local/bin/odoo > /tmp-bin \
    && mv /tmp-bin /usr/local/bin/odoo \
&& chmod +x /usr/local/bin/odoo

cd /tmp \
	&& wget https://pypi.python.org/packages/fc/99/9eed836fe4d916792994838df125da9c25c5f7c31abfbf6f0ab076e5f419/python-ldap-2.4.27.tar.gz \
	&& tar -xvf python-ldap-2.4.27.tar.gz \
	&& cd /tmp/python-ldap-2.4.27 \
	&& patch -i /tmp/setup.cfg.diff setup.cfg \
	&& python setup.py build \
	&& pip uninstall -y python-ldap \
&& python setup.py install

odoo
