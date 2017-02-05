#!/bin/bash
# Simple backup with rsync
# local-mode, tossh-mode, fromssh-mode

SOURCES="/storage/900B-8135/Pictures/ /storage/900B-8135/DCIM/ /storage/emulated/0/DCIM/ /storage/emulated/0/Pictures/  "
TARGET="/home/jens/Pictures/"

# edit or comment with "#"
#LISTPACKAGES=listdebianpackages        # local-mode and tossh-mode
MONTHROTATE=monthrotate                 # use DD instead of YYMMDD

RSYNCCONF=( --exclude=Music --exclude=Android --exclude=LOST.DIR --exclude=)

MAILREC="info.priority@high5.alioth.uberspace.de"

SSHUSER="root"
FROMSSH="canary"
#TOSSH="tossh-server"
SSHPORT=22

##

 for SOURCE in "${SOURCES[@]}"
    do 	rsync -avR --recursive --backup --backup-dir=backup --suffix=$RANDOM --remove-source-files --checksum "$SSHUSER"@"$FROMSSH":"$SOURCE"  "$TARGET"
    done
  
  
