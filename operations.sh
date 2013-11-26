#!/bin/bash

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: format_tape
# Format an LTFS LTO tape. Note: -f force is not used, and so an tape
# that has already been formatted will not be overwritten.
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
format_tape() {
  "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected format tape." 10 30
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: list_tape
# List the contents of a mounted tape (directories and files).
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
list_tape() {
  exec 3>&1
  SELECTED=`$DIALOG --title "Please choose a file" "$@" --backtitle "$backtitle" --fselect $MOUNT_POINT/ 15 60 2>&1 1>&3`
  retval=$?
  exec 3>&-
  
  case $retval in
  $DIALOG_CANCEL)  
    ;;
  $DIALOG_OK)
    "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected $SELECTED." 10 30
    ;;
  esac
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: copy_to_tape
# Perform a file copy using rsync, from the tape staging folder, to 
# the tape drive.
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
copy_to_tape() {
  logger 4 "Starting copy to tape from $TEST_SOURCE to $MOUNT_POINT"
  
  ($RSYNC_CMD $TEST_SOURCE $MOUNT_POINT) | "$DIALOG" --title " PROGRESS " \
        --progressbox "Copy progress..." 20 70

  logger 4 "Copy from $TEST_SOURCE to $MOUNT_POINT complete."
  
  "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "Copy complete." 8 30
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: restore_tape
# Completely restore the entire contents of a tape to the tape staging
# folder.
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
restore_tape() {
   "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected restore tape." 10 30
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: restore_items
# Restore selected directories or files from the tape. Restored items
# will be placed in the 'Requests' area.
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
restore_items() {
  "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected restore archive items." 10 30
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: eject_tape
# Eject a tape.
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
eject_tape() {
  "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected eject tape." 10 30
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: get_tape_status
# Get tape status.
# https://github.com/prestoprime/LTFSArchiver
# https://www.prestocentre.org/library/tools/ltfs-archiver
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
get_tape_status() {
  COUNT=0
  while [ $COUNT -le 5 ]; do
    TAPESTATUS=( `$MT_CMD -f $1 status |grep -E "General|Density" | sed -e 's/.*code//' -e 's/(no.*//' -e 's/ (de.*//'| sed '/General/s/[^0-9]*//g' |  tr -d ' ' | tr '\n' ' '` )
    logger 4 "TAPESTATUS returned value: $TAPESTATUS"
    [ $DEBUG == 1 ] && $MT_CMD -f $1 status 
    case ${TAPESTATUS[1]} in
      "41010000")
        # ok
        TAPE_STATUS_RC=0
        TAPE_STATUS_MSG="ready"
        COUNT=5
        # se OK, leggo density code
        DENSITY_IDX=0
        if [ -z ${TAPESTATUS[0]} ]; then
          unset TAPE_STATUS_TYPE
        else
          while [ $DENSITY_IDX -lt ${#LTO_ALLOWED_CODES[@]} ]; do
            if [ ${TAPESTATUS[0]} == ${LTO_ALLOWED_CODES[$DENSITY_IDX]} ]; then
              TAPE_STATUS_TYPE=${LTO_ALLOWED_TYPES[$DENSITY_IDX]}
              TAPE_WATERMARK=${LTO_WATERMARK[$DENSITY_IDX]}
              DENSITY_IDX=${#LTO_ALLOWED_CODES[@]}
            fi
          done
        fi
        if [ -z $TAPE_STATUS_TYPE ]; then
          TAPE_STATUS_RC=32
          TAPE_STATUS_MSG=" unsupported type (density code: ${TAPESTATUS[0]})"
        fi
        # test per simulare errore
        #TAPE_STATUS_RC=32
        #TAPE_STATUS_MSG="fake error"
      ;;
      "10000")
        TAPE_STATUS_RC=1
        TAPE_STATUS_MSG=" positiong"
      ;;
      "45010000")
        TAPE_STATUS_RC=2
        TAPE_STATUS_MSG=" protected"
      ;;
      "50000")
        TAPE_STATUS_RC=4
        TAPE_STATUS_MSG=" missing"
      ;;
      "4010000")
        TAPE_STATUS_RC=8
        TAPE_STATUS_MSG=" protected - ejecting"
      ;;
      *)
        TAPE_STATUS_RC=16
        TAPE_STATUS_MSG=" unknown status: ${TAPESTATUS[1]}"
      ;;
    esac
    sleep 1
    let COUNT+=1
  done
  echo $TAPE_STATUS_MSG
}
