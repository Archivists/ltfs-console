#!/bin/bash

format_tape() {
  "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected format tape." 10 30
}

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

copy_to_tape() {
  logger 4 "Starting copy to tape from $TEST_SOURCE to $MOUNT_POINT"
  ($RSYNC_CMD $TEST_SOURCE $MOUNT_POINT) | "$DIALOG" --title " PROGRESS " \
        --progressbox "Copy progress..." 20 70
}

restore_tape() {
   "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected restore tape." 10 30
}

restore_items() {
  "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected restore archive items." 10 30
}

eject_tape() {
  "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected eject tape." 10 30
      ;;
}

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
