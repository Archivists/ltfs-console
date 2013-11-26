###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: logger
# Utility logging function.
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
logger() {
	if [ $LOGLEVEL -ge $1 ]; then
		echo `date +%Y-%m-%d_%T`" -> "`echo $@ | sed -e 's/^'$1'//'` >> $MAIN_LOG_FILE
	fi
	if [ $DEBUG == 1 ]; then
		echo $@
	fi
}

