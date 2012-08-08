/**
 * TileView.as
 * Takes an array of BoxShots and lays them out in a
 * Tile like layout.
 */
package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import com.slskin.ignitenetwork.components.BoxShot;
	import flash.events.Event;
		
	public dynamic class TileList extends MovieClip
	{
		/* Member fields */
		private var container: Sprite;
		private var _listItems: Array;
		private var _listWidth: Number;
		private var _vPadding: Number; // vertical padding between box shots
		private var _hPadding: Number; //  horizontal padding between box shots
		
		public function TileList(listItems: Array, listWidth: Number, vPadding: Number, hPadding: Number) 
		{
			this._listItems = listItems;
			this._listWidth = listWidth;
			this._vPadding = vPadding;
			this._hPadding = hPadding;
			
			// draw a pixel on stage to offset a weird issue where
			// the height of the container is returned incorrectly
			this.graphics.beginFill(0x000000, 0);
			this.graphics.drawRect(0, 0, 1, 1);
			this.graphics.endFill();
			
			this.layoutTileList();
		}
		
		public function get listWidth(): Number {
			return this._listWidth;
		}
		
		public function getItemAt(index: uint): BoxShot {
			return this._listItems[index];
		}
		
		/**
		 * Adds the ListItem elements in the local array as children
		 * to this DisplayObject in a horizontal tiled layout.
		 */
		private function layoutTileList(): void
		{
			if (this.container != null && this.contains(this.container))
				this.removeChild(this.container);
			
			// create container and add it as child
			container = new Sprite();
			addChild(container);
			
			var numItems: uint = this._listItems.length;
			
			var boxPerRow: uint = this._listWidth / (BoxShot.BOX_WIDTH + this._hPadding);
			var numOfRows: uint = Math.ceil(numItems / boxPerRow);
			var numOfColumns: uint = boxPerRow;// Math.ceil(numItems / numOfRows);
			
			var rowOffset: Number = 0;
			var columnOffset: Number = 0;
			
			var boxWidth: Number = BoxShot.BOX_WIDTH;
			var boxHeight: Number = BoxShot.BOX_HEIGHT + BoxShot.LABEL_HEIGHT + BoxShot.LABEL_PADDING;
			
			var index: uint = 0; // current index into listItems
			
			for (var row: uint = 0; row < numOfRows; row++)
			{
				// calculate row offset
				rowOffset = (row * boxHeight) + (row * this._vPadding) + this._vPadding;
				
				for (var col: uint = 0; col < numOfColumns; col++)
				{
					if (index >= numItems) break;
					
					// calculate column offset
					columnOffset = (col * boxWidth) + (col * this._hPadding) + this._hPadding;
					var item: BoxShot = this._listItems[index++];
					item.x = columnOffset;
					item.y = rowOffset;
					container.addChild(item);
				}
			}
			
			// add vPadding to bottom row
			var spacer: Sprite = new Sprite();
			spacer.graphics.beginFill(0x000000, 0);
			spacer.graphics.drawRect(0, rowOffset+boxHeight, 1, 2 * this._vPadding);
			spacer.graphics.endFill();
			container.addChild(spacer);
		}
	} // class
} // package
