#!/bin/bash
# author: lilong'en(lilongen@163.com)
#

setVersion() {
	echo "Set version..."
	echo $VERSION > VERSION
}

enterBuildWorkspace() {
	rm -rf _TMP_
	mkdir _TMP_
	cd _TMP_
}

leaveBuildWorkspace() {
	cd ..
}

clone() {
	echo "clone ..."
	git clone git@github.com:lilongen/statcode.git ccv
}

preparePackageSource() {
	echo "Prepare package source files..."
	setVersion

	rm -rf ccv/.git
	rm -rf ccv/docs
	
	cp ccv/INSTALL.pl .
	cp ccv/README .
}

generatePackage() {
	echo "Generate package ..."
	gz_file="ccv.tar.gz"
	up_file="ccv-2.0-$VERSION.tar.gz"
	
	declare -a cmds
	cmds=(
		"tar -czvf $gz_file ccv/"
		"tar -czvf $up_file INSTALL.pl README $gz_file"
	)
	
	index=0
	while [ "${cmds[index]}" != "" ]
	do
		${cmds[index]}
		let "index++"
	done
}

uploadPackage() {
	echo "upload package ..."
	up_file="ccv-2.0-$VERSION.tar.gz"
	
	declare -a cmds
	cmds=(
		"rsync -vaP -e ssh $up_file lilongen,ccv@frs.sourceforge.net:/home/frs/project/c/cc/ccv/"
		"rsync -vaP -e ssh $up_file lilongen,statcode@frs.sourceforge.net:/home/frs/project/s/st/statcode/"
		"rsync -vaP -e ssh $up_file lilongen,cvschangeviewer@frs.sourceforge.net:/home/frs/project/c/cv/cvschangeviewer/"
	)
	
	index=0
	while [ "${cmds[index]}" != "" ]
	do
		${cmds[index]}
		let "index++"
	done
}

uploadManual() {
	echo "upload ccv web manual...."
	python upload.project.web.py
}

main() {
	echo "Start a new build..."
	
	enterBuildWorkspace
	clone
	preparePackageSource
	generatePackage
	if [ $1 -gt 0 ]
	then
		echo 
		uploadPackage
	fi	
	leaveBuildWorkspace
	

	if [ $1 -gt 1 ]
	then
		uploadManual
	fi
		
	echo "done!"
}

VERSION="`date +%02m%02d%04Y`"

main $#
