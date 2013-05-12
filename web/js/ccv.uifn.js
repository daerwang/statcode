ccv.uifn = {
    tip: function(content) {
        Tip(content, CLICKCLOSE, true, STICKY, true, SHADOW, true, ABOVE, false, FADEIN, 500, FADEOUT, 500);
    },
        
    layoutMsgDiv: function() {
        ccv.domJQ.MSG.css({
            "width": ccv.domJQ.HEADER.width() - 2,
            "height": ccv.domJQ.HEADER.height(),
            "line-height": ccv.domJQ.HEADER.height() + "px"
        });
    },
    
    layoutAccountInfoDiv: function() {
    	if (!ccv.vars.counterUseRuntimeAccount) {
    		ccv.domJQ.ACCOUNT_INFO.hide();
    		ccv.domJQ.ACCOUNT_INFO_LINKER.hide();
    		return;
    	}
    	
    	var btnGenerateOffset = ccv.domJQ.BTN_GENERATE.offset();
    	var btnGenerateHeight = ccv.domJQ.BTN_GENERATE.height() + ccv.uifn._getPaddings(ccv.domJQ.BTN_GENERATE, 'tb');
    	var accountInfoDivWidth = ccv.domJQ.ACCOUNT_INFO.width() + ccv.uifn._getPaddings(ccv.domJQ.ACCOUNT_INFO);
    	var accountInfoDivHeight = ccv.domJQ.ACCOUNT_INFO.height() + ccv.uifn._getPaddings(ccv.domJQ.ACCOUNT_INFO, 'tb');

        ccv.domJQ.ACCOUNT_INFO.show().css({
            "top": btnGenerateOffset.top - accountInfoDivHeight + btnGenerateHeight,
            "left": btnGenerateOffset.left - accountInfoDivWidth - 80
        });
        ccv.domJQ.ACCOUNT_INFO_LINKER.show().css({
            "top": btnGenerateOffset.top + (btnGenerateHeight - 24) / 2,
            "left": btnGenerateOffset.left - 75
        });        
        
        ccv.uifn.fillAccountInfo();
    },
    
    fillAccountInfo: function() {
        var uid = '';
        var upw = '';
        
        var cfgFile = ccv.domJQ.CFG_SELECT.val();
        var accountInfo = ccv.fn.getRuntimeAccountInfo(cfgFile);
        if (accountInfo) {
            uid = accountInfo.uid;
            upw = accountInfo.upw;
        }
        ccv.domJQ.ACCOUNT_ID.val(uid);
        ccv.domJQ.ACCOUNT_PW.val(upw);            
    },  


    layoutOptionDiv: function() {
    	var offset = ccv.domJQ.A_OPTIONS.offset();
		var x = offset.left + ccv.domJQ.A_OPTIONS.width() - ccv.domJQ.OPTIONS.width() - 18;
		var y = offset.top + ccv.domJQ.A_OPTIONS.height() + 0;
		
		ccv.domJQ.OPTIONS.css({"top": y, "left": x});
    },
    
    showOptionDiv: function(show) {
    	if (arguments.length == 1) {
    		ccv.domJQ.OPTIONS.css("visibility", show ? "visible" : "hidden");
    		return;
    	}
		if (ccv.domJQ.OPTIONS.css('visibility') == 'hidden') {
			ccv.domJQ.OPTIONS.css("visibility", "visible");
		} else {
			ccv.domJQ.OPTIONS.css("visibility", "hidden");
		}    	
    },
	
	_getPaddings: function(jqDom, lrOrTb) {
		var a = jqDom.css("padding-left");
		var b = jqDom.css("padding-right");
		if (lrOrTb == 'tb') {
			a = jqDom.css("padding-top");
			b = jqDom.css("padding-bottom");			
		}
		
		return parseInt(/\d+/.exec(a)[0], 10) + parseInt(/\d+/.exec(b)[0], 10);
	},
    
    layoutCCV: function() {
        var w = jQuery(window).width() - 20;
        ccv.domJQ.HEADER.css("width", w);
        ccv.domJQ.MAIN.css("width", w);
    	
    	if (ccv.vars.cfgModuleWidthComplement == -1) {
    		var paddings = ccv.uifn._getPaddings(ccv.domJQ.USER_ACTIONS) + ccv.uifn._getPaddings(ccv.domJQ.HISTORY) + ccv.uifn._getPaddings(ccv.domJQ.CFG_MODULES);
    		var borders = 24;
    		ccv.vars.cfgModuleWidthComplement = ccv.domJQ.USER_ACTIONS.width() + ccv.domJQ.HISTORY.width() + paddings + 10 + borders;
    	}
        ccv.domJQ.CFG_MODULES.css("width", w - ccv.vars.cfgModuleWidthComplement);
        
        ccv.uifn.layoutMsgDiv();
        ccv.ajaxupload.executor.layoutAll();
        ccv.uifn.layoutOptionDiv();
        ccv.uifn.layoutAccountInfoDiv();
    },

    
    resetMsgInterval: function() {
        ccv.domJQ.MSG.css("visibility", "hidden");
        clearInterval(ccv.vars.msgInterval);
        ccv.vars.msgInterval = 0;            
    },
    
    showMsg: function(msg, persistence) {
        if (ccv.vars.msgInterval) {
            ccv.uifn.resetMsgInterval();
        }
        
        ccv.domJQ.MSG_CONTENT.html(ccv.util.escapeHtml(msg)).attr("title", msg);
        ccv.domJQ.MSG.css("visibility", "visible");
        if (!persistence) {
	        ccv.vars.msgInterval = setInterval(function() {
	             ccv.uifn.resetMsgInterval();
	        }, 4000);
	    }   	
    },
    
    _getCodeItemDetailsString: function(item) {
    	var str = "";
        if (item.type == "cvs") {
        	str = item.module + "<br>" + item.repositoryPath;
        } else if (item.type == "svn"){
        	str = item.module + "<br>" + item.trunkFullPath + "<br>" + item.branchFullPath + "<br>" + item.tagFullPath;
        } else if (item.type == "git"){
        	str = item.url;
        }
        
        return str; 	
    },

    refreshModules: function(modules) {
        ccv.vars.counterUseRuntimeAccount = 0;
        
        ccv.domJQ.MODULES.hide();
        ccv.domJQ.ALL_ANCHOR.attr("checked", false);
        ccv.domJQ.MODULE_ANCHORS.attr("checked", false).val("");
        ccv.uifn.changeModulesBG(false, ccv.domJQ.MODULES);
        
        var toDynamicModuleItems = function() {
        	var delta =  modules.length - ccv.domJQ.MODULES.length;
        	if (delta <= 0 ) {
        		if (modules.length <= 50 && ccv.domJQ.MODULES.length > 50) {
        			ccv.domJQ.MODULES.slice(50).detach();
        			ccv.domJQ.MODULES = ccv.domJQ.MODULES_CONTAINER.find("div.module");
        		}
        		
        		return;
        	}
        	
        	var addedItems = "";
        	for (var i = 0; i < delta; i++) {
        		addedItems += ccv.ModuleItemHtml + "\n";
        	}
        	
        	ccv.domJQ.MODULES_CONTAINER.append(addedItems);
        	ccv.domJQ.MODULES = ccv.domJQ.MODULES_CONTAINER.find("div.module");
        }();
        
        for (var i = 0; i < modules.length; i++) {
            if (modules[i].useRuntimeAccount == '1') {
                ccv.vars.counterUseRuntimeAccount++;    
            }
        	var shownMid = modules[i].id;
            var jqModule = ccv.domJQ.MODULES.eq(i);
            jqModule.find("div.anchor input").val(modules[i].id);
            
            if (modules[i].CFG_ERROR) {
            	shownMid = '<span class="errSetting" onselectstart="return false;">Error: ' + ccv.util.escapeHtml(modules[i].CFG_ERROR) + '</span>' + shownMid;
            }
            
            jqModule.find("div.moduleInfo span.moduleId").html(shownMid);
            jqModule.find("div.moduleInfo span.moduleType").html("(" + modules[i].type + ")");
            
            var indicator = modules[i].useRuntimeAccount == '1' ? ' use Runtime Account' : '';
            var jqIndicator = jqModule.find("div.moduleInfo span.moduleIndicator").html(indicator);
            
            jqModule.removeClass("cvs svn git").addClass(modules[i].type);
            jqModule.find("div.moduleInfo span.moduleDetails").html(ccv.uifn._getCodeItemDetailsString(modules[i]));
            jqModule.show();
        }
        
        ccv.uifn.layoutAccountInfoDiv();          
    },
    
    insertEntry2CfgsDom: function(cfgs, defaultCfg) {
        var opts = "";
        for (var i = 0; i < cfgs.length; i++) {
            var flagChecked = (cfgs[i] == defaultCfg) ? " selected" : "";
			opts += "<option value='" + cfgs[i] + "' "   + flagChecked + ">" + cfgs[i] + "</option>";
        }
     
        ccv.domJQ.CFG_SELECT.html(opts);
    },
    
    changeModulesBG: function(checkedOn, jqM) {
        if (checkedOn) {
            jqM.addClass("bkChecked");        
        } else {
            jqM.removeClass("bkChecked");
        }
    },
    
    behaviorModuleItmes: function() {
    	jQuery.each(ccv.domJQ.MODULE_ANCHORS, function(index) {
    		if (ccv.domJQ.MODULE_ANCHORS.eq(index).attr('checked')) {
    			ccv.uifn.changeModulesBG(true, ccv.domJQ.MODULES.eq(index));
    		}
    	});
    },
    
    
    htmlSvnRevBaseDoms: function() {
    	var opts = [
    		{k: "branch", v: "Is branch"},
    		{k: "trunk", v: "Is trunk"},
    		{k: "OnTrunk", v: "On trunk"},
    		{k: "OnBranch", v: "On branch"},
    		{k: "tag", v: "Is tag"}
    	];
    	
    	var revOptHtml = "";
    	var dateOptHtml = "<option value='" + opts[2].k + "'>" + opts[2].v + "</option>\n<option value='" + opts[3].k + "'>" + opts[3].v + "</option>\n";
    	for (var i = 0; i < opts.length; i++) {
    		var strChecked = opts[i].k == "branch" ? "checked" : "";
    		revOptHtml += "<option value='" + opts[i].k + "' " + strChecked + ">" + opts[i].v + "</option>\n";
    	}
    	
		ccv.domJQ.SVN_REV_BASE.filter(".svnRev1Base, .svnRev2Base").html(revOptHtml);
		ccv.domJQ.SVN_REV_BASE.filter(".svnDate1Base, .svnDate2Base").html(dateOptHtml).attr("disabled", true).addClass("gray");   	  	
    },
    
	behaviorDiffDoms: function() {
	    if (ccv.domJQ.RADIO_DIFF_AGAINST.filter(':checked').val() == "dates") {
	        ccv.domJQ.DIFF.find("input.Wdate").attr("disabled", false).removeClass("gray");
	        ccv.domJQ.DIFF.find("input.revision").attr("disabled", true).addClass("gray");
	        ccv.domJQ.DIFF.find("input.branchRevsBasedOn").attr("disabled", true).addClass("gray");
	        ccv.domJQ.DIFF.find("input.branchDatesBasedOn").attr("disabled", false).removeClass("gray");
	        
	        ccv.domJQ.SVN_REV_BASE.filter(".svnRev1Base, .svnRev2Base").attr("disabled", true).addClass("gray");
	        ccv.domJQ.SVN_REV_BASE.filter(".svnDate1Base, .svnDate2Base").attr("disabled", false).removeClass("gray");
	        
	        ccv.uifn._revBasedSlt2BranchInput(ccv.domJQ.SVN_REV_BASE.filter(".svnDate1Base"), ccv.domJQ.DIFF.find("input.branchDatesBasedOn"));
	        
	    } else {
	        ccv.domJQ.DIFF.find("input.Wdate").attr("disabled", true).addClass("gray");
	        ccv.domJQ.DIFF.find("input.revision").attr("disabled", false).removeClass("gray");
	        ccv.domJQ.DIFF.find("input.branchDatesBasedOn").attr("disabled", true).addClass("gray");
	        ccv.domJQ.DIFF.find("input.branchRevsBasedOn").attr("disabled", false).removeClass("gray");
	        
	        ccv.domJQ.SVN_REV_BASE.filter(".svnRev1Base, .svnRev2Base").attr("disabled", false).removeClass("gray");
	        ccv.domJQ.SVN_REV_BASE.filter(".svnDate1Base, .svnDate2Base").attr("disabled", true).addClass("gray");
	        
	        ccv.uifn._revBasedSlt2BranchInput(ccv.domJQ.SVN_REV_BASE.filter(".svnRev1Base"), ccv.domJQ.DIFF.find("input.branchRevsBasedOn"));
 	    } 
	},
	
	_revBasedSlt2BranchInput: function(jqSlt, jqInput) {
		if (jqSlt.val() == "OnBranch") {
			jqInput.attr("disabled", false).removeClass("gray");
		} else {
			jqInput.attr("disabled", true).addClass("gray");
		}
	},
	
	_revBasedSlt2RevsInput: function() {
		if (ccv.domJQ.SVN_REV_BASE.filter(".svnRev1Base").val() == "trunk") {
			ccv.domJQ.DIFF.find("input.rev1").attr("disabled", true).addClass("gray");
		} else {
			ccv.domJQ.DIFF.find("input.rev1").attr("disabled", false).removeClass("gray");
		}
		
		if (ccv.domJQ.SVN_REV_BASE.filter(".svnRev2Base").val() == "trunk") {
			ccv.domJQ.DIFF.find("input.rev2").attr("disabled", true).addClass("gray");
		} else {
			ccv.domJQ.DIFF.find("input.rev2").attr("disabled", false).removeClass("gray");
		}			
	},
	
	behaviorSvnDateRevBaseDomsRestriction: function() {
		var jqBranchRevsBasedOn = ccv.domJQ.DIFF.find("input.branchRevsBasedOn");
		var jqBranchDatesBasedOn = ccv.domJQ.DIFF.find("input.branchDatesBasedOn");
		
		var jqRevsDfBase = ccv.domJQ.SVN_REV_BASE.filter(".svnRev1Base, .svnRev2Base").change(function() {
			if (this.value.indexOf("On") == 0) {
				if (jQuery(this).attr("class").indexOf("svnRev1Base") > 0) {
					jqRevsDfBase.filter(".svnRev2Base").val(this.value)
				} else {
					jqRevsDfBase.filter(".svnRev1Base").val(this.value)
				}
			}
			
			ccv.uifn._revBasedSlt2RevsInput();
			ccv.uifn._revBasedSlt2BranchInput(jQuery(this), jqBranchRevsBasedOn);
		});

		var jqDatesDfBase = ccv.domJQ.SVN_REV_BASE.filter(".svnDate1Base, .svnDate2Base").change(function() {
			if (jQuery(this).attr("class").indexOf("svnDate1Base") > 0) {
				jqDatesDfBase.filter(".svnDate2Base").val(this.value)
			} else {
				jqDatesDfBase.filter(".svnDate1Base").val(this.value)
			}			
			ccv.uifn._revBasedSlt2BranchInput(jQuery(this), jqBranchDatesBasedOn);
		});
	},
	
	appendFile2Select: function(cfgFile) {
		var opt = ccv.domJQ.CFG_SELECT.find("option[value='" + cfgFile + "']");
		if (!opt.length) {
			ccv.domJQ.CFG_SELECT.append("<option value='" + cfgFile + "'>" + cfgFile + "</option>");
			ccv.xmlFiles.push(cfgFile);
		} 
	},
	
	showXmlPwdVerifyUI: function(mode) {
		if (mode == "2edit") {
			ccv.domJQ.XPVU_BTN_TOEDIT.show();
			ccv.domJQ.XPVU_BTN_TODELETE.hide();
		} else {//2delete
			ccv.domJQ.XPVU_BTN_TOEDIT.hide();
			ccv.domJQ.XPVU_BTN_TODELETE.show();
		}
		ccv.domJQ.XML_PWD_VERIFY_UI.data("mode", mode).show();
		ccv.domJQ.XPVU_INPUT_XML_PWD.addClass("grayClr").val(ccv.nls.cfg.xmlPwdHint).focus();
	},
	
	hideXmlPwdVerifyUI: function(mode) {
		ccv.domJQ.XML_PWD_VERIFY_UI.hide();
	},
	
	enableSelectFileAnchor: function(show) {
		var jqDom = jQuery("input#ccvFileDom");
		jqDom.css("z-index", (show ? 9998 : -1));
	},
	
	switchUserActionsMode: function(mode) {
		
	    if (mode == "log") {
	        ccv.domJQ.LOG.show();
	        ccv.domJQ.DIFF.hide();
	        ccv.domJQ.FILE.hide();
	    } else if (mode == "diff") {
	        ccv.domJQ.DIFF.show();
	        ccv.domJQ.LOG.hide();
	        ccv.domJQ.FILE.hide();
	    } else {
	        ccv.domJQ.FILE.show();
	        ccv.domJQ.LOG.hide();
	        ccv.domJQ.DIFF.hide();
	    }
	    
	    ccv.uifn.layoutComboBoxAnchor(mode);
	    ccv.ac.close();
	},
	
	initComboboxes: function() {
		var jqComboBoxes = jQuery('.ccv input.combobox');
		var downAnchorHtml = '<div class="comboboxDownAnchor"/>'
		for (var i = 0; i < jqComboBoxes.length; i++) {
			var jqDownAnchor = jQuery(downAnchorHtml).insertAfter(jqComboBoxes.eq(i));
			
			jqDownAnchor.click(function() {
				ccv.ac.open(jQuery(this));
			});			
		}
	},
	
	layoutComboBoxAnchor: function(mode) {
		var jqContainer = ccv.domJQ[mode.toUpperCase()];
		var jqComboBoxInput = jqContainer.find('input.combobox');
		var jqComboBoxAnchor = jqContainer.find('.comboboxDownAnchor');
		
		for (var i = 0; i < jqComboBoxInput.length; i++) {
	    	var comboBoxInputOffset = jqComboBoxInput.eq(i).position();
	    	var comboBoxInputWidth = jqComboBoxInput.eq(i).width() +  ccv.uifn._getPaddings(jqComboBoxInput.eq(i), 'lr');
	        jqComboBoxAnchor.eq(i).css({
	            "top": comboBoxInputOffset.top + 1,
	            "left": comboBoxInputOffset.left + comboBoxInputWidth - 23
	        });  			
		}
	},
	
	initDomJQ: function() {
		ccv.domJQ = {};
		ccv.domJQ.CCV_PARENT            = jQuery(".ccv").parent();
	    ccv.domJQ.CFG_MODULES           = jQuery(".ccv div.cfgModules");
	    ccv.domJQ.CFG_SELECT            = ccv.domJQ.CFG_MODULES.find("select.cfgFiles");
	    ccv.domJQ.MODULES_CONTAINER     = ccv.domJQ.CFG_MODULES.find("div.modules");
	    ccv.domJQ.MODULES               = ccv.domJQ.MODULES_CONTAINER.find("div.module");
	    
	    ccv.domJQ.XML_PWD_VERIFY_UI 	= ccv.domJQ.CFG_MODULES.find("div.xmlPwdVerifyContainer");
	    ccv.domJQ.XPVU_BTN_TODELETE 	= ccv.domJQ.XML_PWD_VERIFY_UI.find("a.toDelete");
	    ccv.domJQ.XPVU_BTN_TOEDIT	 	= ccv.domJQ.XML_PWD_VERIFY_UI.find("a.toEdit");
	    ccv.domJQ.XPVU_INPUT_XML_PWD	= ccv.domJQ.XML_PWD_VERIFY_UI.find("input.xmlPwd");
	    
	    ccv.domJQ.MAIN                  = jQuery(".ccv div.main");
	    ccv.domJQ.USER_ACTIONS          = jQuery(".ccv div.userActions");
	    ccv.domJQ.MODE_SELECTOR			= ccv.domJQ.USER_ACTIONS.find(".modeSelector");
	    ccv.domJQ.LOG                   = ccv.domJQ.USER_ACTIONS.find("div.log");
	    ccv.domJQ.DIFF                  = ccv.domJQ.USER_ACTIONS.find("div.diff");
	    ccv.domJQ.FILE                  = ccv.domJQ.USER_ACTIONS.find("div.file");
	    
	    ccv.domJQ.RADIO_MODE            = jQuery(".ccv div.userActions input.radioMode");
	    ccv.domJQ.RADIO_DIFF_AGAINST    = ccv.domJQ.DIFF.find("input.diffAgainst");
	    
	    ccv.domJQ.FILE_REV              = ccv.domJQ.FILE.find("input.action_file_revs");
	    
	    ccv.domJQ.REVS                  = ccv.domJQ.LOG.find("input.revs");
	    ccv.domJQ.DATES                 = ccv.domJQ.LOG.find("input.dates");
	    ccv.domJQ.WIDS                  = ccv.domJQ.LOG.find("input.wids");
	    
	    ccv.domJQ.REV1                  = ccv.domJQ.DIFF.find("input.rev1");
	    ccv.domJQ.REV2                  = ccv.domJQ.DIFF.find("input.rev2");
	    ccv.domJQ.DATE1                 = ccv.domJQ.DIFF.find("input.date1");
	    ccv.domJQ.DATE2                 = ccv.domJQ.DIFF.find("input.date2");
	    ccv.domJQ.SVN_REV_BASE			= ccv.domJQ.DIFF.find("select.svnRevBase");
	    
	    ccv.domJQ.BTN_GENERATE          = ccv.domJQ.USER_ACTIONS.find("button");
	    ccv.domJQ.BTN_DELETE            = ccv.domJQ.CFG_MODULES.find(".deleteCfg");
	    ccv.domJQ.BTN_EDIT              = ccv.domJQ.CFG_MODULES.find(".editCfg");
	    ccv.domJQ.BTN_NEW               = ccv.domJQ.CFG_MODULES.find(".newCfg");
	    ccv.domJQ.A_OPTIONS             = ccv.domJQ.CFG_MODULES.find("a.reportOptions");
		
	    ccv.domJQ.ACCOUNT_INFO       	= jQuery(".ccv .runtimeAccount");
	    ccv.domJQ.ACCOUNT_INFO_LINKER  	= jQuery(".ccv .linkerRuntimeAccount2Generate");
	    ccv.domJQ.ACCOUNT_ID       		= ccv.domJQ.ACCOUNT_INFO.find(".accountId");
	    ccv.domJQ.ACCOUNT_PW       		= ccv.domJQ.ACCOUNT_INFO.find(".accountPw");
	    ccv.domJQ.ACCOUNT_REMEMBER      = ccv.domJQ.ACCOUNT_INFO.find(".rememberAccount");
	    
	    ccv.domJQ.ALL_ANCHOR            = ccv.domJQ.CFG_MODULES.find("input.allAnchor");
	    ccv.domJQ.MODULE_ANCHORS        = ccv.domJQ.MODULES.find("input");
	    ccv.domJQ.OPTIONS               = jQuery(".ccv div.divOptions");
	    
	    ccv.domJQ.HEADER                = jQuery(".ccv div.header");
	    ccv.domJQ.MSG                   = ccv.domJQ.HEADER.find("div.msg");
	    ccv.domJQ.MSG_CONTENT           = ccv.domJQ.MSG.find(".content");
	    ccv.domJQ.BTN_BROWSE            = ccv.domJQ.HEADER.find("button.btnBrowse");
	    ccv.domJQ.XML_NAME              = ccv.domJQ.HEADER.find("span.xmlName");
	    ccv.domJQ.UP_PASSWD             = ccv.domJQ.HEADER.find("input.upPasswd");
	    ccv.domJQ.BTN_UPLOAD            = ccv.domJQ.HEADER.find("button.btnUpload");
	    
	    ccv.domJQ.DLGS                  = jQuery(".ccv div.dlgs");
	    ccv.domJQ.DLG_PROGRESS          = ccv.domJQ.DLGS.find("div.dlgProgress");
	    ccv.domJQ.PROGRESS              = ccv.domJQ.DLGS.find("div.progress");
	    ccv.domJQ.DLG_EDIT      		= ccv.domJQ.DLGS.find("div.dlgEdit");
	    
	    ccv.domJQ.HISTORY               = jQuery("iframe.iframeHistory");
	    ccv.domJQ.COUNTER 				= jQuery(".__COUNTER__");
	},
	
	bindEvent: function() {
		ccv.domJQ.A_OPTIONS.click(function() {
			ccv.uifn.showOptionDiv();
		});
		
		ccv.domJQ.OPTIONS.dblclick(function() {
			//ccv.domJQ.OPTIONS.css("visibility", "hidden");
		});
		
		ccv.domJQ.OPTIONS.find(".options .opt4cvs input:checkbox").attr("checked", false);
	
		ccv.domJQ.OPTIONS.find(".closeAnchor").click(function() {
			ccv.domJQ.OPTIONS.css("visibility", "hidden");
		});
		
		ccv.domJQ.MSG.dblclick(function() {
			ccv.domJQ.MSG.css("visibility", "hidden");
		}).find(".msgCloseAnchor").click(function() {
			ccv.domJQ.MSG.css("visibility", "hidden");
		});	
		
		
		var funRevFocus = function(domObj) {
			if (domObj.value == "Input branch name here") {
				domObj.value = "";
			}	
		};
		var funRevBlur = function(domObj) {
			if (domObj.value == "") {
				domObj.value = "Input branch name here";
			}	
		};	
		ccv.domJQ.REVS.focus(function() {
			funRevFocus(this);
		}).blur(function() {
			funRevBlur(this);
		});
		
		ccv.domJQ.FILE_REV.focus(function() {
			funRevFocus(this);
		}).blur(function() {
			funRevBlur(this);
		});	
		
	
	    ccv.domJQ.MODULES.mouseover(function() {
	        jQuery(this).addClass("bkHover");    
	    }).mouseout(function() {
	        jQuery(this).removeClass("bkHover");    
	    }).click(function() {
	    	var i = ccv.domJQ.MODULES.index(this);
	    	ccv.domJQ.MODULE_ANCHORS[i].checked = !ccv.domJQ.MODULE_ANCHORS[i].checked;
	    	ccv.uifn.changeModulesBG(ccv.domJQ.MODULE_ANCHORS[i].checked, ccv.domJQ.MODULES.eq(i));
	    });
	    
	    ccv.domJQ.MODULE_ANCHORS.click(function(e) {
	        var i = ccv.domJQ.MODULE_ANCHORS.index(this);
	        ccv.uifn.changeModulesBG(this.checked, ccv.domJQ.MODULES.eq(i));
	        e.stopPropagation();
	    });
	    
	    ccv.domJQ.ALL_ANCHOR.click(function() {
	        ccv.domJQ.MODULE_ANCHORS.attr("checked", this.checked);
	        ccv.uifn.changeModulesBG(this.checked, ccv.domJQ.MODULES);
	    });    
	    
	    ccv.domJQ.OPTIONS.find("table td.optionDesc").click(function() {
	    	var jqPrevTd = jQuery(this).prev();
	    	var jqChkBox = jqPrevTd.find("input");
	    	
	    	jqChkBox.attr("checked", !jqChkBox[0].checked);
	    });
		
		ccv.domJQ.BTN_GENERATE.mouseover(function() {
		    ccv.domJQ.BTN_GENERATE.css("background-color", "#cc0000");
		}).mouseout(function() {
		    ccv.domJQ.BTN_GENERATE.css("background-color", "#aa0000");
		}).click(function() {
		    ccv.fn.submitGenerate();
		});
		
		ccv.domJQ.RADIO_MODE.click(function() {
			ccv.uifn.switchUserActionsMode(this.value);
	    });
		
		ccv.domJQ.RADIO_DIFF_AGAINST.click(function() {
			ccv.uifn.behaviorDiffDoms();
		});
		
	    jQuery(".header .writeProtectPwdInstruction").mouseover(function() {
			var tipWriteProtectPwdInstruction = "Provide a Write-protect Password for the *.xml when upload!<br>\
				<font color=#ff0000>Remember this password & do not forget it!</font><br>\
				It is required when you want to Update or Remove it.";
	       	ccv.uifn.tip(tipWriteProtectPwdInstruction);
	    });
	    
	    ccv.domJQ.CFG_SELECT.change(function() {
	    	var cfg = ccv.domJQ.CFG_SELECT.val();
	        ccv.fn.wapi({cmd: "GET_MODULES", cfg: cfg}, ccv.cb.successGetModules, ccv.cb.errorGetModules);
	        ccv.bot.switchCfgAvailableRevs(cfg, 'branches');
	        ccv.ac.updateSource();
	    });
	    
	    ccv.domJQ.BTN_DELETE.click(function() {
	    	ccv.uifn.showXmlPwdVerifyUI("2delete");
	    	return false;
	    });
	    
	    ccv.domJQ.BTN_EDIT.click(function() {
	    	ccv.uifn.showXmlPwdVerifyUI("2edit");
	    	return false;
	    });    
	
	    ccv.domJQ.BTN_NEW.click(function() {
	        ccv.dlgs.switchEditorMode("new");
	    	if (!ccv.vars.editor) {
	    		ccv.util.createEditor();	
	    	}
	    	   	
	    	ccv.fn.wapi({cmd: "GET_XML_CONTENT", cfg: "example.xml"}, function(ret) {
	    		ccv.vars.editor.setValue(ret.desc || "");
	    	},function(ret) {
				ccv.uifn.showMsg("WAPI GET_XML_CONTENT ERROR!");
	    	});
	    	return false;
	    });    
	    
	    ccv.domJQ.BTN_UPLOAD.click(function() {
	        var pw = jQuery.trim(ccv.domJQ.UP_PASSWD.val());
	        ccv.domJQ.UP_PASSWD.val(pw)
	        if (!pw) {
	            ccv.uifn.showMsg("Write-protect password can not be empty");
	            
	            return false;
	        }
	        ccv.ajaxupload.executor._settings.data.cfgPwd = pw;
	        ccv.ajaxupload.executor.submit();
	    }); 
	    
	    jQuery(window).resize(function() {
	        ccv.uifn.layoutCCV();
	    });
	    
	    var jqModeName = jQuery(".ccv div.modeSelector .modeName").click(function() {
	        ccv.domJQ.RADIO_MODE.eq(jqModeName.index(this)).click();
	    });
	    
	    ccv.xpvUI.bindEvents();    		
	}	
};
