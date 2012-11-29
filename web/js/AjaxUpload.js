/**
 * AJAX Upload
 * Project page - http://valums.com/ajax-upload/
 * Copyright (c) 2008 Andris Valums, http://valums.com
 * Licensed under the MIT license (http://valums.com/mit-license/)
 * 
 * 
 * lilongen:
 * 1. change ajaxupload & ajaxupload base function namespace from global to ccv namespace
 * 2. change input dom dynamically locate to static locate, make it work in FF3.6, and better work on IE7
 */
ccv.AjaxUpload = function(jqBtnBrowse, options){
	this._input = null;
	this._iframe = null;
	this._form = null;
	this._blockdiv = null;
	this._button = jqBtnBrowse[0];
	this._disabled = false;
	this._submitting = false;
	// Variable changes to true if the button was clicked
	// 3 seconds ago (requred to fix Safari on Mac error)
	this._justClicked = false;
	this._parentDialog = document.body;
	
	this._inputCoord = {left: 0, top: 0, width: 0, height: 0};
	
	/*
	if (window.jQuery && jQuery.ui && jQuery.ui.dialog){
		var parentDialog = jQuery(this._button).parents('.ui-dialog');
		if (parentDialog.length){
			this._parentDialog = parentDialog[0];
		}
	}
	*/			
					
	this._settings = {
		// Location of the server-side upload script
		action: 'upload.php',
		// input file id
		id: 'file1',			
		// File upload name
		name: 'userfile',
		// Additional data to send
		data: {},
		// Submit file as soon as it's selected
		autoSubmit: true,
		// The type of data that you're expecting back from the server.
		// Html and xml are detected automatically.
		// Only useful when you are using json data as a response.
		// Set to "json" in that case. 
		responseType: false,
		// Location of the server-side script that fixes Safari 
		// hanging problem returning "Connection: close" header
		closeConnection: '',
		// Class applied to button when mouse is hovered
		hoverClass: 'hover',		
		// When user selects a file, useful with autoSubmit disabled			
		onChange: function(file, extension){},					
		// Callback to fire before file is uploaded
		// You can return false to cancel upload
		onSubmit: function(file, extension){},
		// Fired when file upload is completed
		// WARNING! DO NOT USE "FALSE" STRING AS A RESPONSE!
		onComplete: function(file, response) {}
	};

	// Merge the users options with our defaults
	for (var i in options) {
		this._settings[i] = options[i];
	}
	
	this._createInput();
	this._createBlockDiv();
	
	this.layoutAll();
};
			
// assigning methods to our class
ccv.AjaxUpload.prototype = {
	setData : function(data){
		this._settings.data = data;
	},
	disable : function(){
		this._disabled = true;
	},
	enable : function(){
		this._disabled = false;
	},
	// removes instance
	destroy : function(){
		if(this._input){
			if(this._input.parentNode){
				this._input.parentNode.removeChild(this._input);
			}
			this._input = null;
		}
	},
	
	_createBlockDiv: function() {
		var _this = this;
		jQuery(document.body).append('<div class="ccv_profile_photo_blockUnwantedFilePart"></div>');
	},
	/**
	 * Creates invisible file input above the button 
	 */
	_createInput : function(){
		var self = this;
		var input = document.createElement("input");
		input.setAttribute('type', 'file');
		input.setAttribute('name', this._settings.name);
		input.setAttribute('id', this._settings.id);
		input.setAttribute('hideFocus', 'true');
		input.setAttribute('ACCEPT', "image/jpg,image/jpeg,image/gif,image/png,image/bmp"); //#Added personal, but it can not work in FF3
		
		var styles = {
			'position' 	: 'absolute',
			'height'	: '20px',
			'fontSize': '14px',
			'opacity'	: 0,
			'display' 	: 'block',
			'zIndex' 	:  9998 //Max zIndex supported by Opera 9.0-9.2x 
			// Strange, I expected 2147483647
			// Doesn't work in IE :(
			//,'direction' : 'ltr'			
		};
		
		for (var i in styles){
			input.style[i] = styles[i];
		}
		
		// Make sure that element opacity exists
		// (IE uses filter instead)
		if ( ! (input.style.opacity === "0")){
			input.style.filter = "alpha(opacity=0)";
		}
//		input.style.filter = "alpha(opacity=100)";
							
		this._parentDialog.appendChild(input);

		ccv.AjaxUpload.base.addEvent(input, 'change', function(){
			// get filename from input
			var file = ccv.AjaxUpload.base.fileFromPath(this.value);	
			if(self._settings.onChange.call(self, file, ccv.AjaxUpload.base.getExt(file)) == false ){
				return;				
			}														
			// Submit form when value is changed
			if (self._settings.autoSubmit){
				self.submit();						
			}						
		});
		
		// Fixing problem with Safari
		// The problem is that if you leave input before the file select dialog opens
		// it does not upload the file.
		// As dialog opens slowly (it is a sheet dialog which takes some time to open)
		// there is some time while you can leave the button.
		// So we should not change display to none immediately
		ccv.AjaxUpload.base.addEvent(input, 'click', function(e){
			self._justClicked = true;
			setTimeout(function(){
				// we will wait 3 seconds for dialog to open
				self._justClicked = false;
			}, 2500);			
		});	
		
		this._input = input;
	},
	
	getInputCoord: function() {
		var inputOffset = jQuery(this._input).offset();
		this._inputCoord.left = inputOffset.left;
		this._inputCoord.top = inputOffset.top;
		this._inputCoord.width = this._input.offsetWidth;
		this._inputCoord.height = this._input.offsetHeight;			
	},
	
	layoutAll: function() {
		this.getInputCoord();
		var inputOffset = this.layoutInput();
		this.layoutBlockDiv(inputOffset);
	},
	
	showInput: function(show) {
		if (show) {
			jQuery(this._input).show();
			jQuery(this._blockdiv).show();			
		} else {
			jQuery(this._input).hide();
			jQuery(this._blockdiv).hide();
		}
	},
	
	layoutInput: function() {
		var offset = jQuery(this._button).offset();
		var inputTop = offset.top;
		var inputLeft = offset.left - this._inputCoord.width + this._button.offsetWidth;		
		
		this._input.style.top = inputTop + 'px';
		this._input.style.left = inputLeft + 'px';
		
		return {left: inputLeft, top: inputTop};
	},
	
	layoutBlockDiv: function(inputOffset) {
		if (this._blockdiv && (typeof this._blockdiv === 'object')) {
			this._blockdiv.css({
				top: (inputOffset.top - 1),
				left: (inputOffset.left - 1),
				width: (this._inputCoord.width - this._button.offsetWidth),
				height: (this._inputCoord.height + 2)
			});				
		}		
	},

	/**
	 * Creates iframe with unique name
	 */
	_createIframe : function(){
		// unique name
		// We cannot use getTime, because it sometimes return
		// same value in safari :(
		var id = ccv.AjaxUpload.base.getUID();
		
		// Remove ie6 "This page contains both secure and nonsecure items" prompt 
		// http://tinyurl.com/77w9wh
		var iframe = ccv.AjaxUpload.base.toElement('<iframe src="javascript:false;" name="' + id + '" />');
		iframe.id = id;
		iframe.style.display = 'none';
		document.body.appendChild(iframe);	
		this._iframe = iframe;	
		return iframe;						
	},
	/**
	 * Upload file without refreshing the page
	 */
	submit : function(){
		var self = this, settings = this._settings;	
					
		if (this._input.value === ''){
			// there is no file
			return;
		}
										
		// get filename from input
		var file = ccv.AjaxUpload.base.fileFromPath(this._input.value);			

		// execute user event
		if (! (settings.onSubmit.call(this, file, ccv.AjaxUpload.base.getExt(file)) == false)) {
			// Create new iframe for this submission
			var iframe = this._createIframe();
			
			// Do not submit if user function returns false										
			var form = this._createForm(iframe);
			form.appendChild(this._input);

			// A pretty little hack to make uploads not hang in Safari. Just call this
			// immediately before the upload is submitted. This does an Ajax call to
			// the server, which returns an empty document with the "Connection: close"
			// header, telling Safari to close the active connection.
			// http://blog.airbladesoftware.com/2007/8/17/note-to-self-prevent-uploads-hanging-in-safari
			if (settings.closeConnection && /AppleWebKit|MSIE/.test(navigator.userAgent)){
				var xhr = ccv.AjaxUpload.base.getXhr();
				// Open synhronous connection
				xhr.open('GET', settings.closeConnection, false);
				xhr.send('');
			}
			
			form.submit();
			
			document.body.removeChild(form);				
			form = null;
			this._form = null;
			this._input = null;
			
			// create new input
			this._createInput();
			this.layoutAll();
			
			var toDeleteFlag = false;
			
			ccv.AjaxUpload.base.addEvent(iframe, 'load', function(e){
					
				if (// For Safari
					iframe.src == "javascript:'%3Chtml%3E%3C/html%3E';" ||
					// For FF, IE
					iframe.src == "javascript:'<html></html>';"){						
					
					// First time around, do not delete.
					if( toDeleteFlag ){
						// Fix busy state in FF3
						setTimeout( function() {
							document.body.removeChild(iframe);
							this._iframe = null;
						}, 0);
					}
					return;
				}				
				
				var doc = iframe.contentDocument ? iframe.contentDocument : frames[iframe.id].document;

				// fixing Opera 9.26
				if (doc.readyState && doc.readyState != 'complete'){
					// Opera fires load event multiple times
					// Even when the DOM is not ready yet
					// this fix should not affect other browsers
					return;
				}
				
				// fixing Opera 9.64
				if (doc.body && doc.body.innerHTML == "false"){
					// In Opera 9.64 event was fired second time
					// when body.innerHTML changed from false 
					// to server response approx. after 1 sec
					return;				
				}
				
				var response;
									
				if (doc.XMLDocument){
					// response is a xml document IE property
					response = doc.XMLDocument;
				} else if (doc.body){
					// response is html document or plain text
					response = doc.body.innerHTML;
					if (settings.responseType && settings.responseType.toLowerCase() == 'json'){
						// If the document was sent as 'application/javascript' or
						// 'text/javascript', then the browser wraps the text in a <pre>
						// tag and performs html encoding on the contents.  In this case,
						// we need to pull the original text content from the text node's
						// nodeValue property to retrieve the unmangled content.
						// Note that IE6 only understands text/html
						if (doc.body.firstChild && doc.body.firstChild.nodeName.toUpperCase() == 'PRE'){
							response = doc.body.firstChild.firstChild.nodeValue;
						}
						if (response) {
							response = window["eval"]("(" + response + ")");
						} else {
							response = {};
						}
					}
				} else {
					// response is a xml document
					var response = doc;
				}
																			
				settings.onComplete.call(self, file, response);
						
				// Reload blank page, so that reloading main page
				// does not re-submit the post. Also, remember to
				// delete the frame
				toDeleteFlag = true;
				
				// Fix IE mixed content issue
				iframe.src = "javascript:'<html></html>';";		 								
			});
	
		} else {
			// clear input to allow user to select same file
			// Doesn't work in IE6
			// this._input.value = '';
			document.body.removeChild(this._input);				
			this._input = null;
			
			// create new input
			this._createInput();
			this.layoutAll();						
		}
	},		
	/**
	 * Creates form, that will be submitted to iframe
	 */
	_createForm : function(iframe){
		var settings = this._settings;
		
		// method, enctype must be specified here
		// because changing this attr on the fly is not allowed in IE 6/7		
		var form = ccv.AjaxUpload.base.toElement('<form method="post" enctype="multipart/form-data"></form>');
		form.style.display = 'none';
		form.action = settings.action;
		form.target = iframe.name;
		document.body.appendChild(form);
		
		// Create hidden input element for each data key
		for (var prop in settings.data){
			if (prop == 'id') {
				continue;
			}
			
			var el = document.createElement("input");
			el.type = 'hidden';
			el.name = prop;
			el.value = settings.data[prop];
			form.appendChild(el);
		}	
		this._form = form;
				
		return form;
	},
	
	removeAll: function() {
		try {
			if (this._blockdiv && (typeof this._blockdiv === 'object')) {
				this._blockdiv.remove();
				this._blockdiv = null;
			}			
			if (this._input && (typeof this._input === 'object')) {
				document.body.removeChild(this._input);
				this._input = null;
			}
//			if (this._form && (typeof this._form === 'object')) {
//				document.body.removeChild(this._form);
//				this._form = null;
//			}
//			if (this._iframe && (typeof this._iframe === 'object')) {
//				document.body.removeChild(this._iframe);
//				this._iframe = null;
//			}	
		}catch(e){
			return;
		}
			
	}
};



/**
 * following are base functions needed by AjaxUpload
 * 
 * Changed by micro, for namespace alteration
 * 
 */
ccv.AjaxUpload.base = {
	/**
	 * Attaches event to a dom element
	 */
	addEvent: function(el, type, fn){
		if (window.addEventListener){
			el.addEventListener(type, fn, false);
		} else if (window.attachEvent){
			var f = function(){
			  fn.call(el, window.event);
			};			
			el.attachEvent('on' + type, f)
		}
	},
	
	
	/**
	 * Creates and returns element from html chunk
	 */
	toElement: function(html){
		var div = document.createElement('div');
		div.innerHTML = html;
		var el = div.childNodes[0];
		div.removeChild(el);
		
		return el;
	},

	getBox: function(el){
		var left, right, top, bottom;	
		var offset = jQuery(el).offset();
		left = offset.left;
		top = offset.top;
							
		right = left + el.offsetWidth;
		bottom = top + el.offsetHeight;		
			
		return {
			left: left,
			right: right,
			top: top,
			bottom: bottom
		};
	},
	
	/**
	 * Function generates unique id
	 */		
	getUID: function(){
		var id = 0;
		return function(){
			return 'ValumsAjaxUpload' + id++;
		}();
	},
	
	fileFromPath: function(file){
		return file.replace(/.*(\/|\\)/, "");			
	},
	
	getExt: function(file){
		return (/[.]/.exec(file)) ? /[^.]+$/.exec(file.toLowerCase()) : '';
	},			
	
	/**
	 * Cross-browser way to get xhr object  
	 */
	getXhr: function(){
		var xhr;
		
		return function(){
			if (xhr) return xhr;
					
			if (typeof XMLHttpRequest !== 'undefined') {
				xhr = new XMLHttpRequest();
			} else {
				var v = [
					"Microsoft.XmlHttp",
					"MSXML2.XmlHttp.5.0",
					"MSXML2.XmlHttp.4.0",
					"MSXML2.XmlHttp.3.0",
					"MSXML2.XmlHttp.2.0"					
				];
				
				for (var i=0; i < v.length; i++){
					try {
						xhr = new ActiveXObject(v[i]);
						break;
					} catch (e){}
				}
			} 			
	
			return xhr;
		}();
	}
};