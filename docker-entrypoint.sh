#!/usr/bin/env sh

set -exuo pipefail
trap "rm -f ${DATA}/log/status.pl ${DATA}/log/status.pl.old" EXIT

if [[ -z "$(ls -A ${CONFIG})" ]]; then
  echo "Creating new default configuration..."
  mv ${INIT_CONFIG}/* ${CONFIG}
  rm -rf ${INIT_CONFIG}
  chown -R backuppc:backuppc ${CONFIG}
fi

if [[ -z "$(ls -A ${DATA})" ]]; then
  echo "Creating data-directory from skel..."
  mv ${INIT_DATA}/* ${DATA}
  rm -rf ${INIT_DATA}
  mkdir -p ${DATA}/.ssh
  echo "Creating a ssh keypair..."
  ssh-keygen -N '' -f ${DATA}/.ssh/id_rsa
  chown -R backuppc:backuppc ${DATA}
  chmod -R 0600 ${DATA}/.ssh/*
fi

if [[ ! -f "${DATA}/.msmtprc" ]] && [[ ! -z ${MAILSERVER} ]]; then
  echo "generating ${DATA}/.msmtprc config"
  cat > "${DATA}/.msmtprc" << EOF
  account mail_account
  tls on
  tls_starttls off
  tls_certcheck off
  tls_trust_file /etc/ssl/certs/ca-certificates.crt
  auth on
  host ${MAILSERVER}
  port ${PORT}
  from ${FROM}
  user ${USER}
  password ${PASSWORD}

  defaults
  account mail_account
  account default: mail_account
EOF
  chown -R backuppc:backuppc ${DATA}/.msmtprc
  chmod -R 0600 ${DATA}/.msmtprc
fi

/usr/local/bin/dumb-init -c /usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
/usr/local/bin/dumb-init su-exec backuppc:backuppc /usr/bin/perl /usr/share/BackupPC/bin/BackupPC

