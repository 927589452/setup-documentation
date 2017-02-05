#!/bin/sh
#script to generate everything needed on the node

read 'muninin remote port eg 10001 
	choose a different for each node! ' MPORT
print "add
[node.example.com]
 address 127.0.0.1
 port $MPORT 
 use_node_name yes

to your munin.conf
" 
print "let this run as a cron job" 

echo "#!/bin/sh


#this tunnel forwards any data from $MUNINREMOTEPORT 
#to the node starting the ssh tunnel (localhost) 
#on port 4949 (the munin port) 
#there needs to  be a tunnel running on $MUNINSERVER 
#ssh -R $BRIDGEPORT:localhost:22 $BRIDGE_MUNIN_USER@$BRIDGEHOST running on the 
#BRIDGE_MUNIN_USER is a local user on the bridge host
#NODE --> 	SSH --> 	BRIDGE 
#				BRIDGE -->	ssh -->	SERVER
#NODE	==============================================>	SERVER
#
MUNIN_TUNNEL_USER=tunnel #is a local user on the munin server
BRIDGEPORT= 12345 #arbitrary port on bridgehost, fix for all nodes
BRIDGEHOST=bridgehost-domain #remote@munin.example.com
MUNINREMOTEPORT=$MPORT
#
if [ \"`ps -eaf | grep ssh | grep nNgf | grep 4949 | grep $MUNINREMOTEPORT | grep -v grep`\" ] ; then
 echo "tunnel is up"
else
 echo \"SSH tunnel NOT alive ... Restarting ...\"
 /usr/bin/ssh -nNgf -R \$MUNINREMOTEPORT:localhost:4949 -i /path/to/key -p \$BRIDGEPORT \$MUNIN_TUNNEL_USER@$BRIDGEHOST
 logger -p daemon.notice \"SSH tunnel NOT alive ... Restarting ...\"
fi" > munin_tunnel.sh

