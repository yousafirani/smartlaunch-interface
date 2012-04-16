package com.slskin.ignitenetwork.components
{
	import flash.display.MovieClip;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.events.Event;
	
	public class SLWindow extends MovieClip
	{
		public static const RESIZE_COMPLETE:String = "ResizeComplete";
		
		private var hTween:Tween;
		private var wTween:Tween;
		private var wResizeDone:Boolean;
		private var hResizeDone:Boolean;
		
		public function SLWindow() {}
		
		public function resize(h:Number, w:Number):void
		{
			wResizeDone = false;
			hResizeDone = false;
			hTween = new Tween(this, "height", Strong.easeIn, this.height, h, .5, true);
			wTween = new Tween(this, "width", Strong.easeIn, this.width, w, .5, true);
			
			hTween.addEventListener(TweenEvent.MOTION_FINISH, hResizeComplete);
			wTween.addEventListener(TweenEvent.MOTION_FINISH, wResizeComplete);
		}
		
		private function hResizeComplete(evt:TweenEvent):void
		{
			hResizeDone = true;
			if(wResizeDone)
				this.dispatchEvent(new Event(SLWindow.RESIZE_COMPLETE));
		}
		
		private function wResizeComplete(evt:TweenEvent):void
		{
			wResizeDone = true;
			if(hResizeDone)
				this.dispatchEvent(new Event(SLWindow.RESIZE_COMPLETE));
		}

	} //class
} //package
