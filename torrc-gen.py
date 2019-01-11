#!/usr/bin/python3

##################################################
#                  Traktor V2.5                  #
#     https://github.com/TraktorPlus/Traktor     #
# https://gitlab.com/GNULand/TraktorPlus/Traktor #
##################################################

import os
hosts = os.popen("hostname -I").read()
hosts = hosts.replace('\n','')
hostsList = hosts.split(' ')
hostsList.pop()
newIp = []
for host in hostsList:
    newIp.append('.'.join((host.split('.'))[:-1])+'.0/24')
tmp=''
for ip in newIp:
    tmp = tmp + "SOCKSPolicy accept "+ip+"\n" 

File = open("/etc/tor/torrc" , 'r')
tor = File.read()
File.close()

if ("SocksPort" in tor) or ("SOCKSPolicy" in tor):
    tor_swap = []
    tor = tor.split('\n')
    for line in tor:
        if "SocksPort" in line :
            tor_swap.append((line + '\n' + tmp +"SOCKSPolicy accept 127.0.0.0/24\n" +"SOCKSPolicy reject *"))
        elif 'SOCKSPolicy' in line:
            pass
        else:
            tor_swap.append(line)
    
    tor = '\n'.join(tor_swap)

else:
    tor = tor + "\n# Share Proxy\nHTTPTunnelPort 0.0.0.0:8181\nSocksPort 0.0.0.0:9050\n"+ tmp +"SOCKSPolicy accept 127.0.0.0/24\n"+ "SOCKSPolicy reject *"

File1 = open("/etc/tor/torrc",'w')
File1.write(tor)
File1.close()
