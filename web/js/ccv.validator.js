ccv.validator = {
	vdrFormator: function(msg) {
		if (typeof msg == "string") {
			return "" + msg;
		} else {
			return "";	
		}
	},
	
	vdrXmlFileName: function(val) {
		if (!ccv.util.isXmlFileNameAvailable(val)) {
			return ccv.validator.vdrFormator("File name already used");
		}
		if (/[ ]/.test(val)) {
			return ccv.validator.vdrFormator("File name illegal");
		}
		if (!/\.[a-z]+/i.test(val)) {
			return ccv.validator.vdrFormator("Need 'xml' as file extend name");
		}		
		if (!/\.xml$/i.test(val)) {
			return ccv.validator.vdrFormator("File extend name must be \"xml\"");
		}					
		
		return "";
	},
	
	vdrXmlFilePwd: function(val) {
		if (val == "") {
			return ccv.validator.vdrFormator("Write-Protect Password is required");
		}
		
		return "";		
	},
	
	vdrXmlStream: function() {
		var jqCodeMirrorLines = ccv.domJQ.DLG_EDIT.find("div.CodeMirror-lines");
		if (jqCodeMirrorLines.find("span.cm-error").length) {
			return ccv.validator.vdrFormator("xml syntax error");
		}
		
		return "";
	},

	vdrRevs: function(val) {
		
		
	},

	vdrDates: function(val) {
		if (!ccv.fn.isDatesFormatValid(val)) {
			return 	ccv.validator.vdrFormator("Dates format is not right");
		}
		
		if (!ccv.fn.checkDatesLogic(val)) {
			return 	ccv.validator.vdrFormator("Date scope logic is illegal");
		}		
	},
	
	vdrWids: function(val) {
		if (!ccv.fn.isValidWids(val)) {
			return 	ccv.validator.vdrFormator("Not legal acounts");
		}
	},	

	vdrRev: function(val) {
		
		
	},

	vdrDate: function(val) {
		
		
	}
};
