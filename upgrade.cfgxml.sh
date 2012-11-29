#!/bin/bash
# author: lilong'en(lilongen@163.com)
# date:   11/02/2010
#

function upgradeAll() {
    echo 
    echo "Start CCV module config files upgrade ..."
    echo

    cd config
    if [ ! -e _cfgsbk ]
    then
    	mkdir _cfgsbk
    fi
    
    for i in *.xml
    do
        bkFile=_cfgsbk/$i.ubk
		if [ ! -e $bkFile ]
		then
		    echo "backup $i ... "
            cp -f $i $bkFile
		fi        
        
        echo "upgrade $i ..."
        upgrade $i
    done
    cd ..
    
    echo "CCV module config files upgrade: done!"
    echo 
}

function upgrade() {
    cfgFile=$1

    sed -i -r 's/<(\/)?cvs_module>/<\1module>/g' $cfgFile
    
    sed -i -r 's/<(\/)?cvs_access_mode>/<\1access_mode>/g' $cfgFile
    sed -i -r 's/<(\/)?cvs_account_id>/<\1account_id>/g' $cfgFile
    sed -i -r 's/<(\/)?cvs_account_pw>/<\1account_pw>/g' $cfgFile
    
    sed -i -r 's/<(\/)?viewvc_cvsroot>/<\1viewvc_repository>/g' $cfgFile
    
    #replacce global id/pwd/mode form account_id/account_pw/account_mode to prefixed by cvs
    sed -i -r 's/^<account_id>(.*)<\/account_id>/<cvs_account_id>\1<\/cvs_account_id>/g' $cfgFile
    sed -i -r 's/^<account_pw>(.*)<\/account_pw>/<cvs_account_pw>\1<\/cvs_account_pw>/g' $cfgFile
    sed -i -r 's/^<access_mode>(.*)<\/access_mode>/<cvs_account_mode>\1<\/cvs_account_mode>/g' $cfgFile
}

if [ $# -gt 0 ]
then
	cfgFile=$1
	echo 
	if [ -e $cfgFile ]
	then
		echo "upgrade $cfgFile ..."
		upgrade $cfgFile
		echo "done!"
	else 
		echo "Eror: $cfgFile not exist!"
	fi
	echo 
else 
	upgradeAll
fi