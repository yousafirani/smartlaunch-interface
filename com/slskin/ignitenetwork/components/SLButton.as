package com.slskin.ignitenetwork.components
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import fl.controls.Button;
	import fl.text.TLFTextField;

	public class SLButton extends MovieClip 
	{
		public static const BUTTON_CLICK_EVENT:String = "buttonClick";
		private const DEFAULT_COLOR:uint = 0xFFFFFF;
		private const ROLLOVER_COLOR:uint = 0xFFFFFF;
		
		private var tlf:TLFTextField;
		
		public function SLButton() 
		{
			this.tabChildren = false;
			this.enabled = true;
			
			//listen for added to stage
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function get label():String { return this.field.text; }
		public function set label(s:String):void { this.field.text = s; }
		
		/* enables the button */
		public function enable():void
		{
			this.alpha = 1;
			//listen for button rollover
			this.button.addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			this.button.addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			this.button.addEventListener(MouseEvent.CLICK, onMouseClick);
			this.button.enabled = true;
			this.enabled = true;
		}
		
		/* disables the button */
		public function disable():void
		{
			this.alpha = .5;
			//listen for button rollover
			this.button.removeEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			this.button.removeEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			this.button.removeEventListener(MouseEvent.CLICK, onMouseClick);
			this.button.enabled = false;
			this.enabled = false;
		}
		
		private function onAdded(evt:Event):void
		{
			this.tlf = this.field;
			this.tlf.textColor = this.DEFAULT_COLOR;
			if(enabled)
				this.enable();
			else
				this.disable();
			
		}
		
		
		private function onMouseOver(evt:MouseEvent):void
		{
			this.tlf.textColor = this.ROLLOVER_COLOR;
			this.bg.gotoAndStop("over");
			this.arrow.play();
		}
		
		private function onMouseOut(evt:MouseEvent):void
		{
			this.field.textColor = this.DEFAULT_COLOR;
			this.bg.gotoAndStop("up");
		}
		
		private function onMouseClick(evt:MouseEvent):void
		{
			//dispatch event to listeners of this obj
			this.dispatchEvent(new Event(SLButton.BUTTON_CLICK_EVENT));
		}
		
	} //class
} //package
