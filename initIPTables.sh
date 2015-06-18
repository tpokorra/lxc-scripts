#!/bin/bash

if [ -d /etc/network/if-post-down.d ]
then
  # Ubuntu
  # see https://help.ubuntu.com/community/IptablesHowTo#Solution_.232_.2BAC8-etc.2BAC8-network.2BAC8-if-pre-up.d_and_...2BAC8-if-post-down.d
  cat > /etc/network/if-pre-up.d/iptablesload <<FINISH
#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0
FINISH

  cat > /etc/network/if-post-down.d/iptablessave <<FINISH
#!/bin/sh
iptables-save -c > /etc/iptables.rules
if [ -f /etc/iptables.downrules ]; then
   iptables-restore < /etc/iptables.downrules
fi
exit 0
FINISH

  chmod +x /etc/network/if-post-down.d/iptablessave
  chmod +x /etc/network/if-pre-up.d/iptablesload
else
  # Fedora
  # https://fedoraproject.org/wiki/How_to_edit_iptables_rules
  # iptables service loads from and saves to /etc/sysconfig/iptables
fi
