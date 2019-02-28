#!/bin/bash

[ -f "$(dirname $0)/init" ] && . "$(dirname $0)/init"

# default
if [ -z "$REINDEX" ]; then
	REINDEX=120 #minutes
fi
if [ -z "$INOTIFY" ]; then
	INOTIFY=1
fi

#START METHOD FOR INDEXING OF OPENGROK
start_opengrok(){
	# Wait for Tomcat startup.
	date +"%F %T Waiting for tomcat startup..."
	while [ "`curl --silent --write-out '%{response_code}' -o /dev/null 'http://localhost:8080/'`" == "000" ]; do
		sleep 1;
	done
	date +"%F %T Startup finished"

	# Populate the webapp with bare configuration.
    grok_add_info "initial reindex in progress... Stay tuned please !"
	/grok/bin/grok_index.sh --noIndex

	# Perform initial indexing.
	/grok/bin/grok_reindex
	date +"%F %T Initial reindex finished"
    grok_remove_info

	# Continue to index every $REINDEX minutes.
	if [ "$REINDEX" = "0" ]; then
		date +"%F %T Automatic reindexing disabled"
		return
	else
		date +"%F %T Automatic reindexing in $REINDEX minutes..."
	fi
	while true; do
        TIMEOUT=`expr 60 \* $REINDEX`
        if [ "$INOTIFY" = "1" ]; then
          inotifywait -t $TIMEOUT -r -e modify,create,delete,move /grok/src
          ret=$?
          if [ $ret -eq 0 ]; then
            sleep 120
          elif [ $ret -eq 1 ]; then
            sleep $TIMEOUT
          fi
        else
          sleep $TIMEOUT
        fi
        grok_add_info "scheduled reindex in progress..."
		/grok/bin/grok_index
        grok_remove_info
	done
}

#START ALL NECESSARY SERVICES.
start_opengrok &
catalina.sh run
