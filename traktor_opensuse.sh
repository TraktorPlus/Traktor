#!/bin/bash


##################################################
#                  Traktor V2.5                  #
#     https://github.com/TraktorPlus/Traktor     #
# https://gitlab.com/GNULand/TraktorPlus/Traktor #
##################################################


clear
Version="Traktor V2.4"
#date="2018/03/3 Sat 21:30"
echo -e "$Version\nTor will be automatically installed and configured…\n\n"
# ==========/VARIABLES/==========
GRE='\033[0;32m'
RED='\033[91m'
NC='\033[0m'
trap "exit 1" TERM
export TOP_PID=$$
# ==========/VARIABLES-END/==========

# =========/Create File and Folder/=========

if [ ! -e "$HOME/.Traktor/Traktor_Log/install.log" ]; then
    echo -e "Traktor $Version Log: [$(date)]" | tee $HOME/.Traktor/Traktor_Log/install.log > /dev/null # echo date and time
fi

# =========/Create File and Folder End/=========


function loading {
	spin[0]="-"
	spin[1]="\\"
	spin[2]="|"
	spin[3]="/"
	PID=$!
	echo -n "${spin[0]}"
	while [ -d /proc/$PID ]
	do
	        for i in "${spin[@]}"
                do
	                echo -ne "\b$i"
	                sleep 0.2
		done
	done
        wait $PID
        if [ $? -ne 0 ]; then
                echo -e "\b${RD}Failed!${NC}"
                kill -s TERM $TOP_PID
        else
                echo -e "\b${GRE}Done."
        fi
}

#Tumbleweed will add as soon as possible
function uprepo {
	if grep -Fxq "VERSION=\"42.3\"" /etc/os-release
	then
		
		sudo zypper addrepo http://download.opensuse.org/repositories/home:/hayyan71/openSUSE_Leap_42.3/home:hayyan71.repo #add obfs4proxy
		sudo zypper addrepo http://download.opensuse.org/repositories/server:/dns/openSUSE_42.3/server:dns.repo #add dnscrypt-proxy

	elif grep -Fxq "NAME=\"openSUSE Tumbleweed\"" /etc/os-release
	then
		sudo zyyper addrepo http://download.opensuse.org/repositories/home:/hayyan71/openSUSE_Tumbleweed/home:hayyan71.repo #add obfs4proxy	

	else
		echo "\n\n tratktor doesn't support your current version yet"
		exit 1
	fi
	
	sudo zypper --no-gpg-checks ref


}
function packin {

	if grep -Fxq "NAME=\"openSUSE Tumbleweed\"" /etc/os-release
	then
		sudo zypper in -l -y obfs4-obfs4proxy privoxy tor dnscrypt-proxy
	elif grep -Fxq "VERSION=\"42.3\"" /etc/os-release	
		sudo zypper in -l -y obfs4proxy dnscrypt-proxy privoxy
	else
		echo "\n\nTraktor doesn't support you current version"
		exit 1
	fi

}

function torrcbackup {

	if [ -f "/etc/tor/torrc" ]; then
		sudo cp /etc/tor/torrc /etc/tor/torrc.traktor-backup
	fi
	if [ $? -ne 0 ]; then
		exit 1
	fi

}

function bridgewrite {

	sudo wget -q https://raw.githubusercontent.com/TraktorPlus/Traktor/config/torrc -O /etc/tor/torrc > /dev/null
	sudo sed -i -- 's/Log notice file \/var\/log\/tor\/notices.log/Log notice file \/var\/log\/tor\/tor.log/g' /etc/tor/torrc
	if [ $? -ne 0 ]; then
		exit 1
	fi

}


function privoxyback {
	
	if [ -f "/etc/privoxy/config" ]; then
	        sudo cp /etc/privoxy/config /etc/privoxy/config.traktor-backup
	fi
	if [ $? -ne 0 ]; then
		exit 1
	fi

}

function privoxyconf {
	sudo perl -i -pe 's/^listen-address/#$&/' /etc/privoxy/config
	echo 'logdir /var/log/privoxy
	listen-address  0.0.0.0:8118
	forward-socks5t             /     127.0.0.1:9050 .
	forward         192.168.*.*/     .
	forward            10.*.*.*/     .
	forward           127.*.*.*/     .
	forward           localhost/     .' | sudo tee /etc/privoxy/config > /dev/null
	sudo systemctl enable privoxy
	sudo systemctl restart privoxy.service
}

function setip {
    echo $XDG_CURRENT_DESKTOP | grep -i gnome >/dev/null
    gnome=$?
    echo $XDG_CURRENT_DESKTOP | grep -i xfce >/dev/null
    xfce="$?"
    echo $XDG_CURRENT_DESKTOP | grep -i kde >/dev/null
    kde="$?"
    if [ "$gnome" == "0" ] || [ "$xfce" == "0" ] ;then 
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.http host 127.0.0.1
        gsettings set org.gnome.system.proxy.http port 8118
        gsettings set org.gnome.system.proxy.socks host 127.0.0.1
        gsettings set org.gnome.system.proxy.socks port 9050
        gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '::1', '192.168.0.0/16', '192.168.8.1', '10.0.0.0/8', '172.16.0.0/12', '0.0.0.0/8', '10.0.0.0/8', '100.64.0.0/10', '127.0.0.0/8', '169.254.0.0/16', '172.16.0.0/12', '192.0.0.0/24', '192.0.2.0/24', '192.168.0.0/16', '192.88.99.0/24', '198.18.0.0/15', '198.51.100.0/24', '203.0.113.0/24', '224.0.0.0/3']"
    elif [ "$kde" == "0" ];then
        sed -i -- 's/ProxyType=.*/ProxyType=1/g' $HOME/.config/kioslaverc
        sed -i -- 's/httpProxy=.*/httpProxy=http:\/\/127.0.0.1 8118/g' $HOME/.config/kioslaverc
        sed -i -- 's/socksProxy=.*/socksProxy=socks:\/\/127.0.0.1 9050/g' $HOME/.config/kioslaverc
    else
        echo "Your Desktop not Support"
	exit 1
    fi
}

sudo uname -a &> /dev/null
echo -n "Add and Update repos...  "
uprepo >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
echo -n "Installing packages...  "
packin >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading
echo -ne "${NC}Backing up the old torrc to '/etc/tor/torrc.traktor-backup'...   "
torrcbackup >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading
echo -ne "${NC}Writing bridges...   "
bridgewrite >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading
echo -ne "${NC}Backing up privoxy...   "
privoxyback >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading
echo -ne "${NC}Config for privoxy...   "
privoxyconf >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading
echo -ne "${NC}Set ip and port...   "
setip >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading


echo -e "\nInstall Finished successfully…\n"
# Wait for tor to establish connection
echo -e "${NC}Tor is trying to establish a connection. This may take long for some minutes. Please wait${GRE}" | sudo tee /var/log/tor/tor.log
bootstraped='n'
sudo systemctl enable tor.service 
sudo systemctl restart tor.service
while [ $bootstraped == 'n' ]; do
	if sudo cat /var/log/tor/tor.log | grep "Bootstrapped 100%: Done";then
		bootstraped='y'
	else
		sleep 1
 	fi 
done 

echo -e "\n\nCongratulations!!! Your computer is using Tor.${NC}"
