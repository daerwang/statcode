ccv.dlgs = {
    init: function() {
		this._initDlgEdit();
		this._initDlgProgress();
    },
    
    _setDlgEditValidation: function() {
    	ccv.domJQ.DLG_EDIT.find("input.xmlFileName").bind("blur keyup", function(e) {
    		var val = jQuery.trim(this.value);
			var pmDom = e.type == "blur" ? this : null;
    		ccv.dlgs.showMsgInDlgEdit({msg: ccv.validator.vdrXmlFileName(val), dom: pmDom});
    	});
    	
    	ccv.domJQ.DLG_EDIT.find("input.xmlFilePwd").bind("blur keyup", function(e) {
    		var val = jQuery.trim(this.value);
    		var pmDom = e.type == "blur" ? this : null;	
    		ccv.dlgs.showMsgInDlgEdit({msg: ccv.validator.vdrXmlFilePwd(val), dom: pmDom});
    	});    	
    },
    
    _intFocus: 0,
    
    _intHide: 0,
    
    showMsgInDlgEdit: function(opts) {
    	var jqMsg = ccv.domJQ.DLG_EDIT.find("div.errMsg");
    	
    	if (opts && opts.msg) {
    		jqMsg.html(opts.msg).show();
    		
    		if (ccv.dlgs._intFocus) {
    			clearInterval(ccv.dlgs._intFocus);
    		}
    		if (ccv.dlgs._intHide) {
    			clearInterval(ccv.dlgs._intHide);
    		}    		
    		
    		if (opts.dom) {
    			ccv.dlgs._intFocus = setInterval(function() {
    				opts.dom.focus();
    				
    				clearInterval(ccv.dlgs._intFocus);
    				ccv.dlgs._intFocus = 0;
    			}, 20);
    		}
    		
    		if (opts.autoHide) {
    			ccv.dlgs._intHide = setInterval(function() {
    				jqMsg.hide();
    				clearInterval(ccv.dlgs._intHide);
    				ccv.dlgs._intHide = 0;
    			}, 3000);    			
    		}
    	} else {
    		jqMsg.hide();
    	}
    },
    
    _initDlgEdit: function() {
    	ccv.domJQ.DLG_EDIT.dialog({
    		width: 720,
    		height: 700,
    		closeOnEscape: true,
    		autoOpen: false,
    		modal: true,
    		title: "Edit configure",
    		close: function() {
    			ccv.uifn.enableSelectFileAnchor(true);
    		},
    		buttons: {
    			"Save": function() {
    				if (ccv.opts.DLG_EDIT_MODE == "edit") {
	    				var pwd = jQuery.trim(ccv.domJQ.XPVU_INPUT_XML_PWD.val());
	    				var content = ccv.vars.editor.getValue();
	    				var vdrRet = ccv.validator.vdrXmlStream();
	    				if (vdrRet) {
	    					ccv.dlgs.showMsgInDlgEdit({msg: vdrRet, dom: null, autoHide: true});
	    					return;
	    				}
	    				
	                    ccv.fn.wapi(
	                        {
	                            cmd: "SAVE_XML_FILE",
	                            cfg: ccv.domJQ.CFG_SELECT.val(),
	                            content: content,
	                            cfgPwd: pwd,
	                            flag: "edit"
	                        }, 
	                        ccv.cb.successSaveCfg, 
	                        ccv.cb.errorSaveCfg
	                    );    					
    				} else {
    					var jqXmlFileName = ccv.domJQ.DLG_EDIT.find("input.xmlFileName");
    					var jqXmlPwd = ccv.domJQ.DLG_EDIT.find("input.xmlFilePwd");
				    	var fileName = jQuery.trim(jqXmlFileName.val());
				    	var pwd = jQuery.trim(jqXmlPwd.val());    					
						
						var vdrRet = ccv.validator.vdrXmlFileName(fileName);
						if (vdrRet) {
							ccv.dlgs.showMsgInDlgEdit({msg: vdrRet, dom: jqXmlFileName[0]});
							return;
						}
						
						vdrRet = ccv.validator.vdrXmlFilePwd(pwd);
						if (vdrRet) {
							ccv.dlgs.showMsgInDlgEdit({msg: vdrRet, dom: jqXmlPwd[0]});
							return;
						}
						
	    				var vdrRet = ccv.validator.vdrXmlStream();
	    				if (vdrRet) {
	    					ccv.dlgs.showMsgInDlgEdit({msg: vdrRet, dom: null, autoHide: true});
	    					return;
	    				}						
	    				
	    				var content = ccv.vars.editor.getValue();
	                    ccv.fn.wapi(
	                        {
	                            cmd: "SAVE_XML_FILE",
	                            cfg: fileName,
	                            content: content,
	                            cfgPwd: pwd,
	                            flag: "new"
	                        }, 
	                        ccv.cb.successSaveCfg, 
	                        ccv.cb.errorSaveCfg
	                    ); 	    				
					}
    			},
    			
    			"Cancel": function() {
    				ccv.dlgs.showMsgInDlgEdit();
    				ccv.uifn.enableSelectFileAnchor(true);
    				jQuery(this).dialog("close");
    			}	
    		}
    	});
    	
    	ccv.dlgs._setDlgEditValidation();
    },
    
    _initDlgProgress: function() {
    	ccv.domJQ.DLG_PROGRESS.dialog({
    		width: 648,
    		closeOnEscape: false,
    		autoOpen: false,
    		modal: true,
    		title: 'Pls waiting for a moment, Report Generating ...',
    		close: function(event, ui) {
    			ccv.fn.resetProgress();							
    		},
    		buttons: {
    			'Close': function() {
    				ccv.fn.resetProgress();

    				jQuery(this).dialog('close');
    			}	
    		}
    	});    	
    },
    
    switchEditorMode: function(mode) {
    	var opts = {};
    	var jqElements4New = ccv.domJQ.DLG_EDIT.find("div.elements4New");
    	if (mode == "new") {
    		opts.height = 605;
    		if (jQuery.browser.msie && jQuery.browser.version < 8) {
    			opts.height = 615;
    		}
    		opts.title = "New configure";
    		jqElements4New.show();
    		jqElements4New.find("input.xmlFileName").val("new.xml");
    		jqElements4New.find("input.xmlFilePwd").val("");
    		ccv.opts.DLG_EDIT_MODE = "new";
    	} else {
    		opts.height = 625;
    		opts.title = "View/Edit configure";
    		jqElements4New.hide();
    		ccv.opts.DLG_EDIT_MODE = "edit";
    	}
    	
    	ccv.domJQ.DLG_EDIT.removeClass("new edit").addClass(mode);
    	
    	ccv.dlgs.showMsgInDlgEdit();
    	ccv.uifn.enableSelectFileAnchor(false);
    	ccv.domJQ.DLG_EDIT.dialog("option", opts).dialog("open");
    }  
};
