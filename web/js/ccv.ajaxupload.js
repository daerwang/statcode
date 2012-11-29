ccv.ajaxupload = {
    opts: {
        action: "/ccv-cgi/wapi.pl",
		id: 'ccvFileDom',
        name: 'uploadedFile',
        data: {
            cmd: "UP_XML_FILE"
        },
        autoSubmit: false,
        responseType: "json",
		
		onChange: function(file, ext) {
		    ccv.domJQ.BTN_UPLOAD.removeClass("disabledBtn").attr("disabled", false);
		    ccv.domJQ.XML_NAME.html(file);
		},
		
        onSubmit: function(file, ext){
            if (!(ext && /^(xml)$/.test(ext))){
				ccv.uifn.showMsg("Only *.xml can be uploaded!");
				ccv.domJQ.XML_NAME.html("");
				ccv.domJQ.BTN_UPLOAD.addClass("disabledBtn").attr("disabled", true);
				
                return false;
            }
        },
        
        onComplete: function(file, ret){
        	var persistence = false;
            if (ret.error == 0) {
                if (ret.id == "NEW") {
                    ccv.uifn.appendFile2Select(file);
                 }
            } else {
            	if (ret.id == "CONFIG_ERROR") {
            		if (ret.error == -1) {
            			//file can not be phased
            		} else {
	            		persistence = true;
	            		ret.desc = "Configure Error: ";
	            		for (var i = 0; i < ret.modules.length; i++) {
	            			for (var j in ret.modules[i]) {
	            				ret.desc += ret.modules[i][j];
	            			}
	            		}
	            		
	            		ccv.uifn.appendFile2Select(file);            			
            		}

            	}
            }           
            ccv.uifn.showMsg(ret.desc, persistence);
            
            ccv.domJQ.BTN_UPLOAD.addClass("disabledBtn").attr("disabled", false);
            ccv.domJQ.XML_NAME.html("");
        }
    },
    
    executor: null
    
};
