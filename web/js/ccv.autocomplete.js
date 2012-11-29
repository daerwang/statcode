ccv.ac = {
	
	hack4Highlight: function() {
		
		jQuery.ui.autocomplete.prototype._highlight = function(label) {
			return label.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + this.term.replace(/([\^\$\(\)\[\]\{\}\*\.\+\?\|\\])/gi, "\\$1") + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<span class='acHighlight'>$1</span>");
		};
		
		jQuery.ui.autocomplete.prototype._renderItem = function( ul, item) {
			var label = item.label;
			if (this.term && this.term.length) {
				label = this._highlight(label)
			}
			return $( "<li>" )
				.data( "item.autocomplete", item )
				.append( $( "<a>" ).html( label ) )
				.appendTo( ul );
		};
	}(),
	
	acIsOpen: false,
	
	jqInputs: null,
	
	init: function() {
		this.jqInputs = ccv.domJQ.REVS
				.add(ccv.domJQ.REV1)
				.add(ccv.domJQ.REV2)
				.add(ccv.domJQ.FILE_REV);
				
		this.jqInputs.autocomplete({
			
			minLength: 0,
			
			position: {
				my: 'right top',
				at: 'right bottom'
			},
			
			close: function() {
				ccv.ac.acIsOpen = false;	
			},
			
			open: function() {
				ccv.ac.acIsOpen = true;	
			}
		});
		
		ccv.domJQ.REVS.autocomplete('option', 'appendTo', ccv.domJQ.LOG);
		ccv.domJQ.REV1.autocomplete('option', 'appendTo', ccv.domJQ.DIFF);
		ccv.domJQ.REV2.autocomplete('option', 'appendTo', ccv.domJQ.DIFF);
		ccv.domJQ.FILE_REV.autocomplete('option', 'appendTo', ccv.domJQ.FILE);
	},
	
	updateSource: function() {
		this.jqInputs.autocomplete('option', 'source', ccv.bot.revs);	
	},
	
	close: function() {
		if (this.acIsOpen) {
			this.jqInputs.autocomplete('close');
			this.acIsOpen = false;
		}
	},
	
	open: function(jqDownAnchor) {
		var jqInput = jqDownAnchor.prev('input.combobox');
		if (this.acIsOpen) {
			jqInput.autocomplete('close');
			return;
		}
		jqInput.autocomplete('search', '');
	}
};
