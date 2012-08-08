package com.slskin.ignitenetwork.components
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import fl.controls.Button;
	import fl.text.TLFTextField;
	import flash.ui.Mouse;
	import flash.display.Bitmap;
	import flash.geom.Point;

	public class SLButton extends MovieClip 
	{
		public static const CLICK_EVENT: String = "buttonClick";
		public static const DISABLED_CLICK_EVENT: String = "disabledClick"
		private const DEFAULT_COLOR: uint = 0xFFFFFF;
		private const ROLLOVER_COLOR: uint = 0xFFFFFF;
		
		private var tlf: TLFTextField;
		private var disabledCursor: Bitmap;
		
		public function SLButton() 
		{
			this.tabChildren = false;
			this.enabled = true;

			this.disabledCursor = new Bitmap(new DisabledCursor());
			
			// listen for added to stage
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function get label(): String { return this.field.text; }
		public function set label(s: String): void { this.field.text = s; }
		
		/* enables the button */
		public function enable(): void
		{
			this.bg.gotoAndStop("up");
			
			this.button.removeEventListener(MouseEvent.ROLL_OVER, this.disabledOver);
			this.button.removeEventListener(MouseEvent.ROLL_OUT, this.disabledOut);

			// listen for button rollover
			this.button.addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			this.button.addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			this.button.addEventListener(MouseEvent.CLICK, onMouseClick);
			this.button.enabled = true;
			this.enabled = true;
			
			this.button.removeEventListener(MouseEvent.CLICK, disabledClick);
		}
		
		/* disables the button */
		public function disable(): void
		{
			this.bg.gotoAndStop("disabled");
			
			// add disabled listeners
			this.button.addEventListener(MouseEvent.ROLL_OVER, this.disabledOver);
			this.button.addEventListener(MouseEvent.ROLL_OUT, this.disabledOut);
			
			// remove listeners
			this.button.removeEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			this.button.removeEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			this.button.removeEventListener(MouseEvent.CLICK, onMouseClick);
			this.button.enabled = false;
			this.enabled = false;
			
			// add disable click listener
			this.button.addEventListener(MouseEvent.CLICK, disabledClick);
		}
		
		private function onAdded(evt: Event): void
		{
			this.tlf = this.field;
			this.tlf.textColor = this.DEFAULT_COLOR;
			if (enabled)
				this.enable();
			else
				this.disable();
			
		}
		
		private function disabledOver(evt: MouseEvent): void 
		{
			this.disabledCursor.visible = false;
			this.addChild(this.disabledCursor);
			Mouse.hide();
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandler);
		}
		
		private function disabledOut(evt: MouseEvent): void 
		{
			this.removeChild(this.disabledCursor);
			Mouse.show();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandler);
		}
		
		private function disabledClick(evt: MouseEvent): void
		{
			this.dispatchEvent(new Event(SLButton.DISABLED_CLICK_EVENT))
		}
		
		private function onMouseMoveHandler(evt: MouseEvent): void 
		{
			var pt: Point = globalToLocal(new Point(evt.stageX, evt.stageY));
			this.disabledCursor.x = pt.x;
			this.disabledCursor.y = pt.y;
			this.disabledCursor.visible = true;
		}
		
		private function onMouseOver(evt: MouseEvent): void {
			this.tlf.textColor = this.ROLLOVER_COLOR;
			this.bg.gotoAndStop("over");
		}
		
		private function onMouseOut(evt: MouseEvent): void {
			this.field.textColor = this.DEFAULT_COLOR;
			this.bg.gotoAndStop("up");
		}
		
		private function onMouseClick(evt: MouseEvent): void {
			this.dispatchEvent(new Event(SLButton.CLICK_EVENT));
		}
		
	} // class
} // package
