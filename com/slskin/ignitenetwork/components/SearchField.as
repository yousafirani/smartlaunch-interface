package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import flash.text.TextField;
	import com.slskin.ignitenetwork.components.PanelBackground;
	import com.slskin.ignitenetwork.components.DottedSeperatorSearch;
	import com.slskin.ignitenetwork.views.ListView;
	import com.slskin.ignitenetwork.components.ListItem;
	
	public class SearchField extends MovieClip 
	{
		/* Constants */
		private const LIST_ITEM_HEIGHT:Number = 25; //search list item height
		
		/* Member Fields */
		private var _hint:String; //default label to display in field
		private var dp:Vector.<IListItemObject>; //a vector of IListItemObject used to populate listItems
		private var listItems:Array; //array of list items used to populate the quick results
		private var quickResults:ListView; //the quickResults ListView
		private var field:TextField; //reference to the text field in the component.
		
		public function SearchField() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//set reference the the field
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
		
		public function set hint(txt:String):void {
			this._hint = txt;
		}
		
		public function set dataProvider(dp:Vector.<IListItemObject>): void 
		{
			this.dp = dp;
			createListItems(dp);
		}
		
		/*
		createListItems
		Creates ListItem objects for every IListItemObject in the dataprovider. The
		ListItem is a generic display object that can display an IListItemObject.
		*/
		private function createListItems(dp:Vector.<IListItemObject>):void
		{
			this.listItems = new Array();
			for(var i:uint = 0; i < dp.length; i++)
				listItems.push(new ListItem(dp[i], this.width, LIST_ITEM_HEIGHT, 0x333333, "12", 0xFFFFFFF, new DottedSeperatorSearch()));
				
		}
		
		/*
		displayQuickResults
		Displays the quick results under the search field. The listItems array
		is an array of ListItem objects.
		*/
		private function displayQuickResults(listItems:Array):void
		{
			this.removeQuickResults();
			this.quickResults = new ListView(listItems, 0, 0, new PanelBackground());
			this.quickResults.y = this.height;
			this.addChild(this.quickResults);
		}
		
		
		private function removeQuickResults():void {
			if(this.quickResults != null && this.contains(quickResults))
				this.removeChild(this.quickResults);
		}
		
				
		private function onSearchChange(evt:Event):void 
		{
			this.clearButton.visible = this.field.text.length > 0;
			if(this.field.text.length > 0)
				displayQuickResults(this.listItems.filter(filterFunc));
			else
				this.removeQuickResults();
		}
		
		private function filterFunc(item:ListItem, index:int, array:Array):Boolean
		{
			item.clearFormat();
			item.seperatorVisible = true;
			var sourceLabel:String = item.listItemObj.itemLabel.toLocaleLowerCase();
			var input:String = field.text.toLocaleLowerCase();
			
			var startIndex:int = sourceLabel.search(input);
			if(startIndex == -1)
				return false;
			
			item.highlight(startIndex, startIndex + input.length);
			return true;
		}
		
		private function onFocusIn(evt:FocusEvent):void 
		{
			evt.target.alpha = 1;
			if(evt.target.text == _hint)
				evt.target.text = '';
		}
		
		private function onFocusOut(evt:FocusEvent):void 
		{
			if(evt.target.text == '')
			{
				evt.target.text = _hint;
				evt.target.alpha = .5;
			}
		}
		
		private function onClearClick(evt:MouseEvent):void
		{
			 field.text = '';
			 evt.target.visible = false;
			 this.removeQuickResults();
		}
		
	}//class
}//package
