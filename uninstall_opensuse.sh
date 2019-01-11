#!/bin/bash


##################################################
#                  Traktor V2.5                  #
#     https://github.com/TraktorPlus/Traktor     #
# https://gitlab.com/GNULand/TraktorPlus/Traktor #
##################################################


clear
echo -e "Traktor\nTor will be automatically uinstalled ...\n\n"
sudo zypper rr server_dns home_hayyan71
if grep -Fxq "VERSION=\"42.3\"" /etc/os-release; then
	sudo zypper rm -yu obfs4proxy tor torsocks dnscrypt-proxy privoxy 
else

	sudo zypper rm -yu obfs4-obfs4proxy tor torsocks dnscrypt-proxy privoxy 
fi
sudo rm -f /etc/tor/torrc 
if [ -e $HOME/.config/kioslaverc ];
then
	sed -i -- 's/ProxyType=.*/ProxyType=0/g' $HOME/.config/kioslaverc
	sed -i -- 's/httpProxy=.*/httpProxy=/g' $HOME/.config/kioslaverc
	sed -i -- 's/socksProxy=.*/socksProxy=/g' $HOME/.config/kioslaverc
else
	gsettings set org.gnome.system.proxy mode 'none'
fi
echo "Uninstalling Finished Successfully."
exit 0
