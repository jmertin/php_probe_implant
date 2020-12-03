#!/bin/sh
#
#
# In case we have an ENTRYPOINT?CMD defined, use that one instead
if [ -n "$ENTRYPOINT" ]
then
    # Deplpoy the probe.
    if [ "$PHP_DEPLOY" = "true" ]
    then
        if [ -x /opt/apmia/php-probe.sh ]
        then
            echo " * Implanting PHP probe"
            # Execute php-probe.sh
            /bin/sh /opt/apmia/php-probe.sh
        else
            echo "*** FATAL: PHP deployment enabled, but probe-installer not found. Exiting!"
        fi
    fi
    
    if [ ! -f $PHP_LOGDIR ]
    then
        mkdir -p $PHP_LOGDIR
        # If you want to have logs, identify the user the Web-Server
        # is running as, and apply the chmod accordingly.
        chown ${PHP_WWWMODE}.${PHP_WWWMODE} $PHP_LOGDIR
        chmod 775 $PHP_LOGDIR
    fi
    
    echo " * Handing over to real ENTRYPOINT: $ENTRYPOINT"
    # Execute real Entrypoint. Make sure it hooks itself to the shell.
    exec $ENTRYPOINT
else
    echo "*** php-probe implant entry point"
    echo "*** Current directory: `pwd`"
    echo "Copying over all files from /data/apmia directory to /opt/apmia"
    cp -ar /opt/data/apmia /opt/
    cp -ar /opt/data/*.sh /opt/apmia/ 
    chmod 755 /opt/apmia /opt/apmia/*.sh
    # Exit with a true status
    /bin/true
fi
