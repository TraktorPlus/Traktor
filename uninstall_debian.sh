#!/bin/bash


##################################################
#                  Traktor V2.5                  #
#     https://github.com/TraktorPlus/Traktor     #
# https://gitlab.com/GNULand/TraktorPlus/Traktor #
##################################################


trap "exit 1" TERM
export TOP_PID=$$

clear
Version="V2.0"
#date="2018/04/14 Sat 15:00"

GRE='\033[92m' # Green Light
NC='\033[0m' # White
RD='\033[91m' # Red Light

if [ ! -e "$HOME/.Traktor/Traktor_Log/uninstall.log" ]; then
    echo -e "Traktor $Version Log: [$(date)]" | tee $HOME/.Traktor/Traktor_Log/uninstall.log > /dev/null
fi


echo -e "Traktor Debian Uninstaller $Version\n\n"


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
        echo -e "\n${NC}Check Traktor Log in $HOME/.Traktor/Traktor_Log/uninstall.log"
        kill -s TERM $TOP_PID
    else
        echo -e "\b${GRE}Done."
    fi
}

# Ask for Removing Packages
function ask {
    checktor=`apt list --installed 2> /dev/null | grep "^tor/"`
    if [[ "$?" == "0" ]]; then
        read -p "Do you want to remove tor package? [Y/n] : " rt #tor
        if [ "$rt" == "y" ] || [ "$rt" == "Y" ] || [ "$rt" == "" ]; then
            rt="tor"
        else
            unset rt
        fi
    fi
     
    cat $HOME/.Traktor/Traktor_Log/install.log | grep '#resolvconf' > /dev/null
    if [[ "$?" != "0" ]]; then
        read -p "$(echo -e "Do you want to remove resolvconf package? [Y/n]"$RD" (* This action is not recommended)"$NC :) " rr # resolvconf
        if [ "$rr" == "y" ] || [ "$rr" == "Y" ] || [ "$rr" == "" ]; then
            rr="resolvconf"
        else
            unset rr
        fi
    fi
    
    checkobfs4proxy=`apt list --installed 2> /dev/null | grep "^obfs4proxy/"`
    if [[ "$?" == "0" ]]; then
        read -p "Do you want to remove obfs4proxy package? [Y/n] : " ro # obfs4proxy
        if [ "$ro" == "y" ] || [ "$ro" == "Y" ] || [ "$ro" == "" ]; then
            ro="obfs4proxy"
        else
            unset ro
        fi
    fi
    
    checkprivoxy=`apt list --installed 2> /dev/null | grep "^privoxy/"`
    if [[ "$?" == "0" ]]; then
        read -p "Do you want to remove privoxy package? [Y/n] : " rp # privoxy
        if [ "$rp" == "y" ] || [ "$rp" == "Y" ] || [ "$rp" == "" ]; then
            rp="privoxy"
        else
            unset rp
        fi
    fi
    
    checkdnsproxy=`apt list --installed 2> /dev/null | grep "^dnscrypt-proxy/"`
    if [[ "$?" == "0" ]]; then
        read -p "Do you want to remove dnscrypt-proxy package? [Y/n] : " rd # dnscrypt-proxy
        if [ "$rd" == "y" ] || [ "$rd" == "Y" ] || [ "$rd" == "" ]; then
            rd="dnscrypt-proxy"
        else
            unset rd
        fi
    fi
    
    checktorbrowser=`apt list --installed 2> /dev/null | grep "^torbrowser-launcher/"`
    if [[ "$?" == "0" ]]; then
        read -p "Do you want to remove torbrowser-launcher package? [Y/n] : " rtb # torbrowser-launcher
        if [ "$rtb" == "y" ] || [ "$rtb" == "Y" ] || [ "$rtb" == "" ]; then
            rtb="torbrowser-launcher"
        else
            unset rtb
        fi
    fi
    
    checkapt=`apt list --installed 2> /dev/null | grep "^apt-transport-tor/"` 
    if [[ "$?" == "0" ]]; then
        read -p "Do you want to remove apt-transport-tor package? [Y/n] : " ratt # apt-transport-tor
        if [ "$ratt" == "y" ] || [ "$ratt" == "Y" ] || [ "$ratt" == "" ]; then
            ratt="apt-transport-tor"
        else
            unset ratt
        fi
    fi
    echo -e ""
}

# Removing Packages
function rmv {
    sudo apt-get purge -y \
    $rt \
    $rr \
    $ro \
    $rp \
    $rd \
    $rtb \
    $ratt 
    
    if [[ "$rt" == "tor" ]]; then
        echo -e "\ntor uninstalling\n"
    fi
    
    if [[ "$rr" == "resolvconf" ]]; then
        echo -e "\nresolvconf uninstalling\n"
    fi
    
    if [[ "$ro" == "obfs4proxy" ]]; then
        echo -e "\nobfs4proxy uninstalling\n"
    fi
    
    if [[ "$rp" == "privoxy" ]]; then
        echo -e "\nprivoxy uninstalling\n"
    fi
    
    if [[ "$rd" == "dnscrypt-proxy" ]]; then
        echo -e "\ndnscrypt-proxy uninstalling\n"
    fi
    
    if [[ "$rtb" == "torbrowser-launcher" ]]; then
        echo -e "\ntorbrowser-launcher uninstalling\n"
    fi
    
    if [[ "$ratt" == "apt-transport-tor" ]]; then
        echo -e "\napt-transport-tor uninstalling\n"
    fi
    
    sudo apt-get autoremove -y
    
    echo -e ""
}

# Remove Repo Tor Source List & Repo Key
function rmvppa {
    sudo rm -rf /etc/apt/sources.list.d/tor.list
    sudo apt-key del A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
    
    echo -e ""
}

# Undo DNS
function fixnetm {
    if [[ "$rr" == "resolvconf" ]]; then
        sudo sed -i '/dns=none/d' /etc/NetworkManager/NetworkManager.conf
    fi
}

# remove proxy
function unsetip {
    echo $XDG_CURRENT_DESKTOP | grep -i gnome > /dev/null
    gnome=$?
    echo $XDG_CURRENT_DESKTOP | grep -i ubuntu > /dev/null
    ubuntu=$?
    echo $XDG_CURRENT_DESKTOP | grep -i xfce > /dev/null
    xfce="$?"
    echo $XDG_CURRENT_DESKTOP | grep -i kde > /dev/null
    kde="$?"
    echo $XDG_CURRENT_DESKTOP | grep -i lxde > /dev/null
    lxde="$?"
    if [ "$gnome" == "0" ] || [ "$xfce" == "0" ] || [ "$ubuntu" == "0" ] || [ "$lxde" == "0" ]; then # Undo Proxy System Wide for Gnome, Unity, XFCE, LXDE ...
        gsettings set org.gnome.system.proxy mode 'none'
        gsettings set org.gnome.system.proxy.http host ''
        gsettings set org.gnome.system.proxy.http port 0
        gsettings set org.gnome.system.proxy.socks host ''
        gsettings set org.gnome.system.proxy.socks port 0
        gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '::1']"
    elif [ "$kde" == "0" ]; then # Undo Proxy System Wide for KDE
        sed -i -- 's/ProxyType=.*/ProxyType=0/g' $HOME/.config/kioslaverc
        sed -i -- 's/httpProxy=.*/httpProxy=/g' $HOME/.config/kioslaverc
        sed -i -- 's/socksProxy=.*/socksProxy=/g' $HOME/.config/kioslaverc
    else
        echo -e "\nYour Desktop not Support!"
    fi
}

function reslvcnf {
    checkrslvcnfdic=`ls -lha /etc/resolv.conf | grep "/run/systemd/resolve/stub-resolv.conf"`
    if [[ "$?" != "0" ]]; then
        stub=`sudo ls /run/systemd/resolve/stub-resolv.conf`
        if [[ "$?" == "0" ]]; then
            ln -s /etc/resolv.conf /run/systemd/resolve/stub-resolv.conf
        else
            rslv=`sudo ls /run/resolvconf/resolv.conf`
            if [[ "$?" == "0" ]]; then
                ln -s /etc/resolv.conf /run/resolvconf/resolv.conf
            else
                echo -e "${RD}\nSomething Wrong for DNS! Please Report it..."
            fi
        fi
    fi
}

sudo uname -a &> /dev/null

echo -e "\n\n\n[ #Uninstall ] Traktor $Version Uninstall Log: [$(date)]\n" | tee -a $HOME/.Traktor/Traktor_Log/uninstall.log > /dev/null
ask

if [[ $rt == "tor" ]] || [[ $rr == "resolvconf" ]] || [[ $ro == "obfs4proxy" ]] || [[ $rp == "privoxy" ]] || [[ $rd == "dnscrypt-proxy" ]] || [[ $rtb == "torbrowser-launcher" ]] || [[ $ratt == "apt-transport-tor" ]]; then
    echo -ne "${NC}\n\nUninstalling Packages... "
    rmv >> $HOME/.Traktor/Traktor_Log/uninstall.log 2>&1 &
    loading
fi

checkppa=`ls /etc/apt/sources.list.d/tor.list &> /dev/null`
if [[ "$?" == "0" ]]; then
    echo -ne "${NC}Uninstalling tor PPA... "
    rmvppa >> $HOME/.Traktor/Traktor_Log/uninstall.log 2>&1 &
    loading
fi


if [[ "$rr" == "resolvconf" ]]; then
    echo -ne "${NC}Fix resolv.conf... "
    reslvcnf >> $HOME/.Traktor/Traktor_Log/uninstall.log 2>&1 &
    loading
    
    echo -ne "${NC}set dns none in NetworkManager.conf... "
    fixnetm >> $HOME/.Traktor/Traktor_Log/uninstall.log 2>&1 &
    loading
fi

echo -ne "${NC}Unset ip and port... "
unsetip >> $HOME/.Traktor/Traktor_Log/uninstall.log 2>&1 &
loading

echo -e "Uninstalling Complete!" >> $HOME/.Traktor/Traktor_Log/uninstall.log
echo -e "\n\nUninstalling Complete!"
