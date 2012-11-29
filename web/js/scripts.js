function showhide(el){
  el.getElementsByTagName("ul")[0].style.display=(el.getElementsByTagName("ul")[0].style.display=="block")?"none":"block";
  el.getElementsByTagName("span")[0].style.backgroundImage=(el.getElementsByTagName("ul")[0].style.display=="block")?"url('../../../img/minus.png')":"url('../../../img/plus.png')";
}

function expandAll(shown) {
	var obj = document.getElementById("containerul");
	
	var lis = obj.getElementsByTagName("li");
	var lisCnt = lis.length;
	for(var index = 0; index < lisCnt; index++) {
		var objULs = lis[index].getElementsByTagName("ul");
		var cntUL = objULs.length;
		for (var j = 0; j < cntUL; j++) {
			objULs[j].style.display = shown ? "block" : "none";
		}
	}
	
	var spans = obj.getElementsByTagName("span");
	var spansCnt = spans.length;
	
	for(var index = 0; index < spansCnt; index++) {
		var objSpan = spans[index];
		if (objSpan.id == 'plus' || objSpan.id == 'minus') {
			objSpan.style.backgroundImage	= shown ? "url('../../../img/minus.png')" : "url('../../../img/plus.png')";		
		}
	}	
}