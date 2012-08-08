/**
 * ViewManager.as
 * Maintains the views that are added to the document
 * class. Gives a collection of functions to manage the
 * views.
 */
package com.slskin.ignitenetwork
{
	import flash.events.Event;
	import flash.display.DisplayObject;
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.views.SLView;
	import com.slskin.ignitenetwork.util.*;
	import flash.events.EventDispatcher;

	public class ViewManager extends EventDispatcher
	{
		/* Member fields */
		private var main: Main;// a reference to the document class.
		private var views: Array;// maintains a collection of the views 
		private var vi: ArrayIterator;// maintains a pointer to the current view.
		private var currentView: SLView;

		public function ViewManager(main: Main)
		{
			this.main = main;
			this.currentView = null;
			this.views = new Array();
			this.vi = new ArrayIterator(this.views);
		}

		/**
		 * Displays the next element in the view list and hides the current element
		 * if one exists. Could be called by an event listener 
		 * so it takes an option event parameter.
		 */
		public function displayNextView(evt: Event = null): void
		{
			if (this.currentView != null)
			{
				this.currentView.hideView();
				this.currentView.addEventListener(SLView.HIDE_COMPLETE, onViewHideComplete);
			}

			if (this.vi.hasNext())
			{
				this.currentView = this.vi.next();
				main.addChild(this.currentView);
			}
		}

		/**
		 * Adds the view to the view array. The array is accessed in a 
		 * queue-like fashion (FIFO) with the array iterator.
		 */
		public function addView(view: SLView): void
		{
			this.views.push(view);
		}

		/**
		 * Clears the view manager views arrays and resets the iterator
		 */
		public function clearAllViews(): void
		{
			if (this.currentView != null)
			{
				this.currentView.hideView();
				this.currentView.addEventListener(SLView.HIDE_COMPLETE, onViewHideComplete);
			}

			this.currentView = null;
			this.views = new Array();
			this.vi = new ArrayIterator(this.views);
		}

		/**
		 * adds view one index ahead of the iterator. This has the effect
		 * of showing the view next time displayNextView is called.
		 */
		public function addViewAsNext(view: SLView): void
		{
			this.views.splice(vi.getIndex(), 0, view);
		}



		/**
		 * Listens for view hide complete event and removes the element from stage.
		 */
		private function onViewHideComplete(evt: Event): void
		{
			if (main.contains(evt.target as DisplayObject))
			{
				main.removeChild(evt.target as DisplayObject);
			}

			this.dispatchEvent(evt);
		}
	}// class
}// package