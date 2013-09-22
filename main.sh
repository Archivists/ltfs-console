#!/bin/bash
# $Id: LTFSConsole,v 0.1 2013/09/22 10:37:01 tony Exp $

. ./app.conf
. ./logger.sh
. ./setup-vars
. ./setup-tempfile
. ./operations.sh

MAIN_LOG_FILE=$LOGDIR/ltfsconsole.`date +%Y%m%d`.log

DIALOG_ERROR=254
export DIALOG_ERROR

backtitle="LTFS Console Tape Manager v0.1"
logger 4 "Starting up."

returncode=0
while test $returncode != 1 && test $returncode != 250
do
exec 3>&1

value=`$DIALOG --backtitle "$backtitle" "$@" \
  --clear \
  --title " MAIN MENU " "$@" \
        --menu "Welcome to the main menu for LTFS Tape Manager. \n\
Choose a menu item from below, or press cancel to quit. \n\n\
          Menu Option:" 20 52 6 \
        "Format Tape"  "Label and format a tape." \
        "List Tape"  "List contents of tape." \
        "Copy to Tape" "Copy staging folder to tape." \
        "Restore Tape" "Restore a complete tape." \
        "Restore Items" "Restore archive items." \
        "Status" "Show tape drive status." \
        "Eject"  "Eject tape." \
2>&1 1>&3`

returncode=$?
exec 3>&-

operation=`echo "$value" | sed 's/\ //g'`

  case $returncode in
  $DIALOG_CANCEL)
    "$DIALOG" \
    --clear \
    --backtitle "$backtitle" \
    --yesno "Really quit?" 10 30
    case $? in
    $DIALOG_OK)
      break
      ;;
    $DIALOG_CANCEL)
      returncode=99
      ;;
    esac
    ;;
  $DIALOG_OK)
    case $operation in
    FormatTape)
      format_tape
      ;;
    ListTape)
      list_tape
      ;;
    CopytoTape)
      copy_to_tape
      ;;
    RestoreTape)
     restore_tape
      ;;
    RestoreItems)
      restore_items
      ;;
    Status)
      TAPESTATUS=`get_tape_status $DEVICE`
      "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "$TAPESTATUS" 15 40
      ;;
    Eject)
      eject_tape
      ;;
    *)
      "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --msgbox "You selected an unknown option." 10 30
      ;;
    esac
    ;;
  $DIALOG_ERROR)
    echo "ERROR!$value"
    exit
    ;;
  $DIALOG_ESC)
    returncode=99
    ;;
  *)
    echo "Return code was $returncode"
    exit
    ;;
  esac
done