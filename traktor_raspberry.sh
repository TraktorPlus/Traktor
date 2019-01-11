#!/bin/bash


##################################################
#                  Traktor V2.5                  #
#     https://github.com/TraktorPlus/Traktor     #
# https://gitlab.com/GNULand/TraktorPlus/Traktor #
##################################################


trap "exit 1" TERM
export TOP_PID=$$

clear
Version="Traktor V2.5 - Ubuntu Server Raspberry Pi (18.04)"
#date="2018/06/12 Tue 08:00"
echo -e "$Version\n    Tor will be automatically installed and configured…\n\n"


# =========/Create File and Folder/=========

if [ ! -e "$HOME/.Traktor/Traktor_Log/install.log" ]; then
    echo -e " $Version Log: [$(date)]" | tee $HOME/.Traktor/Traktor_Log/install.log > /dev/null # echo date and time
fi

# =========/Create File and Folder/=========


# =========/Color/=========

GRE='\033[92m' # Green Light
RD='\033[91m' # Red Light
YLW='\033[93m' # Yellow Light
NC='\033[0m' # White

# =========\Color\=========


# =========\Functions\=========

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
        echo -e "\b${RD}Failed!"
        echo -e "\n${NC}Check Traktor Log in $HOME/.Traktor/Traktor_Log/install.log"
        kill -s TERM $TOP_PID
    else
        echo -e "\b${GRE}Done."
    fi
}

function updte {
    if ! { sudo apt-get update 2>&1 >> $HOME/.Traktor/Traktor_Log/install.log || echo E: update failed; } | grep -q '^[WE]:'; then
        echo success
    else
        echo failure
        exit 1
    fi
    echo ""
}

function packinOne { 
    sudo apt-get --yes --force-yes -o Dpkg::Options::="--force-confnew" install \
    tor \
    obfs4proxy
	if [ "$?" != "0" ]; then
        exit 1
	fi
}

function rslv {
    chckrslv=`apt list --installed | grep '^resolvconf/'`
    if [[ "$?" != "0" ]]; then
        echo -e "#resolvconf Not Installed!"
    fi
}

function packinTwo {
    rslv
    
    sudo apt-get install -y \
    dnscrypt-proxy \
    resolvconf \
    privoxy \
    apt-transport-tor
    if [ "$?" != "0" ]; then
        exit 1
    fi
}

function torrcbackup {
    if [ -e "/etc/tor/torrc" ]; then
        sudo cp /etc/tor/torrc /etc/tor/torrc.traktor-backup
        if [ "$?" != "0" ]; then
            exit 1
        fi
    fi

}

function bridgewrite {
    sudo wget https://raw.githubusercontent.com/TraktorPlus/Traktor/config/torrc -O /etc/tor/torrc
    if [ "$?" != "0" ]; then
        exit 1
    fi
}

function privoxyback {
    if [ -e "/etc/privoxy/config" ]; then
        sudo cp /etc/privoxy/config /etc/privoxy/config.traktor-backup
        if [ "$?" != "0" ]; then
            exit 1
        fi
    fi
}

function privoxyconf {
    sudo perl -i -pe 's/^listen-address/#$&/' /etc/privoxy/config
    cmd1="$?"
    echo 'logdir /var/log/privoxy
listen-address  0.0.0.0:8118
forward-socks5t             /     127.0.0.1:9050 .
forward         192.168.*.*/     .
forward            10.*.*.*/     .
forward           127.*.*.*/     .
forward           localhost/     .' | sudo tee /etc/privoxy/config
    cmd2="$?"
    echo ""
    sudo systemctl enable privoxy
    cmd3="$?"
    sudo systemctl restart privoxy.service
    cmd4="$?"
    echo ""
    if [ "$cmd1" != "0" ] || [ "$cmd2" != "0" ] || [ "$cmd3" != "0" ] || [ "$cmd4" != "0" ]; then
        exit 1
    fi
}

function dns {
    org_ip="127.0.0."
    for number in {10..255} ; do
    ip=$org_ip$number
    
    logfile="$HOME/.Traktor/Traktor_Log/dns.log"

    cat $logfile | grep $ip > /dev/null

    if [ "$?" == "0" ]; then # Check Log if Positive
        cat /etc/resolv.conf | grep $ip > /dev/null
        if [ "$?" == "0" ]; then # Check resolve.conf if Positive
            if { sudo netstat -antpou 2>&1; } | grep "$ip:53" | awk {'print $6'} | grep tor > /dev/null; then # Check netstat for TorDNS
                sudo sed -i '/# TorDNS/d' /etc/tor/torrc
                sudo sed -i '/DNSPort/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsOnResolve/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsSuffixes/d' /etc/tor/torrc
                echo -e "\n# TorDNS" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "DNSPort $ip:53" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsOnResolve 1" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsSuffixes .exit,.onion" | sudo tee -a /etc/tor/torrc > /dev/null
                echo -e "TorDNS Running Already( Log OK, RC OK, Net OK )\n"
                break
            elif { sudo netstat -antpou 2>&1; } | grep "$ip:53"; then
                continue
            else
                sudo sed -i '/# TorDNS/d' /etc/tor/torrc
                sudo sed -i '/DNSPort/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsOnResolve/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsSuffixes/d' /etc/tor/torrc
                echo -e "\n# TorDNS" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "DNSPort $ip:53" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsOnResolve 1" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsSuffixes .exit,.onion" | sudo tee -a /etc/tor/torrc > /dev/null
                echo -e "TorDNS Activated( Log OK, RC OK, Net NO! )\n"
                break
            fi
        else # Check resolve.conf if Negative
            if { sudo netstat -antpou 2>&1; } | grep "$ip:53" | awk {'print $6'} | grep tor > /dev/null; then # Check netstat for TorDNS
                echo "nameserver $ip" | sudo tee -a /etc/resolvconf/resolv.conf.d/head
                echo "nameserver 208.67.222.222" | sudo tee -a /etc/resolvconf/resolv.conf.d/tail # added OpenDNS
                sudo resolvconf -u
                echo -e "TorDNS Activated( Log OK, RC NO!, Net OK )\n"
                break
            elif { sudo netstat -antpou 2>&1; } | grep "$ip:53"; then
                continue
            else
                echo "nameserver $ip" | sudo tee -a /etc/resolvconf/resolv.conf.d/head
                echo "nameserver 208.67.222.222" | sudo tee -a /etc/resolvconf/resolv.conf.d/tail # added OpenDNS
                sudo resolvconf -u
                sudo sed -i '/# TorDNS/d' /etc/tor/torrc
                sudo sed -i '/DNSPort/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsOnResolve/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsSuffixes/d' /etc/tor/torrc
                echo -e "\n# TorDNS" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "DNSPort $ip:53" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsOnResolve 1" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsSuffixes .exit,.onion" | sudo tee -a /etc/tor/torrc > /dev/null
                echo -e "TorDNS Activated( Log OK, RC NO!, Net NO! )\n"
                break
            fi
        fi
    else #Check Log if Negative
        cat /etc/resolv.conf | grep $ip > /dev/null
        if [ "$?" == "0" ]; then
            if { sudo netstat -antpou 2>&1; } | grep "$ip:53" | awk {'print $6'} | grep tor > /dev/null; then # Check netstat for TorDNS
                echo -e "\nDNS Log: [$(date)]:\n$ip" | tee -a $HOME/.Traktor/Traktor_Log/dns.log > /dev/null
                echo -e "TorDNS Running Already( Log NO!, RC OK, Net OK )\n"
                break
            elif { sudo netstat -antpou 2>&1; } | grep "$ip:53"; then
                continue
            else
                sudo sed -i '/# TorDNS/d' /etc/tor/torrc
                sudo sed -i '/DNSPort/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsOnResolve/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsSuffixes/d' /etc/tor/torrc
                echo -e "\n# TorDNS" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "DNSPort $ip:53" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsOnResolve 1" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsSuffixes .exit,.onion" | sudo tee -a /etc/tor/torrc > /dev/null
                echo -e "\nDNS Log: [$(date)]:\n$ip" | tee -a $HOME/.Traktor/Traktor_Log/dns.log > /dev/null
                echo -e "TorDNS Activated( Log NO!, RC OK, Net NO! )\n"
                break
            fi
        else
            if { sudo netstat -antpou 2>&1; } | grep "$ip:53" | awk {'print $6'} | grep tor > /dev/null; then # Check netstat for TorDNS
                echo "nameserver $ip" | sudo tee -a /etc/resolvconf/resolv.conf.d/head
                echo "nameserver 208.67.222.222" | sudo tee -a /etc/resolvconf/resolv.conf.d/tail # added OpenDNS
                sudo resolvconf -u
                echo -e "\nDNS Log: [$(date)]:\n$ip" | tee -a $HOME/.Traktor/Traktor_Log/dns.log > /dev/null
                echo -e "TorDNS Activated( Log NO!, RC NO!, Net OK )\n"
                break
            elif { sudo netstat -antpou 2>&1; } | grep "$ip:53"; then
                continue
            else
                echo "nameserver $ip" | sudo tee -a /etc/resolvconf/resolv.conf.d/head
                echo "nameserver 208.67.222.222" | sudo tee -a /etc/resolvconf/resolv.conf.d/tail # added OpenDNS
                sudo resolvconf -u
                sudo sed -i '/# TorDNS/d' /etc/tor/torrc
                sudo sed -i '/DNSPort/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsOnResolve/d' /etc/tor/torrc
                sudo sed -i '/AutomapHostsSuffixes/d' /etc/tor/torrc
                echo -e "\n# TorDNS" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "DNSPort $ip:53" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsOnResolve 1" | sudo tee -a /etc/tor/torrc > /dev/null
                echo "AutomapHostsSuffixes .exit,.onion" | sudo tee -a /etc/tor/torrc > /dev/null
                echo -e "\nDNS Log: [$(date)]:\n$ip" | tee -a $HOME/.Traktor/Traktor_Log/dns.log > /dev/null
                echo -e "TorDNS Activated( Log NO!, RC NO!, Net NO! )\n"
                break
            fi
        fi
    fi

    number=$((number+1))
    done
}

function boot {
    sudo service tor restart
    if [ $? != "0" ]; then
    	exit 1
    fi
    sudo echo " " | sudo tee /var/log/tor/notices.log
    if [ $? != "0" ]; then
    	exit 1
    fi
    timer=1
    while [[ -e ./no && $timer -lt 120  ]]; do
       	if sudo cat /var/log/tor/notices.log | grep "Bootstrapped 100%: Done" > /dev/null; then
		rm ./no
		echo -e "\nBootstrapped 100%" >> $HOME/.Traktor/Traktor_Log/install.log
	else
		sleep 1
		timer=$((timer+1))
 	fi
    done
}

function addrepo {
    codename=`lsb_release -c | awk {'print $2'}`
    if [[ "$codename" =~ ^(bionic)$ ]]; then
        echo "deb tor+http://deb.torproject.org/torproject.org $codename main" | sudo tee /etc/apt/sources.list.d/tor.list
        cmd1=$?
        echo "deb-src tor+http://deb.torproject.org/torproject.org $codename main" | sudo tee -a /etc/apt/sources.list.d/tor.list
        cmd2=$?
        echo ""
    fi
}

function gpgkey {
    gpg --keyserver keys.gnupg.net --recv 886DDD89
    cmd1=$?
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
    cmd2=$?
    echo ""
    if [ "$cmd1" != "0" ] || [ "$cmd2" != "0" ]; then
        exit 1
    fi
}

function updatemain {
    if ! { sudo apt-get update 2>&1 >> $HOME/.Traktor/Traktor_Log/install.log || echo E: update failed; } | grep -q '^[WE]:'; then
        echo success
    else
        echo failure
        exit 1
    fi
    echo ""
}

function upgrademain {
    sudo sudo apt-get --yes --force-yes -o Dpkg::Options::="--force-confnew" install \
    tor \
    obfs4proxy
    checktorrc=`sudo ls /etc/tor/torrc.dpkg-old &> /dev/null`
    if [ "$?" == "0" ]; then
        sudo cat /etc/tor/torrc.dpkg-old | sudo tee /etc/tor/torrc
    fi
    echo ""
}

# =========/End Functions/=========


# =========\Call Functions\=========

sudo uname -a &> /dev/null

echo -e "\n\n\n[ #install ] Traktor $Version Install Log: [$(date)]\n" | tee -a $HOME/.Traktor/Traktor_Log/install.log > /dev/null # echo date and time

echo -ne "${NC}Updating Repository...  "
updte >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -ne "${NC}Installing packages tor and obfs4proxy...  "
packinOne >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -ne "${NC}Installing Other packages...  "
packinTwo >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
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

echo -ne "${NC}Set DNS Tor and OpenDNS...   "
dns >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading


counter=1
touch ./no
while [[ -e ./no && $counter -lt 3 ]]; do
	echo -ne "${NC}Tor is trying to establish a connection. This may take long for some minutes. Please wait...   ${YLW}"$counter"/2 Try... "
	boot
	counter=$((counter+1))
	loading
done
if [ -e ./no ]; then
	echo -e "\b${RD}Failed!"
    echo -e "\n${NC}Check Traktor Log in $HOME/.Traktor/Traktor_Log/install.log"
    kill -s TERM $TOP_PID
fi

echo -ne "${NC}Adding tor repos...   "
addrepo >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -ne "${NC}Fetching Tor signing key and adding it to the keyring...   "
gpgkey >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -ne "${NC}Updating tor from main repo...   "
updatemain >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -ne "${NC}Upgrading tor and obfs4proxy pakages...   "
upgrademain >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading


echo -e "Install Complete!" >> $HOME/.Traktor/Traktor_Log/install.log

sleep 3

# =========/End Call Functions/=========

echo -e "${GRE}\n\nCongratulations!!! Your computer is using Tor.\n Now Use this command 'traktor --help' :)\n\n${NC}"

# Excute Traktor Plus
chmod +x traktor-plus.sh
./traktor-plus.sh
