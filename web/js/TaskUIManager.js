var ccv = ccv || {};

ccv.TaskUIManager = ccv.TaskUIManager || function(){};

jQuery.extend(ccv.TaskUIManager.prototype, {
	
	_jqTray: null,
	
	_jqQueue: null,
	
	_jqTasks: null,
	
	_tasksCnt: 0,
	
	_tasks: {},
	
	_cb4ClickTaskItem: null,
	
	_trayWinkTimerId: 0,
	
	_winkTrayFlag: false,
	
	addQueueAnchor: function(taskQueue, cb4ClickTaskItem) {
		if (taskQueue.jquery) {
			this._jqQueue = taskQueue;
		} else {
			this._jqQueue = jQuery(taskQueue);
		}
		
		this._jqTasks = this._jqQueue.find('li');
		this._cb4ClickTaskItem = cb4ClickTaskItem;

		this._jqTasks.click(function() {
			alert(100);
							
		});
	},
	
	addTrayAnchor: function(taskTray) {
		var self = this;
		if (taskTray.jquery) {
			this._jqTray = taskTray;
		} else {
			this._jqTray = jQuery(taskTray);
		}
		
		this.disableTray();
		
				
		this._jqTray.click(function() {
			if (self.isQueueHide()) {
				self._jqQueue.show();
			} else {
				self._jqQueue.hide();
			}
		});
	},	
	
	
	/**
	 * task queue functions
	 */
	showQueue: function() {
		this._jqQueue.show();
	},
	
	hideQueue: function() {
		this._jqQueue.hide();
	},
	
	addTask: function(taskKey, content) {
		for (var i = 0; i < this._jqTasks.length; i++) {
			var jqTask = this._jqTasks.eq(i);
			if (jqTask.css('display') == 'none') {
				jqTask.addClass(taskKey);
				jqTask.html(content);
				jqTask.show();
				
				this._tasks[taskKey] = {content: content, wink: false};
				
				this.enableTray();
				break;
			}
		}
	},
	
	isTasksLimitReached: function() {
		var limitReached = true;
		for (var i = 0; i < this._jqTasks.length; i++) {
			var jqTask = this._jqTasks.eq(i);
			if (jqTask.css('display') == 'none') {
				limitReached = false;
				
			}
		}
		
		return limitReached;
	},
		
	removeTask: function(taskKey) {
		this.removeWinkTask(taskKey);

		this._tasksCnt --;
		this._jqQueue.find('.' + taskKey).hide().removeClass(taskKey);
		
		if (this._tasks[taskKey]) {
			delete this._tasks[taskKey];
			
			var isNoTask = true;
			for (var key in this._tasks) {
				isNoTask = false;
				break;
			}
			
			if (isNoTask) {
				this.disableTray();
			}
		}
	},
	
	addWinkTask: function(taskKey) {
		if (this._tasks[taskKey]) {
			this._tasks[taskKey].wink = true;
		}
		var jqWinkTask = this._jqQueue.find('.' + taskKey);
		
		if (!jqWinkTask.length || jqWinkTask.css('display') == 'none') {
			return;
		}
		
		jqWinkTask.addClass('taskTrayWink');		
		
		if (!this._winkTrayFlag) {
			this.winkTray();
		}
		
	},
	
	removeWinkTask: function(taskKey) {
		if (this._tasks[taskKey]) {
			this._tasks[taskKey].wink = false;
		}
		
		var jqWinkTask = this._jqQueue.find('.' + taskKey);
				
		jqWinkTask.removeClass('taskTrayWink');			
		var winkTasks = this.getWinkTasks();
		if (!winkTasks) {
			this.unWinkTray();	
		}	
	},
	
	getWinkTasks: function() {
		var winkTasks = "";
		
		for (taskKey in this._tasks) {
			if (this._tasks[taskKey].wink) {
				winkTasks += "li." + taskKey + ',';
			}
		}
		
		return winkTasks.replace(/,$/, '');
	},

	isQueueHide: function() {
		return 	this._jqQueue.css('display') == 'none';
	},



	/**
	 * task tray functions
	 */
	winkTray: function() {
		var self = this;
		this._trayWinkTimerId = setInterval(function() {
			self._jqTray.addClass('trayWink');
			setTimeout(function() {
				self._jqTray.removeClass('trayWink');
			}, 300);
						
		}, 800);
		
		this._winkTrayFlag = true;
		
	},
	
	unWinkTray: function() {
		if (this._trayWinkTimerId) {
			clearInterval(this._trayWinkTimerId);
			this._trayWinkTimerId = 0;
		}
		
		this._winkTrayFlag = false;
	},
	
	disableTray: function() {
		this._jqTray.addClass('taskTrayDisabled');
		this._jqTray.attr('disabled', true);
	},
	
	enableTray: function() {
		console.log('enable tray!!');
		this._jqTray.removeClass('taskTrayDisabled');
		this._jqTray.attr('disabled', false);		
	}	 
});

