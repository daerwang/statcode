ccv.xpvUI = {
	bindEvents: function() {
		ccv.xpvUI._bindXmlPwdUis();
	},
	
	focusInput: function() {
		ccv.domJQ.XPVU_INPUT_XML_PWD.focus();
	},
	
	_xpuvBtnToDeleteClkHandler: function() {
		var pwd = jQuery.trim(ccv.domJQ.XPVU_INPUT_XML_PWD.val());
		if (!pwd || pwd == ccv.nls.cfg.xmlPwdHint) {
			ccv.uifn.showMsg("Write-protected Password needed!");
			ccv.domJQ.XPVU_INPUT_XML_PWD.focus();
			
			return;    					
		}
		
        ccv.fn.wapi(
            {
                cmd: "DEL_XML_FILE", 
                cfg: ccv.domJQ.CFG_SELECT.val(), 
                cfgPwd: pwd
            }, 
            ccv.cb.successDelete, 
            ccv.cb.errorDelete
        );			
	},
	
	_xpuvBtnToEditClkHandler: function() {
		var pwd = jQuery.trim(ccv.domJQ.XPVU_INPUT_XML_PWD.val());
		if (!pwd || pwd == ccv.nls.cfg.xmlPwdHint) {
			ccv.uifn.showMsg("Write-protected Password needed!");
			ccv.domJQ.XPVU_INPUT_XML_PWD.focus();
			
			return;    					
		}
		
        ccv.fn.wapi(
        	{
                cmd: "VERIFY_CFG_PWD", 
                cfg: ccv.domJQ.CFG_SELECT.val(), 
                cfgPwd: pwd
            }, 
            ccv.cb.successVerifyCfgPwd, 
            ccv.cb.errorVerifyCfgPwd
        );
	},	
	
	_bindXmlPwdUis: function() {
		ccv.domJQ.XML_PWD_VERIFY_UI.find(".close").click(function() {
			ccv.uifn.hideXmlPwdVerifyUI();
		});
		ccv.domJQ.XPVU_BTN_TODELETE.click(function() {
			ccv.xpvUI._xpuvBtnToDeleteClkHandler();
		});
		
		ccv.domJQ.XPVU_BTN_TOEDIT.click(function() {
			ccv.xpvUI._xpuvBtnToEditClkHandler();
		});
		
		var posCursorAtFirst = function(el) {
			if (document.selection) {//ie
				var r = el.createTextRange();
				r.collapse(true);   
				r.moveStart('character', 0);   
				r.moveEnd('character', 0);   
				r.select();   
			} else {
				el.selectionStart = 0;	
				el.selectionEnd = 0;
			}			
		};
		
		ccv.domJQ.XPVU_INPUT_XML_PWD.keyup(function(e) {
      		if (e.keyCode == 27) {//escape
      			ccv.uifn.hideXmlPwdVerifyUI();
	        }
		}).bind("click keydown", function(e) {
			if (e.type == "keydown" && e.keyCode == 13) {//enter
	        	var mode = ccv.domJQ.XML_PWD_VERIFY_UI.data("mode");
	        	if (mode == "2edit") {
	        		ccv.xpvUI._xpuvBtnToEditClkHandler();
	        	}
	        	if (mode == "2delete") {
	        		ccv.xpvUI._xpuvBtnToDeleteClkHandler();
	        	}	        	
	        }
			if (jQuery.trim(this.value) == ccv.nls.cfg.xmlPwdHint) {
				ccv.domJQ.XPVU_INPUT_XML_PWD.removeClass("grayClr").val("");
			}
		}).focus(function(e) {
			posCursorAtFirst(e.target);
		}).blur(function(e) {
			if (jQuery.trim(this.value) == "") {
				ccv.domJQ.XPVU_INPUT_XML_PWD.addClass("grayClr").val(ccv.nls.cfg.xmlPwdHint);
			}
		});					
	}
	
};

