package com.slskin.ignitenetwork.util
{
	public class ArrayIterator
	{
		private var items:Array;
		private var index:int;

		/**
		 * Constructor.
		 * array The array of elements to construct and Iterator for
		 */
		public function ArrayIterator( array:Array )
		{
			items = array;
			// If the array is null, create a new empty array
			if (items == null){
				items = new Array();
			}
			
			index = 0;
		}

		/** 
		 * @return true if the iteration has more elements, false otherwise.
		 */
		public function hasNext():Boolean {
			return index < items.length;
		}

		/** 
		 * @return The next element in the iteration. 
		 */
		public function next():* {
			return items[index++];
		}
		
		public function getItemAt(index:int):* {
			return items[index];
		}
		
		/**
		 * Returns current index of iterator
		 */
		 public function getIndex():int {
			 return this.index; 
		}

		/**
		 * Resets the iterator's state to start from the very first element.
		 */
		public function reset():void {
			index = 0;
		}

	}//class
}//package