###################
### Basic steup ###
###################


## Interface list for firewall
##############################
/interface list
add name=LAN
add comment=WAN name=WAN

/interface list member
add interface=v100-LAN list=LAN
add interface=v200-WLAN list=LAN
add interface=v997-MGMNT list=LAN
add interface=v1000-VM-DHCP list=LAN
add interface=wlan1 list=LAN
add interface=wlan2 list=LAN
add interface=bridge_local list=LAN
add comment=Plus interface=ether1 list=WAN

## Services
###########
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes

## More loggs
#############
/system logging action
set 0 memory-lines=1000
set 1 disk-file-count=10 disk-lines-per-file=1000

## Turn off neighbor discovery
#############################
/ip neighbor discovery-settings
set discover-interface-list=none

## Better encryption
####################
/ip ssh
set host-key-type=ed25519 strong-crypto=yes

## Turn off things you don't use
################################
/system watchdog
set automatic-supout=no watchdog-timer=no
/tool bandwidth-server
set authenticate=no enabled=no
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=none
/tool mac-server ping
set enabled=no

## Add graphing
###############
/tool graphing interface
add
/tool graphing resource
add


#####################
### IPv4 Firewall ###
#####################


## Turn on uRPF if is posible
#############################
/ip settings
set max-neighbor-entries=1024 rp-filter=strict secure-redirects=no send-redirects=no

## Firewall adress list
##########################

/ip firewall address-list
# rfc6890 bogons prefix
add address=0.0.0.0/8 list=rfc6890
add address=172.16.0.0/12 list=rfc6890
add address=192.168.0.0/16 list=rfc6890
add address=10.0.0.0/8 list=rfc6890
add address=169.254.0.0/16 list=rfc6890
add address=127.0.0.0/8 list=rfc6890
add address=224.0.0.0/4 list=rfc6890
add address=198.18.0.0/15 list=rfc6890
add address=192.0.0.0/24 list=rfc6890
add address=198.51.100.0/24 list=rfc6890
add address=203.0.113.0/24 list=rfc6890
add address=240.0.0.0/4 list=rfc6890
add address=192.88.99.0/24 list=rfc6890
# DNS addresses
add address=8.8.8.8 list=dns
add address=1.1.1.1 list=dns
# Add the mikrotik addres if you want to use it as dns server
add address=10.0.y.1 list=dns
# NTP addresses
add address=pool.ntp.org list=ntp
# Addresses that will be able to log in to Mikrotik
add address=10.0.a.62 comment=Computer list=my_device
add address=10.0.b.62 comment=Laptop list=my_device
# local-networks
add address=10.0.a.0/24 comment=lan list=local_networks
add address=10.0.b.0/24 comment=wlan list=local_networks
# Network devices
add address=10.0.y.1 comment=router list=net_devices
add address=10.0.y.2 comment=switch list=net_devices
# IoT devices that don't be allow to connect with internet.
add address=10.0.x.z list=iot_devices
add address=10.0.x.z list=iot_devices
add address=10.0.x.z list=iot_devices

## Firewall filter
###################

/ip firewall filter
add action=passthrough chain=forward comment="==========FORWARD=========="
add action=log chain=forward comment="log befor drop" connection-state=invalid log-prefix=ipv4_forward_drop_invalid
add action=drop chain=forward comment="drop invalid" connection-state=invalid
add action=drop chain=forward comment="drop iot" src-address-list=iot_devices
add action=accept chain=forward comment="accept established" connection-state=established
add action=accept chain=forward comment="accept related" connection-state=related
add action=accept chain=forward comment="accept new to internet" connection-state=new out-interface-list=WAN
add action=jump chain=forward comment="jump forward for lan" jump-target=local_forward
add action=log chain=forward comment="log befor drop" log-prefix=ipv4_forward_drop
add action=drop chain=forward comment="drop else"

add action=passthrough chain=input comment="==========INPUT=========="
add action=log chain=input comment="log befor drop" connection-state=invalid log-prefix=ipv4_input_drop_invalid
add action=drop chain=input comment="drop invalid" connection-state=invalid
add action=accept chain=input comment="accept established" connection-state=established
add action=accept chain=input comment="aacept related" connection-state=related
add action=accept chain=input comment="accept ssh" connection-state=new dst-address=10.0.y.1 dst-port=22 in-interface-list=LAN protocol=tcp src-address-list=my_device
add action=accept chain=input comment="accept winbox" connection-state=new dst-address=10.0.y.1 dst-port=6559 in-interface-list=LAN protocol=tcp src-address-list=my_device
add action=accept chain=input comment="accept http(s)" connection-state=new dst-address=10.0.y.1 dst-port=6560 in-interface-list=LAN protocol=tcp src-address-list=my_device
add action=accept chain=input comment="accept new dns" connection-state=new dst-port=53 in-interface-list=LAN protocol=tcp
add action=accept chain=input comment="accept new dot - not supported" connection-state=new dst-port=853 in-interface-list=LAN protocol=tcp
add action=accept chain=input comment="accept new dns" connection-state=new dst-port=53 in-interface-list=LAN protocol=udp
add action=accept chain=input comment="accept new dot - not supported" connection-state=new dst-port=853 in-interface-list=LAN protocol=udp
add action=accept chain=input comment="accept ntp - local" connection-state=new dst-port=123 in-interface-list=LAN protocol=udp
add action=accept chain=input comment="accept dhcp" connection-state=new dst-port=67 in-interface-list=LAN protocol=udp
add action=log chain=input comment="log befor drop" log-prefix=ipv4_input_drop
add action=drop chain=input comment="drop else"

add action=passthrough chain=output comment="==========OUTPUT=========="
add action=accept chain=output comment="accept established" connection-state=established
add action=accept chain=output comment="accept related" connection-state=related
add action=accept chain=output comment="accept new ntp - internet" connection-state=new dst-address-list=ntp dst-port=123 out-interface-list=WAN protocol=udp src-address=192.168.0.10 src-port=123
add action=accept chain=output comment="accept new dns - internet" connection-state=new dst-address-list=dns dst-port=53 out-interface-list=WAN protocol=tcp
add action=accept chain=output comment="accept new dns - internet" connection-state=new dst-address-list=dns dst-port=853 out-interface-list=WAN protocol=tcp
add action=accept chain=output comment="accept new dns - internet" connection-state=new dst-address-list=dns dst-port=53 out-interface-list=WAN protocol=udp
add action=accept chain=output comment="accept new dns - internet" connection-state=new dst-address-list=dns dst-port=853 out-interface-list=WAN protocol=udp
add action=accept chain=output comment="accept new dns loopback" connection-state=new dst-address=10.0.10.1 dst-port=53 protocol=tcp src-address=10.0.10.1
add action=accept chain=output comment="accept new dns loopback" connection-state=new dst-address=10.0.10.1 dst-port=53 protocol=udp src-address=10.0.10.1
add action=accept chain=output comment="accept capsman" connection-state="" dst-port=5246 out-interface-list=LAN protocol=udp disabled=yes
add action=accept chain=output comment="accept capsman" connection-state="" dst-port=5247 out-interface-list=LAN protocol=udp disabled=yes
add action=accept chain=output comment="accept new icmp" connection-state=new protocol=icmp
add action=accept chain=output comment="accept dhcp" disabled=yes dst-port=68 out-interface-list=LAN protocol=udp
add action=log chain=output comment="log befor drop" log-prefix=ipv4_output_drop
add action=drop chain=output comment="drop else"

add action=passthrough chain=local_forward comment="==========LOCAL==========" 
add action=accept chain=local_forward comment="accept new for mgmnt" connection-state=new dst-address-list=net_devices src-address-list=my_device
add action=accept chain=local_forward comment="accept new for iot" connection-state=new dst-address-list=iot_devices src-address-list=my_device
add action=return chain=local_forward

## NAT
######

/ip firewall nat
add action=masquerade chain=srcnat comment=LAN out-interface=ether1 src-address=10.0.10.0/24
add action=masquerade chain=srcnat comment=WLAN out-interface=ether1 src-address=10.0.20.0/24
add action=masquerade chain=srcnat comment="Only for update puprose" disabled=yes out-interface=ether1 src-address=10.0.y.1/28

## Firewall RAW
###############

/ip firewall raw
add action=passthrough chain=prerouting comment="==========ALL=========="
add action=jump chain=prerouting comment="jump to wan" in-interface-list=WAN jump-target=wan
add action=jump chain=prerouting comment="jump to lan" in-interface-list=LAN jump-target=lan
add action=jump chain=prerouting comment="jump to tcp" jump-target=tcp protocol=tcp
add action=jump chain=prerouting comment="jump to udp" jump-target=udp protocol=udp
add action=jump chain=prerouting comment="jump to icmp" jump-target=icmp4 protocol=icmp
# Accept what's left
add action=passthrough chain=prerouting comment="==========Else=========="
add action=accept chain=prerouting comment="wan -> accept else" in-interface-list=WAN
add action=accept chain=prerouting comment="lan -> accept else" in-interface-list=LAN
add action=log chain=prerouting comment="log befor drop" log-prefix="raw6_else_drop" 
add action=drop chain=prerouting comment="drop else"

add action=passthrough chain=wan comment="==========WAN==========" 
add action=log chain=wan comment="log befor drop" log-prefix=raw4_wan_drop src-address-list=rfc6890
add action=drop chain=wan comment="drop rfc6890" src-address-list=rfc6890
add action=return chain=wan comment="return else"

add action=passthrough chain=lan comment="==========LAN=========="
add action=return chain=lan comment="return local client" src-address-list=local_networks
add action=return chain=lan comment="return net devices" src-address-list=net_devices
add action=return chain=lan comment="return iot devices" src-address-list=iot_devices
# For dhcp purpose.
add action=return chain=lan comment="return for brodcast" dst-address=255.255.255.255 src-address=0.0.0.0
add action=log chain=lan comment="log befor drop" log-prefix=raw4_lan_drop
add action=drop chain=lan comment="drop else"

add action=passthrough chain=tcp comment="==========TCP=========="
add action=drop chain=tcp comment="tag filter" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
add action=drop chain=tcp comment="flag filter: fin + ack" protocol=tcp tcp-flags=fin,syn
add action=drop chain=tcp comment="flag filter: fin + rst" protocol=tcp tcp-flags=fin,rst
add action=drop chain=tcp comment="flag filter: fin - ack" protocol=tcp tcp-flags=fin,!ack
add action=drop chain=tcp comment="flag filter: fin + urg" protocol=tcp tcp-flags=fin,urg
add action=drop chain=tcp comment="flag filter: syn + rst" protocol=tcp tcp-flags=syn,rst
add action=drop chain=tcp comment="flag filter: rst + rug" protocol=tcp tcp-flags=rst,urg
add action=drop chain=tcp comment="drop port 0" port=0 protocol=tcp
add action=jump chain=tcp comment="jump to virus" jump-target=tcp-virus
add action=accept chain=tcp comment="accept else"

add action=passthrough chain=udp comment="==========UDP==========" 
add action=drop chain=udp comment="drop port 0" port=0 protocol=udp
add action=accept chain=udp comment="accept dhcp" dst-address=255.255.255.255 \
    dst-port=67 protocol=udp src-address=0.0.0.0 src-port=68
add action=jump chain=udp comment="jum to virus" jump-target=udp-virus
add action=accept chain=udp comment="accept else"

add action=passthrough chain=icmp4 comment="==========ICMP==========" 
add action=accept chain=icmp4 comment="echo reply" icmp-options=0:0 limit=5,10:packet protocol=icmp
add action=accept chain=icmp4 comment="net unreachable" icmp-options=3:0 protocol=icmp
add action=accept chain=icmp4 comment="host unreachable" icmp-options=3:1 protocol=icmp
add action=accept chain=icmp4 comment="protocol unreachable" icmp-options=3:2 protocol=icmp
add action=accept chain=icmp4 comment="port unreachable" icmp-options=3:3 protocol=icmp
add action=accept chain=icmp4 comment="fragmentation needed" icmp-options=3:4 protocol=icmp
add action=accept chain=icmp4 comment=echo icmp-options=8:0 limit=5,10:packet protocol=icmp
add action=accept chain=icmp4 comment="time exceeded " icmp-options=11:0-1 protocol=icmp
add action=log chain=icmp4 comment="log befor drop" log-prefix=raw4_icmp_drop
add action=drop chain=icmp4 comment="drop else" protocol=icmp

# Mostly useless. There is some spontaneous traffic on ports: 135,445,65506
add action=drop chain=tcp-virus comment="Drop Firehotcker" dst-port=79 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Blaster Worm" dst-port=135-139 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Blaster Worm" dst-port=445 protocol=tcp
add action=drop chain=tcp-virus comment=________ dst-port=593 protocol=tcp
add action=drop chain=tcp-virus comment=________ dst-port=1024-1030 protocol=tcp
add action=drop chain=tcp-virus comment="Drop MyDoom" dst-port=1080 protocol=tcp
add action=drop chain=tcp-virus comment=________ dst-port=1214 protocol=tcp
add action=drop chain=tcp-virus comment="ndm requester" dst-port=1363protocol=tcp
add action=drop chain=tcp-virus comment="ndm server" dst-port=1364 protocol=tcp
add action=drop chain=tcp-virus comment="screen cast" dst-port=1368 protocol=tcp
add action=drop chain=tcp-virus comment=hromgrafx dst-port=1373 protocol=tcp
add action=drop chain=tcp-virus comment=cichlid dst-port=1377 protocol=tcp
add action=drop chain=tcp-virus comment=Worm dst-port=1433-1434 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Dumaru.Y " dst-port=2283 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Beagle" dst-port=2535 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Beagle.C-K" dst-port=2745 protocol=tcp
add action=drop chain=tcp-virus comment="Bagle Virus " dst-port=2745 protocol=tcp
add action=drop chain=tcp-virus comment="Drop MyDoom" dst-port=3127-3128 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Backdoor OptixPro" dst-port=3410 protocol=tcp
add action=drop chain=tcp-virus comment=Worm dst-port=4444 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Sasser" dst-port=5554 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Beagle.B" dst-port=8866 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Dabber.A-B" dst-port=9898 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Dumaru.Y" dst-port=10000 protocol=tcp
add action=drop chain=tcp-virus comment="Drop MyDoom.B" dst-port=10080 protocol=tcp
add action=drop chain=tcp-virus comment="Drop NetBus" dst-port=12345 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Kuang2" dst-port=17300 protocol=tcp
add action=drop chain=tcp-virus comment="Drop SubSeven" dst-port=27374 protocol=tcp
add action=drop chain=tcp-virus comment="Drop PhatBot, Agobot, Gaobot" dst-port=65506 protocol=tcp
add action=return chain=tcp-virus

# Mostly useless.
add action=drop chain=udp-virus comment="Drop Firehotcker" dst-port=79 protocol=udp
add action=drop chain=udp-virus comment="Drop Messenger Worm" dst-port=135-139 protocol=udp
add action=drop chain=udp-virus comment="Drop Blaster Worm" dst-port=445 protocol=udp
add action=drop chain=udp-virus comment=Worm dst-port=4444 protocol=udp
add action=return chain=udp-virus

#####################
### IPv6 Firewall ###
#####################


## Turn on urpf if is posible
#############################
/ipv6 settings
set accept-redirects=no accept-router-advertisements=yes max-neighbor-entries=254

## Firewall adress list
##########################

/ipv6 firewall address-list
# rfc6890 bogons prefix
add address=::1/128 list=rfc6890
add address=::ffff:0.0.0.0/96 list=rfc6890
add address=::/96 list=rfc6890
add address=100::/64 list=rfc6890
add address=2001:10::/28 list=rfc6890
add address=2001:2::/48 list=rfc6890
add address=2001:db8::/32 list=rfc6890
add address=2001::/23 list=rfc6890
add address=2002::/16 list=rfc6890
add address=fc00::/7 list=rfc6890
add address=fec0::/10 list=rfc6890
add address=::/128 list=rfc6890_bad_dst
add address=::/128 comment="one execption" list=rfc6890_bad_src
add address=ff00::/8 list=rfc6890_bad_src
# DNS addresses
add address=2001:4860:4860::8888/128 list=dns
add address=2606:4700::1111/128 list=dns
# Add the mikrotik addres if you want to use it as dns server
add address=xxxx:xxxx:xxxx:xxxx::x/128 list=dns
# Prefix that you use
add address=xxxx:xxxx:xxxx:xxxx::x/56 list=my_prefix
# Some basic multicast
add address=ff02::1:ff00:0/104 comment=solicited-node list=local-multicast
add address=ff02::1/128 comment=all-nodes list=local-multicast
add address=ff02::2/128 comment=all-routers list=local-multicast
add address=ff02::16/128 comment=mldv2 list=local-multicast
add address=ff02::6a/128 comment=all-snoopers list=local-multicast
add address=ff02::1:2/128 comment=dhcp list=local-multicast

## Firewall filter
###################

/ipv6 firewall filter
add action=passthrough chain=forward comment="==========FORWARD=========="
add action=log chain=forward comment="drop befor log" connection-state=invalid log-prefix=ipv6_forward_drop_invalid
add action=drop chain=forward comment="drop invalid" connection-state=invalid
add action=accept chain=forward comment="accept establish" connection-state=established
add action=accept chain=forward comment="accept related" connection-state=related
add action=accept chain=forward comment="accept new to internet" connection-state=new out-interface-list=WAN src-address-list=my_prefix
add action=log chain=forward comment="drop befor log" log-prefix=ipv6_forward_drop
add action=drop chain=forward comment="accept new to internet" 

add action=passthrough chain=input comment="==========INPUT=========="
add action=log chain=input comment="drop befor log" connection-state=invalid log-prefix=ipv6_input_drop_invalid
add action=drop chain=input comment="drop invalid" connection-state=invalid
add action=accept chain=input comment="accept established" connection-state=established
add action=accept chain=input comment="accept related" connection-state=related
add action=accept chain=input comment="accept new dns" connection-state=new dst-port=53 in-interface-list=LAN protocol=tcp
add action=accept chain=input comment="accept new dot - not supported" connection-state=new dst-port=853 in-interface-list=LAN protocol=tcp
add action=accept chain=input comment="accept new dns" connection-state=new dst-port=53 in-interface-list=LAN protocol=udp
add action=accept chain=input comment="accept new dot - not supported" connection-state=new dst-port=853 in-interface-list=LAN protocol=udp
add action=accept chain=input comment="accept new dot - not supported" connection-state=new dst-port=123 in-interface-list=LAN protocol=udp src-port=123
add action=accept chain=input comment="accept icmpv6" protocol=icmpv6
add action=accept chain=input comment="accept dhcpv6 - internet" connection-state=new dst-port=546 in-interface-list=WAN protocol=udp src-port=547
add action=accept chain=input comment="accept dhcpv6 - lan" connection-state=new dst-port=547 in-interface-list=LAN protocol=udp src-port=546
add action=log chain=input comment="log befor drop" log-prefix=ipv6_input_drop
add action=drop chain=input comment="drop else"

add action=passthrough chain=output comment="==========OUTPUT=========="
add action=accept chain=output comment="accept estalished" connection-state=established
add action=accept chain=output comment="accept related" connection-state=related
add action=accept chain=output comment="accept new icmpv6" protocol=icmpv6
add action=accept chain=output comment="accept new ntp - internet" connection-state=new dst-port=123 out-interface-list=WAN protocol=udp src-port=123
add action=accept chain=output comment="accept dhcpv6 - internet" connection-state=new dst-port=547 out-interface-list=WAN protocol=udp src-port=546
add action=accept chain=output comment="accept dhcpv6 - lan" connection-state=new dst-port=546 out-interface-list=LAN protocol=udp src-port=547
add action=accept chain=output comment="accept new dns - internet" connection-state=new dst-address-list=dns dst-port=53 out-interface-list=WAN protocol=tcp
add action=accept chain=output comment="accept new dot - internet" connection-state=new dst-address-list=dns dst-port=853 out-interface-list=WAN protocol=tcp
add action=accept chain=output comment="accept new dns - internet" connection-state=new dst-address-list=dns dst-port=53 out-interface-list=WAN protocol=udp
add action=accept chain=output comment="accept new dot - internet" connection-state=new dst-address-list=dns dst-port=853 out-interface-list=WAN protocol=udp
add action=log chain=output comment="log befor drop" log-prefix=ipv6_output_drop
add action=drop chain=output comment="drop else"

## Firewall RAW
###############

/ipv6 firewall raw
add action=passthrough chain=prerouting comment="=========ALL========="
add action=jump chain=prerouting comment="jump to bogon filter" jump-target=rfc6890
add action=jump chain=prerouting comment="jump to prefix" jump-target=prefix
add action=jump chain=prerouting comment="jump to tcp filter" jump-target=tcp protocol=tcp
add action=jump chain=prerouting comment="jump to udp filter" jump-target=udp protocol=udp
add action=jump chain=prerouting comment="jump to icmpv6 filter" jump-target=icmpv6 protocol=icmpv6
# Accept what's left
add action=passthrough chain=prerouting comment="=========ELSE========="
add action=accept chain=prerouting comment="wan -> accept else" in-interface-list=WAN
add action=accept chain=prerouting comment="lan -> accept else" in-interface-list=LAN
add action=log chain=prerouting comment="log befor drop" log-prefix=raw6_else_drop
add action=drop chain=prerouting comment="drop else"

# Bogon filter
add action=passthrough chain=rfc6890 comment="=========RFC6890========="
add action=accept chain=rfc6890 comment="exceptoion for dad" dst-address=ff02::1:ff00:0/104 icmp-options=135:0 protocol=icmpv6 src-address=::/128
add action=drop chain=rfc6890 comment="drop src bogon" src-address-list=rfc6890
add action=drop chain=rfc6890 comment="drop dst bogon" dst-address-list=rfc6890
add action=drop chain=rfc6890 comment="drop bad src" src-address-list=rfc6890_bad_src
add action=drop chain=rfc6890 comment="drop bad dst" src-address-list=rfc6890_bad_dst
add action=return chain=rfc6890

add action=passthrough chain=prefix comment="=========PREFIX========="
add action=return chain=prefix comment="return src from my_prefix" in-interface-list=LAN src-address-list=my_prefix
add action=return chain=prefix comment="return dst to my prefix" dst-address-list=my_prefix in-interface-list=WAN
add action=return chain=prefix comment="return link-local -> my_prefix" dst-address-list=my_prefix src-address=fe80::/10
add action=return chain=prefix comment="return link-local -> multicast" dst-address-list=local-multicast src-address=fe80::/10
add action=return chain=prefix comment="return link-local -> link-local" dst-address=fe80::/10 src-address=fe80::/10
add action=log chain=prefix comment="log befor drop" log-prefix=raw6_prefix_drop
add action=drop chain=prefix comment="drop else"

# TCP filter
add action=passthrough chain=prerouting comment="=========TCP=========" protocol=tcp
add action=drop chain=tcp comment="tag filter" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
add action=drop chain=tcp comment="flag filter: fin + ack" protocol=tcp tcp-flags=fin,syn
add action=drop chain=tcp comment="flag filter: fin + rst" protocol=tcp tcp-flags=fin,rst
add action=drop chain=tcp comment="flag filter: fin - ack" protocol=tcp tcp-flags=\fin,!ack
add action=drop chain=tcp comment="flag filter: fin + urg" protocol=tcp tcp-flags=fin,urg
add action=drop chain=tcp comment="flag filter: syn + rst" protocol=tcp tcp-flags=syn,rst
add action=drop chain=tcp comment="flag filter: rst + urg" protocol=tcp tcp-flags=rst,urg
add action=drop chain=tcp comment="drop port 0" port=0 protocol=tcp
add action=jump chain=tcp comment="jump to virus" jump-target=tcp-virus
add action=accept chain=tcp comment="accept else"

# UDP filter
add action=passthrough chain=prerouting comment="=========UDP=========" protocol=udp
add action=drop chain=udp comment="drop port 0" port=0 protocol=udp
add action=jump chain=udp comment="jump to virus" jump-target=udp-virus
add action=accept chain=udp comment="accept else"

# IPv6 filter
add action=passthrough chain=prerouting comment="=========ICMPv6========="
add action=log chain=icmpv6 comment="log befor drop hop limit" dst-address=fe80::/10 hop-limit=not-equal:255 log-prefix=raw6_icmpv6_hop_limit protocol=icmpv6
add action=drop chain=icmpv6 comment="drop with hop-limit!=255" dst-address=fe80::/10 hop-limit=not-equal:255 protocol=icmpv6
add action=accept chain=icmpv6 comment="dst unreachable" dst-limit=4,8,dst-address/1m40s icmp-options=1:0-8 protocol=icmpv6
add action=accept chain=icmpv6 comment="packet too big" dst-limit=4,8,dst-address/1m40s icmp-options=2:0 protocol=icmpv6
add action=accept chain=icmpv6 comment="time exceeded" dst-limit=4,8,dst-address/1m40s icmp-options=3:0 protocol=icmpv6
add action=accept chain=icmpv6 comment="parametr problem" dst-limit=4,8,dst-address/1m40s icmp-options=4:0-2 protocol=icmpv6
add action=accept chain=icmpv6 comment="echo request" dst-limit=4,8,dst-address/1m40s icmp-options=128:0 in-interface-list=LAN protocol=icmpv6
add action=accept chain=icmpv6 comment="echo replay" icmp-options=129:0 limit=8,16:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="mldv1 query" dst-address=ff02::1/128 icmp-options=130:0 limit=8,16:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="mldv1 report" icmp-options=131:0 limit=4,8:packet protocol=icmpv6 src-address=fe80::/10
add action=accept chain=icmpv6 comment="mldv1 done all routers" dst-address=ff02::2/128 icmp-options=132:0 limit=8,16:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="mldv1 done solicited-node addresses" dst-address=ff02::1:ff00:0/104 icmp-options=132:0 limit=8,16:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="router solic" hop-limit=equal:255 icmp-options=133:0 limit=8,16:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="router advert" hop-limit=equal:255 icmp-options=134:0 limit=8,16:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="neighbor solic" hop-limit=equal:255 icmp-options=135:0 limit=8,16:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="neighbor advert" hop-limit=equal:255 icmp-options=136:0 limit=8,16:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="inverse ND solic" hop-limit=equal:255 icmp-options=141:0 limit=4,8:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="inverse ND advert" hop-limit=equal:255 icmp-options=142:0 limit=4,8:packet protocol=icmpv6
add action=accept chain=icmpv6 comment="mldv2 report" dst-address=ff02::16/128 icmp-options=143:0 limit=8,16:packet protocol=icmpv6
add action=drop chain=icmpv6 comment="drom mdns befor log" dst-address=ff02::fb/128 icmp-options=132:0 protocol=icmpv6
add action=log chain=icmpv6 comment="log beffor drop" log-prefix=raw6_icmpv6_drop protocol=icmpv6
add action=drop chain=icmpv6 comment="drop else" protocol=icmpv6

# Mostly useless. There is some spontaneous traffic on ports: 65506
add action=drop chain=tcp-virus comment="Drop Firehotcker" dst-port=79 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Blaster Worm" dst-port=135-139 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Blaster Worm" dst-port=445 protocol=tcp
add action=drop chain=tcp-virus comment=________ dst-port=593 protocol=tcp
add action=drop chain=tcp-virus comment=________ dst-port=1024-1030 protocol=tcp
add action=drop chain=tcp-virus comment="Drop MyDoom" dst-port=1080 protocol=tcp
add action=drop chain=tcp-virus comment=________ dst-port=1214 protocol=tcp
add action=drop chain=tcp-virus comment="ndm requester" dst-port=1363protocol=tcp
add action=drop chain=tcp-virus comment="ndm server" dst-port=1364 protocol=tcp
add action=drop chain=tcp-virus comment="screen cast" dst-port=1368 protocol=tcp
add action=drop chain=tcp-virus comment=hromgrafx dst-port=1373 protocol=tcp
add action=drop chain=tcp-virus comment=cichlid dst-port=1377 protocol=tcp
add action=drop chain=tcp-virus comment=Worm dst-port=1433-1434 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Dumaru.Y " dst-port=2283 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Beagle" dst-port=2535 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Beagle.C-K" dst-port=2745 protocol=tcp
add action=drop chain=tcp-virus comment="Bagle Virus " dst-port=2745 protocol=tcp
add action=drop chain=tcp-virus comment="Drop MyDoom" dst-port=3127-3128 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Backdoor OptixPro" dst-port=3410 protocol=tcp
add action=drop chain=tcp-virus comment=Worm dst-port=4444 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Sasser" dst-port=5554 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Beagle.B" dst-port=8866 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Dabber.A-B" dst-port=9898 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Dumaru.Y" dst-port=10000 protocol=tcp
add action=drop chain=tcp-virus comment="Drop MyDoom.B" dst-port=10080 protocol=tcp
add action=drop chain=tcp-virus comment="Drop NetBus" dst-port=12345 protocol=tcp
add action=drop chain=tcp-virus comment="Drop Kuang2" dst-port=17300 protocol=tcp
add action=drop chain=tcp-virus comment="Drop SubSeven" dst-port=27374 protocol=tcp
add action=drop chain=tcp-virus comment="Drop PhatBot, Agobot, Gaobot" dst-port=65506 protocol=tcp
add action=return chain=tcp-virus

# Mostly useless.
add action=drop chain=udp-virus comment="Drop Firehotcker" dst-port=79 protocol=udp
add action=drop chain=udp-virus comment="Drop Messenger Worm" dst-port=135-139 protocol=udp
add action=drop chain=udp-virus comment="Drop Blaster Worm" dst-port=445 protocol=udp
add action=drop chain=udp-virus comment=Worm dst-port=4444 protocol=udp
add action=return chain=udp-virus
