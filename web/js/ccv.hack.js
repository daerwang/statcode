ccv.hack = {};

ccv.hack.fixIeArrayIndexOf = function () {
	if (!Array.prototype.indexOf) {
		Array.prototype.indexOf = function(obj, start) {
			for (var i = (start || 0), j = this.length; i < j; i++) {
				if (this[i] === obj) { return i; }
			}
			return -1;
		};
	}
}();
	
ccv.hack.uniqueSortArray = function() {
	if (!Array.prototype.uniqueSort) {
		Array.prototype.uniqueSort = function(){
			var u = {}, a = [];
			for (var i = 0, l = this.length; i < l; i++){
				if(u.hasOwnProperty(this[i])) {
					continue;
				}
				a.push(this[i]);
				u[this[i]] = 1;
			}
			
			return a;
		};
	}
}();
