ccv.util = {
	addClassInfo2Body: function() {
		var clz = jQuery.browser.msie ? "ie" : jQuery.browser.mozilla ?  "firefox" : jQuery.browser.chrome ?  "chrome" : jQuery.browser.safari ?  "safari" : ""; 
		if (clz) {
			var ver = Math.floor(jQuery.browser.version);
			jQuery(document.body).addClass(clz).addClass(clz + ver);
		}
	},
	
	escapeHtml: function(str, escapeSpace) {
		str = str.replace(/&/gm, "&amp;").replace(/</gm, "&lt;").replace(/>/gm, "&gt;");
		if (escapeSpace) {
			str = str.replace(/\s/g, "&nbsp;");
		}
		
		return str;
	},
	
	createEditor: function() {
		if (!ccv.vars.editor) {
			ccv.vars.editor = CodeMirror.fromTextArea(ccv.domJQ.DLG_EDIT.find("textarea.editor")[0], {
				mode: {name: "xmlpure"},
				lineNumbers: true
			});
		}	
	},
	
	isXmlFileNameAvailable: function(fileName) {
		for (var i = 0; i < ccv.xmlFiles.length; i++) {
			if (ccv.xmlFiles[i] == fileName) {
				return false;
			}
		}
		
		return true;
	},
	
	/**
	 * example:
	 *   format('%1 %2', 1111, '2222');
	 *   format('hello %1 %2 %3 %4 %5', 1111, '2222', 3, 4, '55555');
	 */
	sprintf: function(string){
		var args = arguments;
		var pattern = new RegExp("%([1-" + args.length + "])", "g");
		return String(string).replace(pattern, function(match, index){
		    return args[index];
		});
	},
	
	counterCcv: function(pms) {
		var reportMode = (pms.cmd == "GET_OVERALL" ? "any" : pms.mode);
		var url = ccv.util.sprintf(ccv.opts.COUNTER[ccv.opts.MODE], pms.cmd, reportMode, Math.random());
		ccv.domJQ.COUNTER.attr("src", url);
	}
};
