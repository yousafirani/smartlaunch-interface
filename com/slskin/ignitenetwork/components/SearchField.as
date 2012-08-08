package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import flash.text.TextField;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.components.PanelBackground;
	import com.slskin.ignitenetwork.components.DottedSeperatorSearch;
	import com.slskin.ignitenetwork.components.List;
	import com.slskin.ignitenetwork.components.ListItem;
	import com.slskin.ignitenetwork.apps.Application;
	import flash.events.KeyboardEvent;
	
	public class SearchField extends MovieClip 
	{
		/* Constants */
		public static const SEARCH_RESULTS: String = "onSearchResults";
		public static const SEARCH_CLEAR_CLICK: String = "onSearchClearClick";
		private const LIST_ITEM_HEIGHT: Number = 32; // search list item height
		private const QUICK_RESULT_PADDING: Number = 3; // padding between field and quick results.
		private const MAX_QUICK_RESULTS: int = 7; // maximum number of results to show in quick results drop down.
		
		/* Member Fields */
		private var _hint: String; // default label to display in field
		private var dp: Vector.<IListItem>; // a vector of IListItemObject used to populate listItems
		private var listItems: Array; // array of list items used to populate the quick results
		private var quickResults: List; // the drop down list of the most recent search results.
		private var searchResults: Array; // an array of the most recent search results.
		private var field: TextField; // reference to the text field in the component.
		
		public function SearchField() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(evt: Event): void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			// set reference the the field
			this.field = this._field;
			this.field.tabEnabled = false;
			this.field.alpha = .5;
			this.field.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
			this.field.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			this.field.addEventListener(Event.CHANGE, onSearchChange);
			this.field.text = _hint;
			
			this.clearButton.visible = false;
			this.clearButton.addEventListener(MouseEvent.CLICK, onClearClick);
		}
		
		public function set hint(txt: String): void {
			this._hint = txt;
		}
		
		public function set dataProvider(dp: Vector.<IListItem>): void {
			this.dp = dp;
			createListItems(dp);
		}
		
		public function get text(): String {
			return this._field.text;
		}
		
		public function clearField(): void
		{
			 this.clearButton.visible = false;
			 this.removeQuickResults();
			 if (_field.text != _hint)
			 {
				 this._field.text = '';
				 stage.focus = null;
			 }
		}
		
		/**
		 * Creates ListItem objects for every IListItem in the dataprovider. The
		 * ListItem is a generic display object that can display an IListItem.
		 */
		private function createListItems(dp: Vector.<IListItem>): void
		{
			this.listItems = new Array();
			var item: ListItem;
			for (var i: uint = 0; i < dp.length; i++)
			{
				item = new ListItem(dp[i], this.width, LIST_ITEM_HEIGHT, 0x333333, 
									"11", 0xCCCCCC, new DottedSeperatorSearch());
				item.addEventListener(SLEvent.LIST_ITEM_CLICK, this.onListItemClick);
				listItems.push(item);
			}
				
				
		}
		
		/**
		 * Displays the quick results under the search field. The listItems array
		 * is an array of ListItem objects.
		 */
		private function displayQuickResults(filterResults: Array): void
		{
			this.removeQuickResults();
			this.searchResults = filterResults;
			
			var listItems: Array = new Array();
			if (filterResults.length > this.MAX_QUICK_RESULTS)
			{
				// take the first MAX_QUICK_RESULTS and create a List from them
				for (var i: uint = 0; i < MAX_QUICK_RESULTS; i++)
					listItems.push(filterResults[i]);
				
				// create a more results list item.
				var numMissing: int = filterResults.length - this.MAX_QUICK_RESULTS;
				var moreResults: ListItem = new ListItem(new Application("-7", numMissing + " More Results..."), 
														this.width, LIST_ITEM_HEIGHT, 0x333333, 
														"11", 0xCCCCCC, new DottedSeperatorSearch());
				moreResults.addEventListener(SLEvent.LIST_ITEM_CLICK, this.onListItemClick);
				listItems.push(moreResults);
			} 
			else
				listItems = filterResults;
				
			this.quickResults = new List(listItems, 0, 0, new PanelBackground(), true);
			this.quickResults.addEventListener(SLEvent.LIST_ITEM_CLICK, this.onListItemClick);  
			this.quickResults.y = this.height + QUICK_RESULT_PADDING;
			this.addChild(this.quickResults);
		}
		
		
		private function removeQuickResults(): void {
			if (this.quickResults != null && this.contains(quickResults))
				this.removeChild(this.quickResults);
		}
		
				
		private function onSearchChange(evt: Event): void 
		{
			this.clearButton.visible = this.field.text.length > 0;
			if (this.field.text.length > 0)
				displayQuickResults(this.listItems.filter(filterFunc));
			else
				this.removeQuickResults();
		}
		
		/**
		 * Filters the list based on the passed in string. Each ListItem
		 * is compared based on the itemLabel property.
		 *
		 * This operation is done in O(n * m) - n is the number of items
		 * and m is the average length of the itemLabel strings. The time complexity
		 * could be improved with a slightly more complex algorithm for finding
		 * substrings in a set of strings (divide and conquer algorithm or an
		 * algorithm using a log-collection). However, I do not expect n to
		 * grow large enough for it to be effective.
		 */
		private function filterFunc(item: ListItem, index: int, array: Array): Boolean
		{
			// reset item format and selection
			item.clearFormat();
			item.seperatorVisible = true;
			item.selected = false;
			
			var sourceLabel: String = item.dataProvider.itemLabel.toLocaleLowerCase();
			var input: String = field.text.toLocaleLowerCase();
			
			var startIndex: int = sourceLabel.search(input);
			if (startIndex == -1)
				return false;
			
			item.highlight(startIndex, startIndex + input.length);
			return true;
		}
		
		private function dispatchSearchEvent(evt: Event = null): void 
		{
			this.removeQuickResults();
			this.dispatchEvent(new SLEvent(SearchField.SEARCH_RESULTS, this.searchResults));
		}
		
		private function onFocusIn(evt: FocusEvent): void 
		{
			evt.target.alpha = 1;
			if (evt.target.text == _hint)
				evt.target.text = '';
			
			evt.target.addEventListener(KeyboardEvent.KEY_UP, this.onKeyboardUp); 
		}
		
		private function onFocusOut(evt: FocusEvent): void 
		{
			if (evt.target.text == '')
			{
				evt.target.text = _hint;
				evt.target.alpha = .5;
			}
			
			evt.target.removeEventListener(KeyboardEvent.KEY_UP, this.onKeyboardUp); 
		}
		
		private function onClearClick(evt: MouseEvent): void 
		{
			this.clearField();
			this.dispatchEvent(new Event(SearchField.SEARCH_CLEAR_CLICK));
		}
		
		private function onKeyboardUp(evt: KeyboardEvent): void 
		{
			if (evt.keyCode == 27) // escape
				this.clearField();
			else if (evt.keyCode == 13 && this.quickResults.selectedListItem == null) // enter
				this.dispatchSearchEvent();
		}
		
		/**
		 * If the user clicks on the more results list item, dispatch the search event otherwise
		 * propegate the LIST_ITEM_CLICK event.
		 */
		private function onListItemClick(evt: SLEvent): void 
		{
			if ( ((evt.argument as ListItem).dataProvider as Application).appID == "-7")
				this.dispatchSearchEvent();
			else
				this.dispatchEvent(new SLEvent(SLEvent.LIST_ITEM_CLICK, evt.argument));
		}
	}// class
}// package
