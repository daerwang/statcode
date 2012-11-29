/**
 * ===========================================================================================
 * ccv business functions
 * 
 */
ccv.fn = {
    wapi: function(jsonData, cbSuccess, cbError) {
    	if (ccv.opts.MODE != -1 && /^(GET_OVERALL|GENERATE)$/.test(jsonData.cmd)) {
    		ccv.util.counterCcv(jsonData);
    	}
    	
        jQuery.ajax({
            url: "/ccv-cgi/wapi.pl",
            type: "POST",
            dataType: "json",
            data: jsonData,
            success: cbSuccess,
            error: cbError
        });
    },
    
    isDatesFormatValid: function(dates) {
        if (dates == "") {
            return true;
        }
                
        return /^(([<>]=?)?)(\d{1,2}[\-\/]\d{1,2}[\-\/]\d{4}|\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2})$/.test(dates)
            || /^(\d{1,2}[\-\/]\d{1,2}[\-\/]\d{4}|\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2})([<>]=?)(\d{1,2}[\-\/]\d{1,2}[\-\/]\d{4}|\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2})$/.test(dates);
    },    

    checkDatesLogic: function(dates) {
        var matched = dates.match(/^(\d{1,2}[\-\/]\d{1,2}[\-\/]\d{4}|\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2})([<>]=?)(\d{1,2}[\-\/]\d{1,2}[\-\/]\d{4}|\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2})$/);
        
        if (matched != null) {
            date1   = dates.match(/^(\d{1,2}[\-\/]\d{1,2}[\-\/]\d{4}|\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2})/g);
            date2   = dates.match(/(\d{1,2}[\-\/]\d{1,2}[\-\/]\d{4}|\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2})$/g);
            arr1    = date1[0].split("/");
            arr2    = date2[0].split("/");
            arr11   = date1[0].split("-");
            arr21   = date2[0].split("-");
            
            arr1    = arr1.length > arr11.length ? arr1 : arr11;
            arr2    = arr2.length > arr21.length ? arr2 : arr21;
            
            var d1, d2;
            if (arr1[2] > 1000) {
                d1  = new Date(arr1[2], arr1[0] - 1, arr1[1]);
                d2  = new Date(arr2[2], arr2[0] - 1, arr2[1]);
            } else {
                d1  = new Date(arr1[0], arr1[1] - 1, arr1[2]);
                d2  = new Date(arr2[0], arr2[1] - 1, arr2[2]);            
            }
                            
            operator = dates.match(/([<>]=?)/g);
            
            strCompareExpression = "" + d1.getTime() + operator[0] + d2.getTime() + "";
            
            compareResult = eval(strCompareExpression);
    
            return compareResult;
        } 
        
        return true;
    },
    
    isValidWids: function(val) {
    	if (/^[\w\._\-]+$/.test(val)
	    	|| /^([\w\._\-]+[\,;])+([\w\._\-]+)?$/.test(val)) {
    		return true;
    	}
    	
    	return false;
    },
    
    setRuntimeAccountCookie: function(pms) {
        var cookieName = ccv.fn.getRuntimeAccountCookieName(pms.cfg);
        
        if (!ccv.domJQ.ACCOUNT_REMEMBER[0].checked) {
            jQuery.cookie(cookieName, null);
        } else {
            var cookieValue = pms.uid + ' ' + pms.upw;
            cookieValue = ccv.fn.codeit(cookieValue, 'en');
            jQuery.cookie(cookieName, cookieValue, {expires: 180});
        }
    },
    
    codeit: function(str, flag) {
    	var out = str;
    	for (var i = 0; i <= 3; i++) {
    		if (flag == 'en') {
    			out = ccv.util.Base64.encode(out);
    		} else {
    			out = ccv.util.Base64.decode(out);
    		}
    	}
    	
    	return out;
    },
    
    getRuntimeAccountInfo: function(cfgFile) {
        var cookieValue = jQuery.cookie(ccv.fn.getRuntimeAccountCookieName(cfgFile));
        if (!cookieValue) {
            return null;
        }

        var arr = ccv.fn.codeit(cookieValue, 'de').split(' ');
        return {
            uid: arr[0],
            upw: arr[1]
        };
    },
    
    getCfgNameWithoutExt: function(cfgFile) {
        return cfgFile.substr(0, cfgFile.length - 4);
    },
    
    getRuntimeAccountCookieName: function(cfgFile) {
        return ccv.def.CK_RUNTIME_ACCOUNT + ccv.fn.getCfgNameWithoutExt(cfgFile);
    },
    
    submitGenerate: function() {
        var ret = ccv.fn.beforeSubmitGenerate();
        
        if (!ret) {
            return false;
        }
        
        var pms = ccv.fn.constructPMs();
        
        if (ccv.vars.counterUseRuntimeAccount
        	&& ccv.fn.existSelectedUseRuntimeAccount(pms.mids)
        	&& !ccv.fn.ifRuntimeAccountProvided()) {
        	ccv.uifn.showMsg("Repository account name and password required!");
        	if (ccv.domJQ.ACCOUNT_ID.val() == '') {
        	    ccv.domJQ.ACCOUNT_ID.focus();    
        	} else {
        	    ccv.domJQ.ACCOUNT_PW.focus();    
        	}
        	return false;
        } else {
        	//ccv.uifn.showMsg("Check passed!");
        	//return false;
        }
        
        if (!jQuery.isPlainObject(pms)) {
        	ccv.uifn.showMsg(pms);
        	return false;
        }
		
		ccv.uifn.showOptionDiv(false);
        ccv.fn.runGenerate(pms);
    },
    
    ifRuntimeAccountProvided: function() {
        var uid = jQuery.trim(ccv.domJQ.ACCOUNT_ID.val());
        var upw = jQuery.trim(ccv.domJQ.ACCOUNT_PW.val());
        if (uid == 'anonymous') {
            return true;
        }
        
        return uid != '' && upw != '';
    },
    
    beforeSubmitGenerate: function() {
        jQuery.each(ccv.domJQ.USER_ACTIONS.find("input:text"), function(index, item) {
            item.value = jQuery.trim(item.value);
        });
        
        if (!ccv.domJQ.MODULES.find(":checked").length) {
            ccv.uifn.showMsg("Please select one or more modules");
            
            return false;
        }
        
        var reportMode = ccv.domJQ.USER_ACTIONS.find("input.radioMode:checked").val();
        var dates = ccv.domJQ.DATES.val();
        if (reportMode == "log") {
	        if (ccv.domJQ.REVS.val() == "" || ccv.domJQ.REVS.val() == "Input branch name here") {
	            ccv.uifn.showMsg("Revison(s)/Branch needed!");
	            ccv.domJQ.REVS.focus();
	            
	            return false;
	        }
                	
            if (ccv.fn.isDatesFormatValid(dates)) {
                if (!ccv.fn.checkDatesLogic(dates)) {
                    ccv.uifn.showMsg("Date scope logic is not valid, please correct it.");
                    ccv.domJQ.DATES.focus();
                    
                    return false;
                }                
            } else {
                ccv.uifn.showMsg("Dates format is not right, please refer to examples!");
                ccv.domJQ.DATES.focus();
                
                return false;                
            }
        } else if (reportMode == "diff"){
        	var dfAgainst = ccv.domJQ.RADIO_DIFF_AGAINST.filter(":checked").val();
        	if (dfAgainst == "revisions") {
        		if (ccv.domJQ.REV1.val() == "" && ccv.domJQ.REV2.val() == "") {
	                ccv.uifn.showMsg("Revsions(rev1/rev2) needed!");
	                ccv.domJQ.REV1.focus();
	                
	                return false;                			
        		}
        	} else {
        		if (ccv.domJQ.DATE1.val() == "" && ccv.domJQ.DATE2.val() == "") {
	                ccv.uifn.showMsg("Dates(d1/d2) needed!");
	                ccv.domJQ.DATE1.focus();        			
	                
	                return false;        
        		}        		
        	}
        } else if (reportMode == "file") {
			if (ccv.domJQ.FILE_REV.val() == "" || ccv.domJQ.FILE_REV.val() == "Input branch name here") {
	            ccv.uifn.showMsg("Revison/Branch needed!");
	            ccv.domJQ.FILE_REV.focus();
	            
	            return false;
	        }        	
        }
        
        
        return true;
    },
    
    getOptions: function(pms) {
    	//options for cvs module
        var jqOstatBin = ccv.domJQ.OPTIONS.find("input.OstatBin");
        var jqOnotStatDeleted = ccv.domJQ.OPTIONS.find("input.OnotStatDeleted");
        var jqOcalcAllRevs = ccv.domJQ.OPTIONS.find("input.OcalcAllRevs");
        var jqOgenGraph = ccv.domJQ.OPTIONS.find("input.OgenGraph");
        var jqOstatBinLines = ccv.domJQ.OPTIONS.find("input.OstatBinLines");
        
        //options for svn module
        var jqOSvnWithLoc = ccv.domJQ.OPTIONS.find("input.OSvnWithLoc");
        var jqOdfIgnoreEOL = ccv.domJQ.OPTIONS.find("input.OdfIgnoreEOL");
    	
    	var opts = {
			OgenGraph: 0, 
			OcalcAllRevs: 0,
			OstatBin: 0,
			OstatBinLines: 0, 
			OnotStatDeleted: 0,
			OSvnWithLoc: 1,
			OdfIgnoreEOL: 0
    	};
   	
    	if (pms.mode == "log" || pms.mode == "diff") {
        	if (jqOgenGraph[0].checked) {
        		opts.OgenGraph = 1;
        	}    	    
    		if (!pms.revs || pms.revs.toUpperCase() == 'HEAD' || pms.revs.toUpperCase() == 'MAIN') {
    			if (jqOcalcAllRevs[0].checked) {
    				opts.OcalcAllRevs = 1;
    			}
    		}
    		if (jqOstatBin[0].checked) {
    			opts.OstatBin = 1;
    		}
    		if (jqOstatBinLines[0].checked) {
    			opts.OstatBinLines = 1;
    		}	
    		if (jqOnotStatDeleted[0].checked) {
    			opts.OnotStatDeleted = 1;
    		}
 
    		if (jqOdfIgnoreEOL[0].checked) {
    			opts.OdfIgnoreEOL = 1;
    		}    			    			    									
    	}
    	
    	return opts;
    },
    
    getFilterInfo: function() {
    	var jqFileInclude = ccv.domJQ.OPTIONS.find("input.fileInclude");
    	var jqFileExclude = ccv.domJQ.OPTIONS.find("input.fileExclude");
    	var jqDirInclude = ccv.domJQ.OPTIONS.find("input.dirInclude");
    	var jqDirExclude = ccv.domJQ.OPTIONS.find("input.dirExclude");
		
		return {
			includeExts: jqFileInclude.val(),
			excludeExts: jqFileExclude.val(),	
			includeDirs: jqDirInclude.val(),
			excludeDirs: jqDirExclude.val()
    	};
    },
    
    constructPMs: function() {
        var cfg = ccv.domJQ.CFG_SELECT.val();
        var revs 	= ccv.domJQ.REVS.val();
        var dates 	= ccv.domJQ.DATES.val();
        var wids 	= ccv.domJQ.WIDS.val();
        var rev1 	= ccv.domJQ.REV1.val();
        var rev2 	= ccv.domJQ.REV2.val();
        var date1 	= ccv.domJQ.DATE1.val();
        var date2 	= ccv.domJQ.DATE2.val();
        var fileRev = ccv.domJQ.FILE_REV.val();
    	
        if (ccv.domJQ.DIFF.find("input.diffAgainst:checked").val() == "revisions") {
        	date1 = "";	
        	date2 = "";
        } else {
        	rev1 = "";
        	rev2 = "";
        }	
    
        
        var pms = {};
        pms.cmd = "GENERATE";
        pms.mode = ccv.domJQ.USER_ACTIONS.find("input.radioMode:checked").val();
        
        var opts = ccv.fn.getOptions(pms);
        var checkedModules = '';
        jQuery.each(ccv.domJQ.MODULES.find("input.chkAnchor[checked='checked'][value!='']"), function(index, item) {
			checkedModules += item.value + ",";        		
        });
         
    	checkedModules = checkedModules.replace(/,$/, '');
    	    
        pms.cfg 	= cfg;
        pms.mids 	= checkedModules;
        
        if (ccv.vars.counterUseRuntimeAccount) {
	        pms.uid = ccv.domJQ.ACCOUNT_ID.val();
	        pms.upw	= ccv.domJQ.ACCOUNT_PW.val();
        } else {
	        pms.uid = '';
	        pms.upw	= '';
        }

    	pms.opts = opts;
        
    	if (pms.mode == "log") {
    		pms.rev = (!revs || revs.toUpperCase() == 'HEAD') ? 'MAIN' : revs;
    		pms.date = dates;
    		pms.wids = wids;
    	} else if (pms.mode == "diff"){
    		pms.r1 = rev1;
    		pms.r2 = rev2;
    		pms.d1 = date1;
    		pms.d2 = date2;
    		
    		var info = ccv.fn._getBranchRevsDatesBased();
    		var validRet = ccv.fn._checkSvnDfPmsValid(pms, info);
    		
    		if (validRet == 0) {
    			jQuery.extend(pms, info);
    		} else {
    			return validRet;	
    		}	
    	} else if (pms.mode == "file") {
    		pms.rev = fileRev;
    	}
    	
		pms.filter = ccv.fn.getFilterInfo();
    	
    	return pms;
    },
    
    _checkSvnDfPmsValid: function(pms, info) {
    	if (info.rd1b == "trunk" && info.rd2b == "trunk") {
    		return "Can not diff between trunk and trunk!";
    	}
    	
		if (info.rd1b == "OnBranch" && !info.bb) {
			return "If r1/r2 are on branch, branch name must be provided!";
		}
    		    	
    	if (info.dfAgainst == "revs") {
    		if (info.rd1b == "OnBranch" || info.rd1b == "OnTrunk") {
    			if (!pms.r1 || !pms.r2 || isNaN(pms.r1) || isNaN(pms.r2)) {
    				return "r1/r2 must be a revison number when they are on branch/trunk!";
    			}
    		}
    	}
    	
    	return 0;
    },
    
    _getBranchRevsDatesBased: function() {
    	var info = {
    		dfAgainst: "",
    		rd1b: "", //rev1/date1 base on
    		rd2b: "", //rev2/date2 base on
    		bb: ""//branch name which revs/dates based on 
    	};
    	
    	if (ccv.domJQ.RADIO_DIFF_AGAINST.filter(':checked').val() == "revisions") {
    		info.dfAgainst = "revs";
    		info.rd1b = ccv.domJQ.SVN_REV_BASE.filter(".svnRev1Base").val();  
    		info.rd2b = ccv.domJQ.SVN_REV_BASE.filter(".svnRev2Base").val();
    		
    		if (info.rd1b == "OnBranch") {
    			info.bb = ccv.domJQ.DIFF.find("input.branchRevsBasedOn").val();
    		}
    	} else {
    		info.dfAgainst = "dates";
    		info.rd1b = ccv.domJQ.SVN_REV_BASE.filter(".svnDate1Base").val();  
    		info.rd2b = ccv.domJQ.SVN_REV_BASE.filter(".svnDate2Base").val();    		
    		
    		if (info.rd1b == "OnBranch") {
    			info.bb = ccv.domJQ.DIFF.find("input.branchDatesBasedOn").val();
    		}    		
    	}
    	
    	return info;
    },
    
    listenProgress: function() {
    	ccv.fn.wapi(
    		{
			    cmd: "GET_PROGRESS",
				T_SNAP: ccv.progress.T_SNAP,
				rnd:  Math.random()    			
    		},
    		
    		function(ret){//success
    			ccv.fn.cbProgress(ret);
    		},
    		
			function() {//error
			    ccv.fn.resetProgress();
				alert("time out");
			}    		
    	);
    },
    
    cbProgress: function(ret) {
        var content = ret.content;
    	if (ret.flagEnd) {
            ccv.fn.resetProgress(true);
    		ccv.domJQ.HISTORY.attr("src", ccv.domJQ.HISTORY.attr("src") +  "?rnd=" + Math.random());        
    		ccv.domJQ.PROGRESS.html(content);
    	} else {
    		var len = content.length;
    		if (len > ccv.progress.retLength) {
    			ccv.progress.times = 0;
    			ccv.progress.retLength = len;
    			ccv.domJQ.PROGRESS.html(content);
    		} else {
    			if (ccv.progress.times % ccv.progress.TimesBatchCnt == 0 ) {
    			    ccv.domJQ.PROGRESS.html(content + '<span class="queryBatchTimesNo">' + (ccv.progress.times / ccv.progress.TimesBatchCnt + 1) + '</span> ');
    			}
    			ccv.progress.times ++;
    			ccv.domJQ.PROGRESS.html(ccv.domJQ.PROGRESS.html() + "...");    
    		}
    	}
    	
    	ccv.domJQ.PROGRESS.scrollTop(ccv.domJQ.PROGRESS[0].scrollHeight);
    }, 
    
    resetProgress: function(/*boolean*/ keepProgressInfo) {
        if (!keepProgressInfo) {
            ccv.domJQ.PROGRESS.html("");
        }
        
       clearInterval(ccv.progress.interval);    
        ccv.progress.interval = 0;
        ccv.progress.retLength = 0;
        ccv.progress.times = 0;
    },  
    
    runGenerate: function(pms) {
        ccv.fn.resetProgress();
        
        ccv.domJQ.PROGRESS.text("");
        ccv.domJQ.DLG_PROGRESS.dialog('open');

    	ccv.fn.wapi(
    		pms,
    		
    		function(ret){//success
    			ccv.fn.setRuntimeAccountCookie(pms);
    			
          	    ccv.progress.T_SNAP = ret.T_SNAP;
                ccv.progress.interval = setInterval(function() {
                    ccv.fn.listenProgress();
                }, 2000); 
    		},
    		
			function() {//error
                ccv.fn.resetProgress();
                alert("Error");  
			}    		
    	);
    },
    
    existSelectedUseRuntimeAccount: function(mids) {
    	var ids = mids.split(',');
    	for (var i = 0; i < ccv.vars.modules.length; i++) {
    		var m = ccv.vars.modules[i];
				
    		if (ids.indexOf(m.id) != -1 && m.useRuntimeAccount == '1') {
    			return true;
    		}
    	}
    	
    	return false;
    }
};

