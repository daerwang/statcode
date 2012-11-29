var ccv = {};

ccv.opts = {
	MODE: -1,
	COUNTER: [
		"http://ccv.sourceforge.net/cgi-bin/counter.py?type=%1&mode=%2&rnd=%3"
	]
};

ccv.def = {
    CK_CFG: "CK_CFG",
    CK_RUNTIME_ACCOUNT: 'CK_RUNTIME_ACC_'
};

ccv.vars = {
	msgInterval: 0,
	modules: null,
	editor: null,
	cfgModuleWidthComplement: -1,
	counterUseRuntimeAccount: 0,
	
	resetUseRuntimeAccount: function() {
        ccv.vars.counterUseRuntimeAccount = 0;
	}
};

ccv.progress = {
    TimesBatchCnt: 30,
    T_SNAP: '',
    interval: 0,
    retLength: 0,
    times: 0
};

ccv.nls = {
	cfg: {
		xmlPwdHint: "Input write-protect password"	
	},
	
	action: {
		
		
	},
	
	brand: {
		
	}
};
