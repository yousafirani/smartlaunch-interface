/*
ListView.as
Takes an array of ListItems and adds them as a child
DisplayObject laid out vertically. The ListView can be
added as the source to a ScrollPane.
*/
package com.slskin.ignitenetwork.components  
{
	import flash.events.Event;
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import com.slskin.ignitenetwork.events.SLEvent;

	public class List extends MovieClip 
	{
		/* Member Fields */
		private var container:Sprite; //container object to store the list.
		private var itemVerticalPadding:Number; //padding between elements.
		private var leftPadding:Number; //left padding for each item
		private var backgroundSprite:DisplayObject; //display object to show as the background of the list
		private var _listItems:Array;
		private var _listWidth:Number = 0;
		private var _listHeight:Number = 0;
		private var selectedIndex:Number = -1;
		private var selectedItem:ListItem;
		
		public function List(listItems:Array, verticalPadding:Number = 0,  leftPadding:Number = 0,
								 bgSprite:DisplayObject = null, navigateWithKeyboard:Boolean = false) 
		{
			this.itemVerticalPadding = verticalPadding;
			this.leftPadding = leftPadding;
			this.backgroundSprite = bgSprite;
			this._listItems = listItems;
			
			if(navigateWithKeyboard)
				this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
				
			this.layoutList();
		}
		
		/* Getters */
		public function get listHeight():Number {
			return this._listHeight;
		}
		
		public function get listWidth():Number {
			return this._listWidth;
		}
		
		public function getItemAt(index:uint):ListItem {
			return this._listItems[index];
		}
		
		private function onAdded(evt:Event):void {
			stage.addEventListener(KeyboardEvent.KEY_UP, this.onKeyUpHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		private function onRemoved(evt:Event):void {
			stage.removeEventListener(KeyboardEvent.KEY_UP, this.onKeyUpHandler);
		}
		
		/*
		layoutList
		Adds the ListItem elements in the local array as children
		to this DisplayObject in a vertical layout.
		*/
		private function layoutList():void
		{
			//remove container if it exists
			if(this.container != null)
				this.removeChild(this.container);
				
			//create container and add it as child
			this.container = new Sprite();
			this.addChild(this.container);
			
			var numItems:uint = this._listItems.length;
			var item:ListItem;
			var yPos:Number = 0;
			for(var i:uint = 0; i < numItems; i++)
			{
				item = this._listItems[i];
				
				//make sure we have ListItem types in the array
				if(!(item is ListItem)) continue;
				
				//keep track of list width
				if(item.itemWidth > this._listWidth)
					this._listWidth = item.itemWidth;
				
				item.x = this.leftPadding;
				item.y = yPos;
				yPos += item.itemHeight + this.itemVerticalPadding;
				this.container.addChildAt(item, 0); 
			}
			
			//hide seperator on last item in list
			if(item != null) 
				item.seperatorVisible = false;
						
			this._listHeight = yPos;
			this._listWidth += this.leftPadding;
			this.selectedIndex = -1;
			this.selectedItem = null;
			
			if(backgroundSprite != null)
			{
				backgroundSprite.width = this._listWidth + this.leftPadding;
				backgroundSprite.height = yPos;
				this.container.addChildAt(backgroundSprite, 0);
			}
		}
		
		/*
		onKeyUpHandler
		Select elements in the list based on key down and key up input.
		*/
		private function onKeyUpHandler(evt:KeyboardEvent):void {
			if(this._listItems == null) return;
			
			if(evt.keyCode == 40) //arrow down
				this.selectedIndex = (this.selectedIndex+1) % this._listItems.length;
			else if(evt.keyCode == 38)
			{
				this.selectedIndex = (this.selectedIndex-1) % this._listItems.length;
				if(this.selectedIndex < 0)
					this.selectedIndex = this._listItems.length + this.selectedIndex;
			}
			else if(evt.keyCode == 13 && this.selectedItem != null) //enter
				this.dispatchEvent(new SLEvent(SLEvent.LIST_ITEM_CLICK, this.selectedItem));
			
			
			if(evt.keyCode == 38 || evt.keyCode == 40)
			{
				if(this.selectedItem != null)
					this.selectedItem.selected = false;
					
				this.selectedItem = this._listItems[this.selectedIndex];
				selectedItem.selected = true;
			}
		}
		

	} //class
} //package
