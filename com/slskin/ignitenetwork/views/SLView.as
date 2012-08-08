/**
SLView.as
A mostly abstract super class that stores common variables and objects
which makes it easier for a movieclip to animate onto the stage. The view
manager expects to deal with SLView's because they have methods for showView
and hideView. By default an SLView will orient itself onto the middle of the stage.
*/
package com.slskin.ignitenetwork.views 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.display.Stage;
	import com.slskin.ignitenetwork.Main;
	
	public class SLView extends MovieClip
	{
		/* Constants */
		public static const SHOW_COMPLETE: String = "showComplete";
		public static const HIDE_COMPLETE: String = "hideComplete";
		
		/* Protected Member Fields */
		protected var xTween: Tween; // stores x tween object
		protected var yTween: Tween; // stores y tween object
		protected var alphaTween: Tween; // stores the alpha tween object
		protected var startPos: Point; // stores start position of this object
		protected var endPos: Point; // stores the end position of this object
		protected var centerX: Number = 0; // stores the center of the stage, X
		protected var centerY: Number = 0; // stores the center of the stage, Y
		protected var yPadding: Number = 0; // x padding added (relative to center y)
		protected var xPadding: Number = 0; // ypadding added (relative to center x)
		
		// Store a typed copy of the main document class.
		protected var main: Main;
		
		/**
		 * Listen for added to stage event with a high priority.
		 */
		public function SLView() {
			// listen for on added to stage event with higher priority
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 1);
		}
		
		/**
		 * Event handler for added to stage event. Set reference to main
		 * and move the view object into the start position.
		 */
		private function onAdded(evt: Event): void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			// set main reference
			main = root as Main;
			
			// setup the view for entrance
			this.setupView();
		}
		
		/**
		 * Sets up view to tween and instatiates listeners
		 */
		public function setupView(): void
		{
			// update the center positions
			this.updateCenter();
			
			// set start position for tween in.
			// By default, the object will start off the stage to the left.
			this.startPos = new Point((this.width * -1) + this.xPadding, this.centerY + this.yPadding);
			
			// move the object to the start pos
			this.moveToStart();
			
			this.stage.addEventListener(Event.RESIZE, this.updateCenter);
			this.stage.addEventListener(Event.RESIZE, this.showView);
		}
		
		/**
		 * Helper function that moves this object to the start position
		 * as indicated by the start position point.
		 */
		protected function moveToStart(): void
		{
			this.x = this.startPos.x;
			this.y = this.startPos.y;
		}
		
		/**
		 * Calculate and store the center x and y based on the height and width
		 * of the stage and this object.
		 */
		protected function updateCenter(evt: Event = null): void
		{
			this.centerX = (main.getStageWidth() - this.width) / 2;
			this.centerY = (main.getStageHeight() - this.height) / 2;
		}
		
		/**
		 * Defines default behavior for hiding an SLView.
		 * By default, the object tweens to the center of the stage taking into
		 * account the x and y padding.
		 */
		public function showView(evt: Event = null): void 
		{
			this.endPos = new Point(this.centerX + this.xPadding, this.centerY + this.yPadding);
	
			// animate to the end position.
			this.xTween = new Tween(this, "x", Strong.easeInOut, this.x, this.endPos.x, 1, true);
			this.yTween = new Tween(this, "y", Strong.easeInOut, this.y, this.endPos.y, 1, true);
			
			this.xTween.addEventListener(TweenEvent.MOTION_FINISH, onShowTweenFinish);
		}
		
		/**
		 * Dispatch showComplete event.
		 */
		private function onShowTweenFinish(evt: TweenEvent): void {
			this.xTween.removeEventListener(TweenEvent.MOTION_FINISH, onShowTweenFinish);
			this.dispatchEvent(new Event(SLView.SHOW_COMPLETE));
		}
		
		/**
		 * Defines default behavior for hiding an SLView.
		 * By Default, the object swipes off the stage to the
		 * right.
		 */
		public function hideView(evt: Event = null): void
		{
			var offStage: Number = this.width + main.getStageWidth();
			this.xTween = new Tween(this, "x", Strong.easeOut, this.x, offStage, 1, true);
			
			this.stage.removeEventListener(Event.RESIZE, this.updateCenter);
			this.stage.removeEventListener(Event.RESIZE, this.showView);
			
			this.xTween.addEventListener(TweenEvent.MOTION_FINISH, onHideTweenFinish);
		}
		
		/**
		 * Dispatch hide complete event.
		 */
		protected function onHideTweenFinish(evt: TweenEvent): void {
			evt.target.removeEventListener(TweenEvent.MOTION_FINISH, onHideTweenFinish);
			this.dispatchEvent(new Event(SLView.HIDE_COMPLETE));
		}
	} // class
} // package
