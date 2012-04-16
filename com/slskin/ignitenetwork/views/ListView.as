/*
ListView.as
Takes an array of ListItems and adds them as a child
DisplayObject laid out vertically. The ListView can be
added as the source to a ScrollPane.
*/
package com.slskin.ignitenetwork.views  
{
	import flash.events.Event;
	import flash.display.MovieClip;
	import com.slskin.ignitenetwork.components.ListItem;
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class ListView extends MovieClip 
	{
		/* Member Fields */
		private var container:Sprite; //container object to store the list.
		private var itemVerticalPadding:Number; //padding between elements.
		private var leftPadding:Number; //left padding for each item
		private var backgroundSprite:DisplayObject; //display object to show as the background of the list
		private var isFiltered:Boolean; //a boolean indicating if the list is filtered.
		private var _listItems:Array;
		private var _listWidth:Number = 0;
		private var _listHeight:Number = 0; //keeps track of the current list height
		
		public function ListView(listItems:Array, verticalPadding:Number = 5, leftPadding:Number = 0, 
								 bgSprite:DisplayObject = null) 
		{
			this.itemVerticalPadding = verticalPadding;
			this.leftPadding = leftPadding;
			this.backgroundSprite = bgSprite;
			this._listItems = listItems;
			
			this.layoutList();
		}
		
		/* Getters */
		public function get listHeight():Number {
			return this._listHeight;
		}
		
		public function get listWidth():Number {
			return this._listWidth;
		}
		
		public function get filtered():Boolean {
			return this.isFiltered;
		}
		
		public function getItemAt(index:uint):ListItem {
			return this._listItems[index];
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
				
				item.clearFormat();
				item.x = this.leftPadding;
				item.y = yPos;
				yPos += item.itemHeight + this.itemVerticalPadding;
				this.container.addChildAt(item, 0);
			}
						
			this._listHeight = yPos;
			this._listWidth += this.leftPadding;
			this.isFiltered = false
			
			if(backgroundSprite != null)
			{
				backgroundSprite.width = this._listWidth;
				backgroundSprite.height = yPos;
				this.container.addChildAt(backgroundSprite, 0);
			}
		}
		
		/*
		filterList
		Filters the list based on the passed in string. Each ListItem
		is compared based on the itemLabel property.
		
		This operation is done in O(n * m) - n is the number of items
		and m is the average length of the itemLabel strings. The time complexity
		could be improved with a slightly more complex algorithm for finding
		substrings in a set of strings (divide and conquer algorithm or an
		algorithm using a hashmap and sorting). However, I do not expect n to
		grow large enough for it to be effective.
		*/
		public function filterList(filter:String):void
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
				if(!(item is ListItem)) 
					continue;
				
				//keep track of list width
				if(item.itemWidth > this._listWidth)
					this._listWidth = item.itemWidth;
				
				//go back to default format
				item.clearFormat();
				
				//make sure we match the filter
				var sourceLabel:String = item.targetObj.itemLabel.toLocaleLowerCase();
				var startIndex:int = sourceLabel.search(filter.toLocaleLowerCase());
				if(startIndex == -1) 
					continue;
				
				item.highlight(startIndex, startIndex + filter.length);
				item.x = this.leftPadding;
				item.y = yPos;
				yPos += item.itemHeight + this.itemVerticalPadding;
				this.container.addChildAt(item, 0);
			}
			
			this._listHeight = yPos;
			this._listWidth += this.leftPadding;
			this.isFiltered = true;
			
			if(backgroundSprite != null)
			{
				backgroundSprite.width = this._listWidth;
				backgroundSprite.height = yPos;
				this.container.addChildAt(backgroundSprite, 0);
			}
		}
		
		/*
		clearFilter
		Clears the filter by laying out the list with no
		filter.
		*/
		public function clearFilter():void
		{
			this.layoutList();
		}
		

	} //class
} //package
