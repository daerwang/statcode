ccv.bot = {
	
	BOT_INFO_JSON_FILE_URI: '/ccv/bot.info.json',
	
	QUERIED_REVS_INFO_JSON_FILE_URI: '/ccv/queried.revs.info.json',
	
	existBotInfo: 0,
	
	emptyBotedInfo: {
		xmlsReposURIs: {},
		reposURIRevsInfo: {}
	},
	
	emptyQueriedInfo: {
		revsInfo: {},
		revs: []
	},
	
	botedInfo: null,
	
	queriedInfo: null,
	
	revs: null,
	
	getBotedInfo: function() {
		var self = this;
		jQuery.ajax({
			url: this.BOT_INFO_JSON_FILE_URI,
			dataType: 'json',
			
			// json.xmlsReposURIs
			// json.reposURIRevsInfo
			success: function(ret) {
				ccv.bot.existBotInfo = 1;
				ccv.bot.botedInfo = ret;
				self.getQueriedInfo();
			},
			error: function() {
				ccv.bot.existBotInfo = 0;
				ccv.bot.botedInfo = self.emptyBotedInfo;
				self.getQueriedInfo();
			}
		});
	},
	
	getQueriedInfo: function() {
		var self = this;
		
		jQuery.ajax({
			url: this.QUERIED_REVS_INFO_JSON_FILE_URI,
			dataType: 'json',
			
			// json.revsInfo
			// json.revs
			success: function(ret) {
				ccv.bot.queriedInfo = ret;
				self.switchCfgAvailableRevs(ccv.domJQ.CFG_SELECT.val(), 'branches');
				ccv.ac.updateSource();
			},
			error: function() {
				ccv.bot.queriedInfo = self.emptyQueriedInfo;
				self.switchCfgAvailableRevs(ccv.domJQ.CFG_SELECT.val(), 'branches');
				ccv.ac.updateSource();
			}
		});
	},
	
	getCfgAvailableRevsFromBotedInfo: function(cfg, flag) {
		if (!ccv.bot.existBotInfo) {
			return null;
		}
		
		var xmlReposURIs = ccv.bot.botedInfo.xmlsReposURIs[cfg];
		if (!xmlReposURIs || xmlReposURIs.length == 0) {
			return null;
		}
		
		var revs = [];
		// json.xmlsReposURIs
		// json.reposURIRevsInfo
		var reposURIRevsInfo = ccv.bot.botedInfo.reposURIRevsInfo; 	
		for (var i = 0; i < xmlReposURIs.length; i++) {
			var uri = xmlReposURIs[i];
			if (!reposURIRevsInfo[uri]) {
				continue;
			}
			
			if (flag == 'branches') {
				if (reposURIRevsInfo[uri].branches.length) {
					revs = revs.concat(reposURIRevsInfo[uri].branches);	
				}
			} else
			if (flag == 'tags') {
				if (reposURIRevsInfo[uri].tags.length) {
					revs = revs.concat(reposURIRevsInfo[uri].tags);	
				}				
			} else {
				if (reposURIRevsInfo[uri].branches.length) {
					revs = revs.concat(reposURIRevsInfo[uri].branches);	
				}				
				if (reposURIRevsInfo[uri].tags.length) {
					revs = revs.concat(reposURIRevsInfo[uri].tags);	
				}
			}			
		}
		
		return revs;		
	},
	
	getCfgAvailableRevsFromQueriedInfo: function() {
		// json.revsInfo
		// json.revs
		var revs = ccv.bot.queriedInfo.revs;
		if (revs && revs.length) {
			return revs;
		} else {
			return null;	
		}
	},
	
	removeIlegalRev: function() {
		var legalRev = /^[\w\d\-_\.]+$/i;
		
		var cnt = this.revs.length;
		for (var i = 0; i < cnt; i++) {
			if (!legalRev.test(this.revs[i])) {
				this.revs.splice(i, 1);
				cnt--;
				i--;
			}
		}
	},
		
	switchCfgAvailableRevs: function(cfg, flag) {
		var botedRevsInfo = this.getCfgAvailableRevsFromBotedInfo(cfg, flag);
		if (!botedRevsInfo || botedRevsInfo.length == 0) {
			this.revs = this.getCfgAvailableRevsFromQueriedInfo();
		} else {
			this.revs = botedRevsInfo;			
		}
		
		if (!this.revs) {
			this.revs = [];
		}
		
		this.revs.push('TRUNK');	
		this.removeIlegalRev();
		this.revs = this.revs.uniqueSort();
	}	
};
