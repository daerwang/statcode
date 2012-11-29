#!/bin/bash
# author: lilong'en(lilongen@163.com)
# date: 10/09/2008
#

ERROR=0
HAS_DIALOG=1

FILES_MODIFIED="FILES.CHG"
TITLE="Change IP"
LB_HTTPD="Specify apache httpd.conf, press enter to skip this if no apache\nIf there are multi apache, use semicolon(;) as the separator\nExample: /usr/local/apache2/conf/httpd.conf"
LB_WEBLOGIC_DOMAIN="Input weblogic domain path, press enter to skip this if no weblogic domain\nIf there are multi domain, use semicolon(;) as the separator\nExample: /www/domains/245.domain"
MSG_HTTPD_NOT_EXIST="\nnot exist!"
MSG_DOMAIN_PATH_NOT_EXIST="\nnot exist or it is not a directory!"
IP_NET_SEGMENT="10.224.118.."
NEW_IP_NET_SEGMENT="10.224.118."

httpd_files=""
weblogic_domain_paths=""

get_params() {
	if dialog --clear --title "$TITLE" --inputbox "$LB_HTTPD" 12 70 2>O
	then
		sed -i -r 's/\s*$//' O
		sed -i -r 's/^\s*//' O
		httpd_files=`cat O`
	fi
	
	if dialog --clear --title "$TITLE" --inputbox "$LB_WEBLOGIC_DOMAIN" 12 70 2>O
	then
		sed -i -r 's/\s*$//' O
		sed -i -r 's/^\s*//' O
		weblogic_domain_paths=`cat O`
	fi
	
	rm -rf O
}

get_params_txt() {
	echo "Specify apache httpd.conf, press enter to skip this if no apache"
	echo "If there are multi apache, use semicolon(;) as the separator"
	echo "Example: /usr/local/apache2/conf/httpd.conf"
	read httpd_files
	
	echo ""
	echo "Input weblogic domain path, press enter to skip this if no weblogic domain"
	echo "If there are multi domain, use semicolon(;) as the separator"
	echo "Example: /www/domains/245.domain"
	read weblogic_domain_paths
}


split_params() {
	if [ "$httpd_files" != "" ]; then
		oldifs=$IFS;IFS=';';arr_https=($(echo "$httpd_files"));IFS=$oldifs
		arr_https_cnt=${#arr_https[*]}
		arr_https_cnt=$(($arr_https_cnt - 1))
	
		while [ $arr_https_cnt -ge 0 ]
		do
			if [ ! -e ${arr_https[$arr_https_cnt]} ]
			then
				if [ $HAS_DIALOG -eq 1 ]
				then
					dialog --clear --title "$TITLE" --msgbox "Error:\n${arr_https[$arr_https_cnt]} $MSG_HTTPD_NOT_EXIST" 8 70
				else 
					echo "ERROR"
					echo ${arr_https[$arr_https_cnt]} $MSG_HTTPD_NOT_EXIST
				fi
				ERROR=1
				return
			fi

			echo ${arr_https[$arr_https_cnt]} >> $FILES_MODIFIED
			arr_https_cnt=$(($arr_https_cnt - 1))
		done
	fi
	
	if [ "$weblogic_domain_paths" != "" ]; then
		oldifs=$IFS;IFS=';';arr_weblogics=($(echo "$weblogic_domain_paths"));IFS=$oldifs
		arr_weblogics_cnt=${#arr_weblogics[*]}	
		arr_weblogics_cnt=$(($arr_weblogics_cnt - 1))
		
		while [ $arr_weblogics_cnt -ge 0 ]
		do
			if [ ! -d ${arr_weblogics[$arr_weblogics_cnt]} ]
			then
				if [ $HAS_DIALOG -eq 1 ]
				then
					dialog --clear --title "$TITLE" --msgbox "Error:\n${arr_weblogics[$arr_weblogics_cnt]} $MSG_DOMAIN_PATH_NOT_EXIST" 8 70
				else 
					echo "ERROR"
					echo ${arr_weblogics[$arr_weblogics_cnt]} $MSG_DOMAIN_PATH_NOT_EXIST
				fi				
				
				ERROR=1
				return
			fi
			
			grep -r -l "$IP_NET_SEGMENT" ${arr_weblogics[$arr_weblogics_cnt]}/*.sh ${arr_weblogics[$arr_weblogics_cnt]}/*/*.sh ${arr_weblogics[$arr_weblogics_cnt]}/*.xml ${arr_weblogics[$arr_weblogics_cnt]}/*/*.xml 2>/dev/null >> $FILES_MODIFIED
			arr_weblogics_cnt=$(($arr_weblogics_cnt - 1))
		done
	fi
}

change_ip() {
	if [ -f $FILES_MODIFIED ] 
	then
		sed -i 's/'$IP_NET_SEGMENT'/'$NEW_IP_NET_SEGMENT'/g' `cat $FILES_MODIFIED`
	fi
}

main() {
	whick_dialog=`which dialog 2>/dev/null`
	#echo $HAS_DIALOG
	if [ "$whick_dialog" = "" ]
	then
		HAS_DIALOG=0 
	fi
	
	#echo $HAS_DIALOG
	rm -rf _TMP_
	rm -rf $FILES_MODIFIED
	rm -rf undo.ip.change.tar
	mkdir _TMP_
	cd _TMP_
	
	if [ $HAS_DIALOG -eq 1 ]
	then
		get_params
	else
		get_params_txt
	fi
	
	if [ $ERROR -ne 0 ]
	then
		cd ..
		return 
	fi
	
	split_params
	if [ $ERROR -ne 0 ]
	then
		cd ..
		return 
	fi	
	
	grep -r -l "$IP_NET_SEGMENT" /etc/sysconfig/networking /etc/sysconfig/network-scripts >> $FILES_MODIFIED
	sed -i -r 's/\/{2,}/\//g' $FILES_MODIFIED
	
	files_size="`du -sh $FILES_MODIFIED | gawk '{print $1}'`"
	
	if [ "$files_size" = "0" ] 
	then
		if [ $HAS_DIALOG -eq 1 ]
		then
			dialog --clear --title "$TITLE" --msgbox "There is no file which include subnet IP: $IP_NET_SEGMENT!" 12 70
		else 
			echo "There is no file which include subnet IP: $IP_NET_SEGMENT!"
		fi		
		
		cd ..
		return
	fi
	
	LINE_SYM="---------------------------------------"
	if [ $HAS_DIALOG -eq 1 ]
	then
		if dialog --clear --title "$TITLE" --yesno "Following files need to be changed:\n$LINE_SYM\n`cat $FILES_MODIFIED`\n$LINE_SYM\n\nChoose YES to change IP, Choose NO to exit without change" 35 70
		then
			tar -cvf undo.ip.change.tar `cat $FILES_MODIFIED`
			change_ip
			dialog --clear --title "$TITLE" --msgbox "IP change: done!" 12 70
			
			mv $FILES_MODIFIED ../
			mv undo.ip.change.tar ../		
		fi		
	else 
		echo "Following files need to be changed:"
		echo "$LINE_SYM"
		cat $FILES_MODIFIED
		echo "$LINE_SYM"
		echo "Input YES to change IP, Input NO to exit without change"
		read CHG
		if [ "$CHG" = "YES" ]
		then
			tar -cvf undo.ip.change.tar `cat $FILES_MODIFIED`
			change_ip
			echo "IP change: done!"
			
			mv $FILES_MODIFIED ../
			mv undo.ip.change.tar ../			
		fi
	fi			

	cd ..
	rm -rf _TMP_
}

main
	
		
