#!/bin/bash
# Hardened user data script (Apache/Nginx selectable)
# #!/bin/bash
################################################################################
# Script Name: hardened_userdata.sh
# Description:
#   User data script for hardened RHEL 8 EC2 instances.
#   This script:
#     - Fetches Hostname, Domain, and WebServer type from EC2 tags:
#         Hostname - Sets the hostname (default: ec2-default-host)
#         Domain   - Sets the domain for TLS cert (default: lms4all.com)
#         WebServer - apache|nginx (default: apache)
#     - Creates users 'jcz' (sudo) and 'sas' (group 'sas') with SSH keys.
#     - Hardens SSH (no root login, key-only auth).
#     - Installs and configures the chosen web server with HTTPS (self-signed CA).
#     - Sets up HTTP->HTTPS redirect.
#     - Configures firewall (SSH + HTTPS).
#     - Logs sudo commands.
#     - Mounts /dev/sdb as /data/v1 (XFS).
################################################################################

set -e

# ======== Fetch Tags: Hostname, Domain, WebServer ========
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION="us-east-1"

NEW_HOSTNAME=$(aws ec2 describe-tags --region $REGION \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Hostname" \
  --query "Tags[0].Value" --output text)
[ -z "$NEW_HOSTNAME" ] && NEW_HOSTNAME="ec2-default-host"

DOMAIN=$(aws ec2 describe-tags --region $REGION \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Domain" \
  --query "Tags[0].Value" --output text)
[ -z "$DOMAIN" ] && DOMAIN="lms4all.com"

WEBSERVER=$(aws ec2 describe-tags --region $REGION \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=WebServer" \
  --query "Tags[0].Value" --output text)
[ -z "$WEBSERVER" ] && WEBSERVER="apache"

hostnamectl set-hostname "$NEW_HOSTNAME"

# ======== Variables ========
WEBROOT="/var/www/html"
CERT_DIR="/etc/ssl/myca"
CA_KEY="$CERT_DIR/ca.key"
CA_CERT="$CERT_DIR/ca.crt"
SERVER_KEY="$CERT_DIR/server.key"
SERVER_CSR="$CERT_DIR/server.csr"
SERVER_CERT="$CERT_DIR/server.crt"

# ======== Create Users and Groups ========
groupadd sas
useradd -m -s /bin/bash jcz
useradd -m -s /bin/bash -g sas sas
echo "jcz ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jcz
chmod 440 /etc/sudoers.d/jcz

# ======== Create SSH Keys ========
for USER in jcz sas; do
    USER_HOME=$(eval echo "~$USER")
    mkdir -p "$USER_HOME/.ssh"
    ssh-keygen -t rsa -b 4096 -f "$USER_HOME/.ssh/id_rsa" -q -N ""
    chown -R "$USER:$USER" "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/id_rsa"
    cat <<EOF > "$USER_HOME/.ssh/config"
Host *
    StrictHostKeyChecking no
    IdentityFile $USER_HOME/.ssh/id_rsa
EOF
    chown "$USER:$USER" "$USER_HOME/.ssh/config"
    chmod 600 "$USER_HOME/.ssh/config"
done

# ======== Harden SSH ========
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# ======== Install Web Server ========
if [ "$WEBSERVER" = "nginx" ]; then
    dnf -y install nginx openssl firewalld awscli sudo
    systemctl enable nginx
    systemctl start nginx
    WEBROOT="/usr/share/nginx/html"

    cat <<EOF > /etc/nginx/conf.d/ssl.conf
server {
    listen 80;
    server_name ${NEW_HOSTNAME}.${DOMAIN};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${NEW_HOSTNAME}.${DOMAIN};

    ssl_certificate $SERVER_CERT;
    ssl_certificate_key $SERVER_KEY;
    ssl_client_certificate $CA_CERT;

    root $WEBROOT;
    index index.html;
}
EOF
else
    dnf -y install httpd mod_ssl openssl firewalld awscli sudo
    systemctl enable httpd
    systemctl start httpd

    cat <<EOF > /etc/httpd/conf.d/ssl-custom.conf
<VirtualHost *:80>
    ServerName ${NEW_HOSTNAME}.${DOMAIN}
    Redirect permanent / https://${NEW_HOSTNAME}.${DOMAIN}/
</VirtualHost>

<VirtualHost *:443>
    DocumentRoot "$WEBROOT"
    ServerName ${NEW_HOSTNAME}.${DOMAIN}
    SSLEngine on
    SSLCertificateFile $SERVER_CERT
    SSLCertificateKeyFile $SERVER_KEY
    SSLCACertificateFile $CA_CERT
</VirtualHost>
EOF
fi

echo "<h1>Welcome to ${NEW_HOSTNAME} (${WEBSERVER})</h1>" > "$WEBROOT/index.html"

# ======== Create Self-Signed CA and TLS cert ========
mkdir -p "$CERT_DIR"
chmod 700 "$CERT_DIR"
openssl genrsa -out "$CA_KEY" 4096
openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 3650 \
    -subj "/C=US/ST=State/L=City/O=MyCA/CN=MyCA" -out "$CA_CERT"

openssl genrsa -out "$SERVER_KEY" 4096
openssl req -new -key "$SERVER_KEY" \
    -subj "/C=US/ST=State/L=City/O=Server/CN=${NEW_HOSTNAME}.${DOMAIN}" \
    -out "$SERVER_CSR"

openssl x509 -req -in "$SERVER_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
    -out "$SERVER_CERT" -days 825 -sha256

# ======== Trust the CA ========
cp "$CA_CERT" /etc/pki/ca-trust/source/anchors/myca.crt
update-ca-trust

# ======== Enable sudo logging ========
echo "Defaults logfile=/var/log/sudo.log" > /etc/sudoers.d/logging
chmod 440 /etc/sudoers.d/logging
touch /var/log/sudo.log
chmod 600 /var/log/sudo.log

# ======== Configure Firewall ========
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# ======== Mount /dev/sdb as /data/v1 ========
mkfs.xfs /dev/sdb
mkdir -p /data/v1
echo "/dev/sdb /data/v1 xfs defaults,nofail 0 2" >> /etc/fstab
mount -a

