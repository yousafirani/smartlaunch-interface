/*
LaunchButton.as
Implementation for the LaunchButton movieclip in the .fla library.
*/
package com.slskin.ignitenetwork.components 
{
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import com.slskin.ignitenetwork.Language;
	
	public class LaunchButton extends MovieClip 
	{
		public function LaunchButton() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(evt:Event):void 
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			this.buttonMode = this.useHandCursor = true;
			
			//set label
			this.labelTLF.text = Language.translate("Start", "Start").toUpperCase();
			
			//add mouse event listeners
			addEventListener(MouseEvent.ROLL_OVER, onLaunchRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onLaunchRollOut);
			addEventListener(MouseEvent.CLICK, onLaunchClick);
			addEventListener(MouseEvent.MOUSE_DOWN, onLaunchDown);
		}
		
				
		/*
		onLaunchRollOver
		RollOver event handler for the launch button.
		*/
		private function onLaunchRollOver(evt:MouseEvent):void {
			this.bg.gotoAndStop("Over");
			evt.stopPropagation();
		}
		
		/*
		onLaunchRollOut
		RollOut event handler for the launch button.
		*/
		private function onLaunchRollOut(evt:MouseEvent):void {
			this.bg.gotoAndStop("Up");
			evt.stopPropagation();
		}
		
		/*
		onLaunchDown
		Mouse down event handler for launch button
		*/
		private function onLaunchDown(evt:MouseEvent):void {
			this.bg.gotoAndStop("Down");
		}
		
		/*
		onLaunchClick
		Click event handler for launch button.
		*/
		private function onLaunchClick(evt:MouseEvent):void 
		{
			this.bg.gotoAndStop("Over");
		}
		
	} //class
} //package
