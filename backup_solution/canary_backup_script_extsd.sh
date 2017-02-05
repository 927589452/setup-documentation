#!/bin/bash
# Simple backup with rsync
# local-mode, tossh-mode, fromssh-mode

SOURCES="/storage/900B-8135 "
TARGET="/home/jens/canary/backup_sd/"

# edit or comment with "#"
#LISTPACKAGES=listdebianpackages        # local-mode and tossh-mode
MONTHROTATE=monthrotate                 # use DD instead of YYMMDD

RSYNCCONF=(--backup --backup-dir=backup --archive --recursive --suffix=$RANDOM --exclude=Downloads --exclude=DCIM --exclude=Pictures)
#MOUNTPOINT="/media/daten"               # check local mountpoint
MAILREC="info.priority@high5.alioth.uberspace.de"

SSHUSER="root"
FROMSSH="canary"
#TOSSH="tossh-server"
SSHPORT=22

### do not edit ###
MOUNT="/bin/mount"; FGREP="/bin/fgrep"; SSH="/usr/bin/ssh"
LN="/bin/ln"; ECHO="/bin/echo"; DATE="/bin/date"; RM="/bin/rm"
DPKG="/usr/bin/dpkg"; AWK="/usr/bin/awk"; MAIL="/usr/bin/mail"
CUT="/usr/bin/cut"; TR="/usr/bin/tr"; RSYNC="/usr/bin/rsync"
LAST="last"; INC="--link-dest=$TARGET/$LAST"

LOG=$0.log
$DATE > $LOG

if [ "${TARGET:${#TARGET}-1:1}" != "/" ]; then
  TARGET=$TARGET/
fi



  for SOURCE in "${SOURCES[@]}"
    do
      if [ "$S" ] && [ "$FROMSSH" ] && [ -z "$TOSSH" ]; then
        $ECHO "$RSYNC -e \"$S\" -avR \"$FROMSSH:$SOURCE\" ${RSYNCCONF[@]} $TARGET$TODAY $INC"  >> $LOG 
        $RSYNC -e "$S" -avR "$FROMSSH:\"$SOURCE\"" "${RSYNCCONF[@]}" "$TARGET"$TODAY $INC >> $LOG 2>&1 
        if [ $? -ne 0 ]; then
          ERROR=1
        fi 
      fi 
      if [ "$S" ]  && [ "$TOSSH" ] && [ -z "$FROMSSH" ]; then
        $ECHO "$RSYNC -e \"$S\" -avR \"$SOURCE\" ${RSYNCCONF[@]} \"$TOSSH:$TARGET$TODAY\" $INC " >> $LOG
        $RSYNC -e "$S" -avR "$SOURCE" "${RSYNCCONF[@]}" "$TOSSH:\"$TARGET\"$TODAY" $INC >> $LOG 2>&1 
        if [ $? -ne 0 ]; then
          ERROR=1
        fi 
      fi
      if [ -z "$S" ]; then
        $ECHO "$RSYNC -avR \"$SOURCE\" ${RSYNCCONF[@]} $TARGET$TODAY $INC"  >> $LOG 
        $RSYNC -avR "$SOURCE" "${RSYNCCONF[@]}" "$TARGET"$TODAY $INC  >> $LOG 2>&1 
        if [ $? -ne 0 ]; then
          ERROR=1
        fi 
      fi
  done

  if [ "$S" ] && [ "$TOSSH" ] && [ -z "$FROMSSH" ]; then
    $ECHO "$SSH -p $SSHPORT -l $SSHUSER $TOSSH $LN -nsf $TARGET$TODAY $TARGET$LAST" >> $LOG  
    $SSH -p $SSHPORT -l $SSHUSER $TOSSH "$LN -nsf \"$TARGET\"$TODAY \"$TARGET\"$LAST" >> $LOG 2>&1
    if [ $? -ne 0 ]; then
      ERROR=1
    fi 
  fi 
  if ( [ "$S" ] && [ "$FROMSSH" ] && [ -z "$TOSSH" ] ) || ( [ -z "$S" ] );  then
    $ECHO "$LN -nsf $TARGET$TODAY $TARGET$LAST" >> $LOG
    $LN -nsf "$TARGET"$TODAY "$TARGET"$LAST  >> $LOG 2>&1 
    if [ $? -ne 0 ]; then
      ERROR=1
    fi 
  fi
$DATE >> $LOG
if [ -n "$MAILREC" ]; then
  if [ $ERROR ];then
    $MAIL -s "Error Backup $LOG" $MAILREC < $LOG
  else
    $MAIL -s "Backup $LOG" $MAILREC < $LOG
  fi
fi
