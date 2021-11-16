#!/bin/sh

if [ -f ./03_gitcredentials ]
then
    source ./03_gitcredentials
fi

# Get installer data
if [ -f ./00_infosource.cfg ]
then
    source ./00_infosource.cfg
    source ./.build
   
fi

if [ -f build_image.cfg ]
then
    source ./build_image.cfg
else
    echo
    echo "*** ERROR: Missing build_image.cfg configuration file (normal on first run)!"
    echo "============================================================================================================="
    echo > build_image.cfg
    echo "# Go to the Agent Download Section, select to download the PHP Agent and open the \"Command line Download\"." | tee -a build_image.cfg
    echo "# and put it all in the below link - incl. the security Token. Exclude the wget command!" | tee -a build_image.cfg
    echo "PHP_FILE='<Insert here the download CLI URL for the PHP APMIA Agent>'" | tee -a build_image.cfg
    exit 1
fi

#echo -n "Removing dangling docker images"
#docker rmi $(docker images -f "dangling=true" -q)

echo
echo -n ">>> Download latest PHP Agent archive [y/n]?: "
read DownLoad

# Clean up build env.
rm -rf apmia

if [ "$DownLoad" = "y" ]
then
    # Removing all instance of files.
    rm -f PHP-apmia-*.tar
    
    ## Download repository
    wget --no-check-certificate --content-disposition $PHP_FILE
    if [ $? == 0 ]
    then
	tar xf PHP-apmia-*.tar apmia/manifest.txt apmia/probe apmia/installer.sh
	PHPMONITVER=`grep php-monitor apmia/manifest.txt | cut -d ':' -f 2`
	TMP=`ls PHP-apmia-*.tar`
    else
	echo "*** FATAL: PHP APMIA Agent download failed. Exiting."
	exit 1
    fi
else
    tar xf PHP-apmia-*.tar apmia/manifest.txt apmia/probe apmia/installer.sh
    PHPMONITVER=`grep php-monitor apmia/manifest.txt | cut -d ':' -f 2`
    TMP=`ls PHP-apmia-*.tar`
fi

FILENAME="PHP-Probe-${PHPMONITVER}.tar.gz"
tar zcf $FILENAME ./apmia

echo ">>> Found PHP Monitor $PHPMONITVER!"
cat Dockerfile.tpl | sed -e '/%%EXTCOPY%%/d' > Dockerfile



echo
echo -n ">>> Build PHP probe volume image [y/n]?: "
read Build

if [ "$Build" = "y" ]
   then

       echo
       echo "*** If you want to apply OS Update, don't use the cache."
       echo -n ">>> Use cache for build [y/n]?: "
       read Cache

       PREFIX=`hostname -s`

       if [ "$Cache" == "y" ]
       then
           ### Build PHP Probe volume
           docker build -t bcp/$FileBase --build-arg PHP_EXTENSION_VER=$PHPMONITVER --build-arg PHP_EXTENSION_FILE=$FILENAME .
       else
           ### Build PHP Probe volume
           docker build --no-cache -t bcp/$FileBase --build-arg PHP_EXTENSION_VER=$PHPMONITVER --build-arg PHP_EXTENSION_FILE=$FILENAME .
       fi
       # Tag the built image
       echo "*** Tagging image to bcp/$FileBase:$PHPMONITVER" 
       docker tag bcp/$FileBase:latest bcp/$FileBase:$PHPMONITVER

       if [ -n DOCKER_REGISTRY ]
       then
	   echo "*** Tagging image to ${DOCKER_REGISTRY}/bcp/$FileBase:$PHPMONITVER" 
	   docker tag bcp/$FileBase:latest ${DOCKER_REGISTRY}/bcp/$FileBase:$PHPMONITVER
	   echo "*** Pushing image to registry" 
	   docker push ${DOCKER_REGISTRY}/bcp/$FileBase:$PHPMONITVER
       fi
fi
