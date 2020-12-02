#!/bin/bash
#
#
# In case we have an ENTRYPOINT?CMD defined, use that one instead
if [ -n "$ENTRYPOINT" ]
then
    # Deplpoy the probe.
    if [ "$PHP_DEPLOY" = "true" ]
    then
	if [ -x ${PHP_PROBE_DIR:-/opt/apmia}/php-probe.sh ]
	then
	    echo " * Implanting PHP probe"
	    # Execute php-probe.sh
	    /bin/sh ${PHP_PROBE_DIR:-/opt/apmia}/php-probe.sh
	else
	    echo "*** FATAL: PHP deployment enabled, but probe-installer not found. Exiting!"
	fi
    fi
    
    if [ ! -f $PHP_LOGDIR ]
    then
	mkdir -p $PHP_LOGDIR
        # If you want to have logs, identify the user the Web-Server
	# is running as, and apply the chmod accordingly.
	## chown www-data.www-data $PHP_LOGDIR
	chmod 775 $PHP_LOGDIR
    fi
    
    echo " * Handing over to real ENTRYPOINT: $ENTRYPOINT"
    # Execute real Entrypoint. Make sure it hooks itself to the shell.
    $ENTRYPOINT
else
    # Exit with a true status
    /bin/true
fi
