#!/usr/bin/python
# author: lilong'en(lilongen@163.com)
#

import os
import cgi 
import cPickle

class CcvTimes:
	_FILE_NAME = ".dts/counter"
	
	_DEFAULT_TIMES = {
		"GET_OVERALL"	: 0,
		"GENERATE" 		: 0,
		"log"			: 0,
		"diff"			: 0,
		"file" 			: 0	
	}
	
	def __init__(self, type, mode):
		self.type = type
		self.mode = mode

		
	def increase(self):
		ret = -1
		rFile = None
		wFile = None

		try:
			times = self._DEFAULT_TIMES
			if os.path.exists(self._FILE_NAME):
				rFile = open(self._FILE_NAME, "r")
				times = cPickle.load(rFile)

			wFile = open(self._FILE_NAME, 'w')					
			times[self.type] = times[self.type] + 1
			if self.type == "GENERATE":
				times[self.mode] = times[self.mode] + 1
			cPickle.dump(times, wFile)
			
			ret = times[self.type]
		except Exception:
			if not rFile is None:
				rFile.close()
			if not wFile is None:
				wFile.close()
		
			ret = "ERROR_IO_FILE_OPERATE"


		return ret
		
#class end		

def main():
	print "Content-type: application/json\n\n"
	form = cgi.FieldStorage()
	ret = "INLEGAL_INVOKE"
	
	if not (form.has_key("type") and form.has_key("mode")):
		print "{ret: %s}" % (ret)
		return
	
	type = form["type"].value
	mode = form["mode"].value
	#type = "GET_OVERALL"
	#mode = ""
	
	if type == "GET_OVERALL" or type == "GENERATE":
		ccvTime = CcvTimes(type, mode)
		ret = ccvTime.increase()
	else:
		ret = "ILLEGAL_COMMNAD"
	
	print "{ret: %s}" % (ret)


main()
