ccv.cb = {
	
	_handleCfgFilesData: function(ret) {
    	ccv.xmlFiles = ret.CFG_FILES;
    	ccv.uifn.insertEntry2CfgsDom(ret.CFG_FILES, ret.CFG_FILE);
	},
	
	_handleModulesData: function(ret) {
    	ccv.vars.resetUseRuntimeAccount();
    	ccv.vars.modules = ret.MODULES;
        ccv.uifn.refreshModules(ret.MODULES);
	},	
	
    successGetOverall: function(ret) {
		if (ret.error == 1) {
			ccv.cb.errorGetOverall();
			return;
		}
		
		ccv.cb._handleCfgFilesData(ret);
		ccv.cb._handleModulesData(ret);
		
		ccv.bot.getBotedInfo();
    },
   
    errorGetOverall: function() {
    	ccv.vars.resetUseRuntimeAccount();
    	ccv.vars.modules = null;
    	ccv.xmlFiles = null;
        ccv.uifn.showMsg("WAPI call 'GetOverall' failed!");
    },
    
    successGetModules: function(ret) {
		if (ret.error == 1) {
			ccv.cb.errorGetModules();
			return;
		}
		
		ccv.cb._handleModulesData(ret);    	
        jQuery.cookie(ccv.def.CK_CFG, ccv.domJQ.CFG_SELECT.val(), {expires: 180});
    },
   
    errorGetModules: function() {
    	ccv.vars.resetUseRuntimeAccount();
        ccv.vars.modules = null;
        ccv.uifn.showMsg("WAPI call 'GetModules' failed!");
    },
    
    successGetXmlFiles: function(ret) {
		ccv.cb._handleCfgFilesData(ret);
    },
   
    errorGetXmlFiles: function(ret) {

    },        
    
    successDelete: function(ret) {
        if (ret.error == 0) {
            var domCfgSelect = ccv.domJQ.CFG_SELECT[0];
            domCfgSelect.remove(domCfgSelect.selectedIndex);
            domCfgSelect.selectedIndex = 0;
            ccv.fn.wapi({cmd: "GET_MODULES", cfg: domCfgSelect.value}, ccv.cb.successGetModules, ccv.cb.errorGetModules);
            
            ccv.uifn.hideXmlPwdVerifyUI();
            ccv.uifn.showMsg("Deleted successfully");
        } else {
            ccv.uifn.showMsg("Delete failed: Write-protected Password not match!");
            ccv.xpvUI.focusInput();
        }
    },
   
    errorDelete: function() {
        ccv.uifn.showMsg("Unkonwn error!");
        ccv.xpvUI.focusInput();
    },
    
    successVerifyCfgPwd: function(ret) {
        if (ret.error == 0) {
        	ccv.uifn.hideXmlPwdVerifyUI();
        	ccv.dlgs.switchEditorMode("edit");
        	if (!ccv.vars.editor) {
        		ccv.util.createEditor();	
        	}
        	ccv.vars.editor.setValue(ret.desc || "");
        } else {
            ccv.uifn.showMsg("Edit failed: Write-protected Password not match!");
            ccv.xpvUI.focusInput();
        }
    },
   
    errorVerifyCfgPwd: function() {
        ccv.uifn.showMsg("Unkonwn error!");
        ccv.xpvUI.focusInput();
    },
    
    successSaveCfg: function(ret) {
    	ret.desc = ret.desc.replace("%1", ret.cfg);
    	
        if (ret.error == 0) {
        	ccv.uifn.showMsg(ret.desc);
        	ccv.domJQ.DLG_EDIT.dialog("close");
        	ccv.uifn.enableSelectFileAnchor(true);
        	ccv.uifn.appendFile2Select(ret.cfg);
			
			if (ccv.domJQ.CFG_SELECT.val() == ret.cfg) {
				ccv.fn.wapi({cmd: "GET_MODULES", cfg: ret.cfg}, ccv.cb.successGetModules, ccv.cb.errorGetModules); 	
			}
        } else {
            ccv.dlgs.showMsgInDlgEdit({msg: ret.desc, dom: null, autoHide: true});
        }
    },
   
    errorSaveCfg: function() {
    	ccv.domJQ.DLG_EDIT.dialog("close");
        ccv.uifn.enableSelectFileAnchor(true);
        ccv.uifn.showMsg("Unkonwn error!");
    }
};
