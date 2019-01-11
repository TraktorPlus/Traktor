#!/bin/bash


##################################################
#                  Traktor V2.5                  #
#     https://github.com/TraktorPlus/Traktor     #
# https://gitlab.com/GNULand/TraktorPlus/Traktor #
##################################################


# =========/Color/=========

GRE='\033[92m' # Green Light
RD='\033[91m' # Red Light
YLW='\033[93m' # Yellow Light
NC='\033[0m' # White

# =========\Color\=========

function proxyssh {
    echo -e "\n${YLW}step 3 of 3:${NC}"
    read -p "do you want to set Tor on SSH? [Y/n]: " qs
    if [ "$qs" == "y" ] || [ "$qs" == "Y" ] || [ "$qs" == "" ]; then
        sudo ls -lha $HOME/.ssh/config
        if [ "$?" == "0" ]; then
            cp $HOME/.ssh/config $HOME/.ssh/config-backup
        fi
        echo "Host *
CheckHostIP no
Compression yes
Protocol 2
ProxyCommand connect -4 -S localhost:9050 $(tor-resolve %h localhost:9050) %p" | tee $HOME/.ssh/config > /dev/null
    echo -e "\nset SOCKS Proxy on SSH" >> $HOME/.Traktor/Traktor_Log/install.log
    else
        echo "Abort."
    fi
}

function proxygit {
    echo -e "\n${YLW}step 2 of 3:${NC}"
    read -p "do you want to set Tor on git? [Y/n]: " qg
    if [ "$qg" == "y" ] || [ "$qg" == "Y" ] || [ "$qg" == "" ]; then
        git config --global http.proxy http://localhost:8118
        echo -e "\nset HTTP Proxy on git" >> $HOME/.Traktor/Traktor_Log/install.log
        proxyssh
    else
        echo "Abort."
        proxyssh
    fi
}

function proxyapt {
    echo -e "\n${YLW}step 1 of 3:${NC}"
    read -p "do you want to set Tor on APT? [Y/n]: " qapt
    if [ "$qapt" == "y" ] || [ "$qapt" == "Y" ] || [ "$qapt" == "" ]; then
        sudo ls /etc/apt/apt.conf &> /dev/null
        if [ "$?" == "0" ]; then
            cp /etc/apt/apt.conf /etc/apt/apt.conf-backup
        fi
        echo 'Acquire::https::Proxy "https://127.0.0.1:8118";' | sudo tee /etc/apt/apt.conf > /dev/null
        echo -e "\nset HTTPS Proxy on APT" >> $HOME/.Traktor/Traktor_Log/install.log
        proxygit
    else
        echo "Abort."
        proxygit
    fi
}

function ask {
    echo -e "\n\n\n\n${GRE}** Welcome to Traktor Plus **\n\n${NC}"
    read -p 'this script set Tor Proxy on SSH, APT and git. press "Y" to continue or Press "N" to cancel it... ' qc
    if [ "$qc" == "y" ] || [ "$qc" == "Y" ] || [ "$qc" == "Enter" ] || [ "$qc" == "enter" ] || [ "$qc" == "" ]; then
        proxyapt
    elif [ "$qc" == "n" ] || [ "$qc" == "N" ]; then
        echo -e "\nif changes your mind, please run ./traktor-plus.sh :)."
    else
        echo -e "\nif changes your mind, please run ./traktor-plus.sh :)."
    fi
}

ask
