#!/usr/bin/python
# author: lilong'en(lilongen@163.com)
#

import os
import sys
import shutil

if not os.path.exists("_TMP_"):
	print "Need build-launch first!!"
	print ""
	sys.exit(0)


os.chdir("_TMP_")
if os.path.exists("ccv.manual"): 
	shutil.rmtree("ccv.manual")

os.mkdir("ccv.manual")
shutil.copy("ccv/VERSION", "ccv.manual/")
shutil.copy("ccv/web/manual.html", "ccv.manual/")
shutil.copy("ccv/web/design.html", "ccv.manual/")
shutil.copytree("ccv/web/img/manual/", "ccv.manual/img/manual/")

os.system("rsync -avP -e ssh ccv.manual/* lilongen,ccv@web.sourceforge.net:/home/project-web/ccv/htdocs/")

os.system("chmod 755 ccv/counter.py")
os.system("rsync -avP -e ssh ccv/counter.py lilongen,ccv@web.sourceforge.net:/home/project-web/ccv/cgi-bin/")
