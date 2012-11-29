function showChildren(dom){
	var domUL = dom.parentNode.getElementsByTagName("ul")[0];
	var cssDisplay = domUL.style.display == "block" ? "none" : "block";
	domUL.style.display = cssDisplay;
	dom.style.backgroundImage = (cssDisplay == "block" ? "url(/ccv/img/minus.png)" : "url(/ccv/img/plus.png)");
}

function expandAll(shown) {
	var obj = document.getElementById("dfTree");
	
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
		if (objSpan.className == 'plus' || objSpan.className == 'minus') {
			objSpan.style.backgroundImage	= shown ? "url('/ccv/img/minus.png')" : "url('/ccv/img/plus.png')";		
		}
	}	
}

function getFileFullUrl(file) {
    return "/ccv/" + GV.InitRevFileLocation + file.substring(GV.InPathPrefix4CoPathsLen);
}

function showDiff(file, rev, offsetB, offsetE, revAction) {
	if (GV.InPathPrefix == GV.RevFullPath) {
		file = file.substr(GV.RevFullPath.length - GV.RevFullPathWithoutRepos.length);
	}
	
	var url = "";
    if (!GV.WithLoc || "0" == GV.WithLoc) {
    	var AT = (rev == GV.InitRev || revAction == "A") ? "COVIEW" : "DFDF";
        url = "/ccv-cgi/svn.differ.pl?AT=" 
        		+ AT + "&T_SNAP="
        		+ encodeURI(GV.T_SNAP) + "&MID="
        		+ GV.MID + "&F="
                + encodeURI(file) + "&R="
                + rev;
                
    } else {
        if ((rev == GV.InitRev || offsetB == -1) && GV.NeedCoFirstVer == 1) {
            url = getFileFullUrl(file);
        } else {
	        url = "/ccv-cgi/svn.differ.pl?AT=DF&DF="
	                + encodeURI(GV.DF) + "&OB="
	                + offsetB + "&OE="
	                + offsetE;
        }
    }
    window.open(url);
}

function showTip(tips) {
	tips = "<font color=#0066cc>Check-in comments:</font><br/>" + (tips ? tips : "no comments");
	Tip(tips, CLICKCLOSE, true, STICKY, true, SHADOW, true, ABOVE, false, FADEIN, 300, FADEOUT, 300, SHADOWWIDTH, 5, WIDTH, 580);	
}

function showBD(domObj) {
	jQuery(document.body).toggleClass("showBD", domObj.checked);
}
