#!/bin/bash
#
# Copyright 2025 Oxide Computer Company
# Modified for shared login...
#

set -o errexit
set -o pipefail

if [[ ! -f "$HOME/.ssh/authorized_keys" ]]; then
  echo "ERROR: you have no $HOME/.ssh/authorized_keys file" >&2
  exit 1
fi

XID=2112
XNAME=icarus

cat <<EOF
#!/bin/bash
set -o errexit
set -o pipefail
set -o xtrace
echo 'Just a moment...' >/dev/msglog
/sbin/zfs create 'rpool/home/$XNAME'
/usr/sbin/useradd -u '$XID' -g staff -c '$XGECOS' -d '/home/$XNAME' \\
    -P 'Primary Administrator' -s /bin/bash '$XNAME'
/bin/passwd -N '$XNAME'
/bin/mkdir '/home/$XNAME/.ssh'
/bin/uudecode <<'EOSSH'
$(uuencode -m "$HOME/.ssh/authorized_keys" "/home/$XNAME/.ssh/authorized_keys" |
  awk 'NR == 1 { $2 = "600" } { print }')
EOSSH
/bin/chown -R '$XNAME:staff' '/home/$XNAME'
/bin/chmod 0700 '/home/$XNAME'
/bin/sed -i \\
    -e '/^PATH=/s#\$#:/opt/ooce/bin:/opt/ooce/sbin#' \\
    /etc/default/login
/bin/ntpdig -S 0.pool.ntp.org || true
echo 'ok go' >/dev/msglog
EOF
