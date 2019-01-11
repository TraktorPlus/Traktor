#!/bin/bash


##################################################
#                  Traktor V2.5                  #
#     https://github.com/TraktorPlus/Traktor     #
# https://gitlab.com/GNULand/TraktorPlus/Traktor #
##################################################


clear


# =========\Create File and Folder\=========

if [ "$1" == "help" ]; then
    clear   
    less help
    exit
fi

if [ ! -d "$HOME/.Traktor/" ]; then
    mkdir "$HOME/.Traktor"
fi
if [ ! -d "$HOME/.Traktor/Traktor_Log/" ]; then
    mkdir "$HOME/.Traktor/Traktor_Log"
fi
if [ ! -e "$HOME/.Traktor/Traktor_Log/traktor.log" ]; then
    echo -e "Traktor Log: [$(date)]" | tee $HOME/.Traktor/Traktor_Log/traktor.log > /dev/null
fi
if [ ! -e "$HOME/.Traktor/Traktor_Log/dns.log" ]; then
    echo -e "DNS Log: [$(date)]" | tee $HOME/.Traktor/Traktor_Log/dns.log > /dev/null
fi
if [ ! -e "$HOME/.Traktor/Traktor_Log/traktor_status.log" ]; then
    echo -e "Traktor Status Log: [$(date)]" | tee $HOME/.Traktor/Traktor_Log/traktor_status.log > /dev/null
fi

# =========/Create File and Folder/=========


# =========\Main\=========
check_distro=0
#Checking if the distro is debianbase / archbase / redhatbase/ openSUSEbae and running the correct script
codename=`lsb_release -c | awk {'print $2'}`
architecture=`dpkg --print-architecture`
if pacman -Q &> /dev/null; then # Check Arch
    sudo chmod +x ./traktor_arch.sh
    ./traktor_arch.sh # Run Traktor Arch
elif [[ "$codename" == "bionic" ]] && [[ "$architecture" == "armhf" ]]; then
    sudo chmod +x ./traktor_raspberry.sh
    ./traktor_raspberry.sh # Run Traktor Raspberry
elif apt list --installed &> /dev/null; then # Check Debian
    sudo chmod +x ./traktor_debian.sh 
    ./traktor_debian.sh # Run Traktor Debian
elif dnf list &> /dev/null; then
    sudo chmod +x ./traktor_fedora.sh
    ./traktor_fedora.sh # Run Traktor Fedora
elif zypper search i+ &> /dev/null; then
    sudo chmod +x ./traktor_opensuse.sh
    ./traktor_opensuse.sh # Run Traktor OpenSUSE
else
    echo "Your distro is neither archbase nor debianbase nor redhatbase nor susebase So, The script is not going to work in your distro."
    check_distro="1"
fi


echo -e "\n[$(date)] traktor installed " | tee -a $HOME/.Traktor/Traktor_Log/traktor.log > /dev/null
if [ "$check_distro" == "0" ]; then
#==========Adding Traktor Command================
    sudo cp traktor /usr/bin/traktor 
	#command_adding="$?"
    sudo chmod 755 /usr/bin/traktor
	#change_mode="$?"
	#if [ "$command_adding" == "0" ] && [ "$change_mode" == "0" ] ; then
	#    echo "Now Use this command 'traktor --help'"
	#fi
#=======Traktor Command Must Be Added============
else
    exit 1
fi
