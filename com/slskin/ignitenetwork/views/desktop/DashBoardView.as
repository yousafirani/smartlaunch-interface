/*
DashboardView.as
Dashboard view is a container for widgets for user info, favorites,
and News.
*/
package com.slskin.ignitenetwork.views.desktop 
{
	import com.slskin.ignitenetwork.views.SLView;
	import flash.events.Event;
	import flash.geom.Point;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import fl.text.TLFTextField;
	import com.slskin.ignitenetwork.events.SLEvent;
	
	public class DashBoardView extends SLView 
	{
		/* Constant */
		private const LEFT_PADDING:Number = 105; //Dashboard needs to make room for ContentView
		
		/* Constructor */
		public function DashBoardView() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded
		Move the object of the stage to the right and show the view.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAdded);
			
			//recalculate start pos and add padding
			this.xPadding = this.LEFT_PADDING + this.width;
			this.startPos = new Point(main.getStageWidth() + this.width, centerY);
			this.moveToStart();
			
			//display the dashboard view
			this.showView();
		}

		/*
		showView
		Listen for TWEEN_FINISH event, indicates that the dashboard view is done
		tweening.
		*/
		public override function showView(evt:Event = null):void
		{
			super.showView();
			
			//listen for x tween finish
			this.xTween.addEventListener(TweenEvent.MOTION_FINISH, onTweenFinish);
		}
		
		/*
		onTweenFinish
		Dispatch the event on behalf of this object
		*/
		private function onTweenFinish(evt:TweenEvent):void {
			this.dispatchEvent(evt);
		}
		
	} //class
} //package
