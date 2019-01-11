#!/bin/bash


##################################################
#                  Traktor V2.5                  #
#     https://github.com/TraktorPlus/Traktor     #
# https://gitlab.com/GNULand/TraktorPlus/Traktor #
##################################################


trap "exit 1" TERM
export TOP_PID=$$

clear
Version="Traktor V2.5"
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
    torbrowser-launcher \
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

function fixappar { 
        sudo sed -i '27s/PUx/ix/' /etc/apparmor.d/abstractions/tor
        if [ "$?" != "0" ]; then
            exit 1 
        fi
        sudo apparmor_parser -r -v /etc/apparmor.d/system_tor
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

function stopnet {
    sudo sed -i -e 's/\[main\]/\[main\]\ndns=none/g' /etc/NetworkManager/NetworkManager.conf
    if [ "$?" != "0" ]; then
        exit 1
    fi
}

function chkowner {
    sudo chown debian-tor:adm /var/log/tor/notices.log
    if [ "$?" != "0" ]; then
        exit 1
    else
        echo "change Ownership notices.log"
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

function libevent {
        read -p "libevent-2.0-5 not installed, do you want to install it? [Y/n] : " qa
        if [ "$qa" == "y" ] || [ "$qa" == "Y" ] || [ "$qa" == "" ]; then
            wget "http://ftp.de.debian.org/debian/pool/main/libe/libevent/libevent-2.0-5_2.0.21-stable-3_amd64.deb" -P $HOME/.Traktor/
            cmd1=$?
            sudo dpkg -i $HOME/.Traktor/libevent-2.0-5_2.0.21-stable-3_amd64.deb
            cmd2=$?
            if [ "$cmd1" != "0" ] || [ "$cmd2" != "0" ]; then
                exit 1
            fi
        else
            echo "Abort."
        fi
}

function libssl {
        read -p "libssl1.1 not installed, do you want to install it? [Y/n]: " qa
        if [ "$qa" == "y" ] || [ "$qa" == "Y" ] || [ "$qa" == "" ]; then
            wget "http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.0f-3+deb9u2_amd64.deb" -P $HOME/.Traktor/
            cmd1=$?
            sudo dpkg -i $HOME/.Traktor/libssl1.1_1.1.0f-3+deb9u1_amd64.deb
            cmd2=$?
            if [ "$cmd1" != "0" ] || [ "$cmd2" != "0" ]; then
                exit 1
            fi
        else
            echo "Abort."
        fi
}

function addrepo {
    codename=`lsb_release -c | awk {'print $2'}`
    if [[ "$codename" =~ ^(trusty|xenial|zesty|artful|bionic|wheezy|jessie|stretch|buster|sid|experimental)$ ]]; then
        echo "deb tor+http://deb.torproject.org/torproject.org $codename main" | sudo tee /etc/apt/sources.list.d/tor.list
        cmd1=$?
        echo "deb-src tor+http://deb.torproject.org/torproject.org $codename main" | sudo tee -a /etc/apt/sources.list.d/tor.list
        cmd2=$?
        echo "deb tor+http://deb.torproject.org/torproject.org obfs4proxy main" | sudo tee -a /etc/apt/sources.list.d/tor.list
        cmd3=$?
        echo ""
    else
        echo "deb tor+http://deb.torproject.org/torproject.org stable main" | sudo tee /etc/apt/sources.list.d/tor.list
        cmd4=$?
        echo "deb tor+http://deb.torproject.org/torproject.org obfs4proxy main" | sudo tee -a /etc/apt/sources.list.d/tor.list
        cmd5=$?
        echo ""
        # Check Package
        libsl=`apt list --installed 2> /dev/null | grep libssl1.1`
        if [[ "$?" == "0" ]]; then
            libsl_status=true
        else
            libsl_status=false
        fi

        libevnt=`apt list --installed 2> /dev/null | grep libevent-2.0-5`
        if [[ "$?" == "0" ]]; then
            libevnt_status=true
        else
            libevnt_status=false
        fi
        
        if [[ "$libsl_status" == "false" ]] || [[ "$libevnt_status" == "false" ]]; then
            echo -ne "\n${NC}Adding libssl or libevent...   "
            apt list --installed 2> /dev/null | grep libssl >> $HOME/.Traktor/Traktor_Log/install.log
            echo "" | tee -a $HOME/.Traktor/Traktor_Log/install.log
            apt list --installed 2> /dev/null | grep libevent >> $HOME/.Traktor/Traktor_Log/install.log
            if [[ "$libsl_status" == "false" ]]; then
                libssl
            fi
            if [[ "$libevnt_status" == "false" ]]; then
                libevent
            fi
            echo ""
        fi
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

function setip {
    echo $XDG_CURRENT_DESKTOP | grep -i gnome > /dev/null
    gnome=$?
    echo $XDG_CURRENT_DESKTOP | grep -i unity > /dev/null
    unity=$?
    echo $XDG_CURRENT_DESKTOP | grep -i ubuntu > /dev/null
    ubuntu=$?
    echo $XDG_CURRENT_DESKTOP | grep -i xfce > /dev/null
    xfce="$?"
    echo $XDG_CURRENT_DESKTOP | grep -i kde > /dev/null
    kde="$?"
    echo $XDG_CURRENT_DESKTOP | grep -i lxde > /dev/null
    lxde="$?"
    if [ "$gnome" == "0" ] || [ "$unity" == "0" ] || [ "$xfce" == "0" ] || [ "$ubuntu" == "0" ] || [ "$lxde" == "0" ]; then 
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.http host 127.0.0.1
        gsettings set org.gnome.system.proxy.http port 8118
        gsettings set org.gnome.system.proxy.socks host 127.0.0.1
        gsettings set org.gnome.system.proxy.socks port 9050
        gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '::1', '192.168.0.0/16', '192.168.8.1', '10.0.0.0/8', '172.16.0.0/12', '0.0.0.0/8', '10.0.0.0/8', '100.64.0.0/10', '127.0.0.0/8', '169.254.0.0/16', '172.16.0.0/12', '192.0.0.0/24', '192.0.2.0/24', '192.168.0.0/16', '192.88.99.0/24', '198.18.0.0/15', '198.51.100.0/24', '203.0.113.0/24', '224.0.0.0/3']"
    elif [ "$kde" == "0" ]; then
        sed -i -- 's/ProxyType=.*/ProxyType=1/g' $HOME/.config/kioslaverc
        sed -i -- 's/httpProxy=.*/httpProxy=http:\/\/127.0.0.1 8118/g' $HOME/.config/kioslaverc
        sed -i -- 's/socksProxy=.*/socksProxy=socks:\/\/127.0.0.1 9050/g' $HOME/.config/kioslavercs
    else
        echo "Your Desktop not Support!"
    fi
}

# =========/End Functions/=========


# =========\Call Functions\=========

sudo uname -a &> /dev/null

echo -e "\n\n\n[ #install ] $Version Install Log: [$(date)]\n" | tee -a $HOME/.Traktor/Traktor_Log/install.log > /dev/null # echo date and time

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

linecheck=`cat /etc/apparmor.d/abstractions/tor | head -19 | tail -1 | awk {'print $2$3$4'}`
if [ "$linecheck" != "Neededbyobfs4proxy" ]; then
    echo -ne "${NC}Fixing apparmor...   "
    fixappar >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
    loading
fi

echo -ne "${NC}Backing up privoxy...   "
privoxyback >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -ne "${NC}Config for privoxy...   "
privoxyconf >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -ne "${NC}stop Network Manager from adding dns-servers to /etc/resolv.conf...   "
stopnet >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -ne "${NC}Set DNS Tor and OpenDNS...   "
dns >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

# Fix Owner
logfile=`sudo ls /var/log/tor/notices.log &> /dev/null`
if [ "$?" != "0" ]; then
    sudo touch /var/log/tor/notices.log
    echo -e "Create notices.log" >> $HOME/.Traktor/Traktor_Log/install.log
fi
chkdebtor=`sudo ls -lha /var/log/tor/notices.log | awk {'print $3'}`
chkadm=`sudo ls -lha /var/log/tor/notices.log | awk {'print $4'}`
if [[ "$chkdebtor" != "debian-tor" ]] || [[ "$chkadm" != "adm" ]]; then
    echo -ne "${NC}Fix Owner /var/log/tor/notices.log...   "
    chkowner >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
    loading
fi

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

echo -ne "${NC}Set ip and port...   "
setip >> $HOME/.Traktor/Traktor_Log/install.log 2>&1 &
loading

echo -e "Install Complete!" >> $HOME/.Traktor/Traktor_Log/install.log

sleep 3

# =========/End Call Functions/=========

echo -e "${GRE}\n\nCongratulations!!! Your computer is using Tor.\n Now Use this command 'traktor --help' :)\n\n${NC}"

# Excute Traktor Plus
chmod +x traktor-plus.sh
./traktor-plus.sh
