#!/bin/bash
# author: lilong'en(lilongen@163.com)
# date: 4/13/2010
#

CcvId="ccv"
UpdatedAvailable=0
UpdateUsingLocalPackage=0
BuildPackageName=""

if [ $# -gt 0 ]
then
	UpdatedAvailable=1
	BuildPackageName=$1
	UpdateUsingLocalPackage=1
fi

createUpdateWorkspace() {
	if [ ! -d .update ]
	then
		mkdir .update
	else 
		rm -rf .update/*	
	fi
}

checkVersion() {
	echo 
	echo "Check whether updated build is available..."
	echo 
	
	localVer=""
	if [ -e VERSION ] 
	then
		localVer=`cat VERSION`
	fi
	
	echo "Current build: $localVer"
	
	echo "Check latest build..."
	wget -P ".update" "http://ccv.sourceforge.net/VERSION"
	remoteVer=`cat .update/VERSION`
	
	echo "Latest build: $remoteVer"
	echo 
	
	if [ "$localVer" = ""  ] || [[ "$localVer" < "$remoteVer" ]]
	then
		UpdatedAvailable=1
	fi
}

download() {
	buildNO=${remoteVer##*.}
	BuildPackageName="$CcvId-2.0-${buildNO}.tar.gz"
	
	latest="http://sourceforge.net/projects/ccv/files/$BuildPackageName/download"
	
	echo "Download CCV latest build..."
	echo 
	wget -P ".update" $latest
}

update() {
	echo 
	echo "upgrading..."
	echo
	
	cd .update
	
	packageName="$CcvId.tar.gz"
	tar -xzf $BuildPackageName
	
	echo "Update files..."
	echo 
	tar -xzf $packageName
	rm -rf ccv/config/config.xml
	rm -rf ccv/config/cvs.accounts
	
	rm -rf $packageName
	tar -czf $packageName ccv/
	rm -rf ccv/
	tar -xzf $packageName -C ../../
	
	echo "Update files: finished"
	cd ..
	chmod 755 *
	chmod 777 config/
	chmod 777 config/CFG_PWD 1>/dev/null 2>/dev/null
	chmod 777 operate/
	chmod 777 web/reports/
	
	echo 
	echo "Upgrade: done!"
	echo "Now your CCV version is: $remoteVer";
	echo
}


main() {
	createUpdateWorkspace
	
	if [ $UpdateUsingLocalPackage -eq 0 ]
	then
		checkVersion
	fi
	
	
	if [ $UpdatedAvailable -eq 1 ]
	then
		if [ $UpdateUsingLocalPackage -eq 0 ]
		then
			download
		else 
			cp -f $BuildPackageName .update/ 1>/dev/null 2>/dev/null
		fi
		
		if [ ! -f ".update/$BuildPackageName" ]
		then
			echo "$BuildPackageName not exist!"
		else
			update	
		fi
	else
		echo 
		echo "Your CCV already is the latest package!"
		echo 
	fi
}

main