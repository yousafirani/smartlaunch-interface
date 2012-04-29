package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.InteractiveObject;
	import com.slskin.ignitenetwork.components.List;
	import com.slskin.ignitenetwork.events.SLEvent;
	
	public class DropDownSelector extends MovieClip 
	{
		/* Constants */
		private const DROP_DOWN_WIDTH:Number = 150;
		private const LIST_ITEM_HEIGHT:Number = 25;
		private const DROP_DOWN_PADDING:Number = 3;
		private const ITEM_ROLLOVER_COLOR:uint = 0x333333;
		private const ITEM_LABEL_SIZE:String = "11";
		private const ITEM_LABEL_COLOR:uint = 0xe1e1e1;
		
		/* Member Fields */
		private var _dropDownList:List;
		private var dp:Vector.<IListItem>; //a vector of IListItem used to populate the drop down list
		
		public function DropDownSelector() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(evt:Event):void 
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			InteractiveObject(this.title.getChildAt(1)).tabEnabled = false; //disable tabbing on tlf
			
			//add listeners and activate buttonMode
			this.buttonMode = this.useHandCursor = true;
			this.addEventListener(MouseEvent.CLICK, onSelectorClick);
			stage.addEventListener(MouseEvent.CLICK, onMasterClick);
		}
		
		public function set dataProvider(dp:Vector.<IListItem>):void 
		{
			this.dp = dp;
			createDropDown(dp);
		}
		
		public function set label(str:String):void {
			this.title.text = str;
		}
		
		/*
		createDropDown
		Creates the drop down List based on the dataprovider.
		*/
		private function createDropDown(dp:Vector.<IListItem>):void
		{
			var listItems:Array = new Array();
			var listItem:ListItem;
			
			//add the rest of the sub categories
			for(var i:uint = 0; i < dp.length; i++)
			{
				listItem = new ListItem(dp[i], 
										DROP_DOWN_WIDTH, 
										LIST_ITEM_HEIGHT, 
										ITEM_ROLLOVER_COLOR, 
										ITEM_LABEL_SIZE,
										ITEM_LABEL_COLOR, new DottedSeperatorShort());
				
				//listen for listItem click
				listItem.addEventListener(SLEvent.LIST_ITEM_CLICK, onListItemClick);
				listItems.push(listItem);
			}
			
			this._dropDownList = new List(listItems, 0, 0, new PanelBackground());
			this._dropDownList.visible = false;
			_dropDownList.y = this.height + this.DROP_DOWN_PADDING;
			this.addChild(_dropDownList);
		}
		
		/*
		toggleDropDown
		Toggles the sub category selector drop down menu.
		*/
		private function toggleDropDown():void
		{
			if(this._dropDownList.visible)
				this.background.gotoAndStop("Up");
			else
				this.background.gotoAndStop("Down");
			
			this._dropDownList.visible = !(this._dropDownList.visible);
		}
		
		/*
		onSelectorClick
		Show or hide the sub category list view depending on its current state.
		*/
		private function onSelectorClick(evt:MouseEvent):void {
			toggleDropDown();
			evt.stopPropagation(); //don't let the event propegate up to parent displayObjects.
		}
		
		/*
		onMasterClick
		Hides the sub categeroy drop down list. This allows for users to click anywhere
		and hide the drop down list if the dropdown is visible. (Expected behavior
		from a drop down list.)
		*/
		private function onMasterClick(evt:MouseEvent):void {
			if(this._dropDownList.visible)
				toggleDropDown();
		}
		
		/*
		onListItemClick
		Propegate the event.
		*/
		private function onListItemClick(evt:SLEvent):void {
			this.dispatchEvent(new SLEvent(SLEvent.LIST_ITEM_CLICK, evt.argument));
		}
		
	} //class
} //package
