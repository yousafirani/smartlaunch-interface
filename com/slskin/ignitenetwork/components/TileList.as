/*
TileView.as
Takes an array of BoxShots and lays them out in a
Tile like layout.
*/
package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import com.slskin.ignitenetwork.components.BoxShot;
		
	public class TileList extends MovieClip
	{
		/* Member fields */
		private var container:Sprite;
		private var _listItems:Array;
		private var _listWidth:Number;
		private var _vPadding:Number; //vertical padding between box shots
		private var _hPadding:Number; // horizontal padding between box shots
		
		public function TileList(listItems:Array, listWidth:Number, vPadding:Number, hPadding:Number) 
		{
			this._listItems = listItems;
			this._listWidth = listWidth;
			this._vPadding = vPadding;
			this._hPadding = hPadding;
			this.layoutTileList();
		}
		
		public function get listWidth():Number {
			return this._listWidth;
		}
		
		public function getItemAt(index:uint):BoxShot {
			return this._listItems[index];
		}
		
		/*
		layoutTileList
		Adds the ListItem elements in the local array as children
		to this DisplayObject in a horizontal tiled layout.
		*/
		private function layoutTileList():void
		{
			//remove container if it exists
			if(this.container != null)
				this.removeChild(this.container);
				
			//create container and add it as child
			this.container = new Sprite();
			this.addChild(this.container);
			
			var numItems:uint = this._listItems.length;
			
			var boxPerRow:uint = this._listWidth / (BoxShot.BOX_WIDTH + this._hPadding);
			var numOfRows:uint = Math.ceil(numItems / boxPerRow);
			var numOfColumns:uint = boxPerRow;//Math.ceil(numItems / numOfRows);
			
			var rowOffset:Number = 0;
			var columnOffset:Number = 0;
			
			var boxWidth:Number = BoxShot.BOX_WIDTH;
			var boxHeight:Number = BoxShot.BOX_HEIGHT + BoxShot.LABEL_HEIGHT;
			
			var index:uint = 0; //current index into listItems
			
			for(var row:uint = 0; row < numOfRows; row++)
			{
				//calculate row offset
				rowOffset = (row * boxHeight) + (row * this._vPadding) + this._vPadding;
				
				for(var col:uint = 0; col < numOfColumns; col++)
				{
					if(index >= numItems) break;
					
					//calculate column offset
					columnOffset = (col * boxWidth) + (col * this._hPadding) + this._hPadding;
					var item:BoxShot = this._listItems[index++];
					item.x = columnOffset;
					item.y = rowOffset;
					this.container.addChild(item);
				}
			}
		}

	} //class
} //package
