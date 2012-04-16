/*
SLCheckBox.as
Defines the behavior for the checkbox component in the library.
*/

package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import fl.text.TLFTextField;
	import flash.text.TextFieldAutoSize;
	import flashx.textLayout.formats.TextDecoration;
	import flash.text.TextFormat;
	import flash.display.Sprite;

	public class SLCheckBox extends MovieClip 
	{
		/* Member Fields */
		private var tlf:TLFTextField;
		private var checkMark:MovieClip;
		private var _labelText:String;
		private var _labelColor:uint;
		private var _rollOverColor:uint;
		private var _selected:Boolean;
		private var _fontSize:String;
		
		public function SLCheckBox(label:String = "Check Box", labelColor:uint = 0x333333, rollOverColor:uint = 0x000000, fontSize:String = "12") 
		{
			this._labelText = label;
			this._labelColor = labelColor;
			this._fontSize = fontSize;
			this._rollOverColor = rollOverColor;
			this._selected = false;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function get selected():Boolean {
			return this._selected;
		}
		
		/* Setters */
		public function set selected(b:Boolean) {
			this._selected = b;
			if(this.checkMark != null)
				this.checkMark.visible = b;
		}
		
		public function set labelText(str:String):void {
			this._labelText = str;
			if(this.tlf != null)
				this.tlf.text = str;
		}
		
		public function set labelColor(color:uint):void {
			this._labelColor = color;
			if(this.tlf != null)
				this.tlf.textColor = color;
		}
		
		/*
		onAdded
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			 //set reference from objects defined in the library
			this.tlf = this.labelTLF;
			this.tlf.autoSize = TextFieldAutoSize.LEFT;
			this.checkMark = this.check;
			this.checkMark.visible = this._selected;
			
			this.tlf.htmlText = this._labelText;
			var fmt:TextFormat = new TextFormat();
			fmt.size = this._fontSize;
			fmt.color = this._labelColor;
			this.tlf.setTextFormat(fmt);
			
			//draw hit box
			var hitBox:Sprite = new Sprite();
			hitBox.buttonMode = true;
			hitBox.graphics.beginFill(0x000000, 0);
			hitBox.graphics.drawRect(0, 0, this.checkMark.width, this.checkMark.height);
			hitBox.graphics.endFill();
			this.addChild(hitBox);
			
			hitBox.addEventListener(MouseEvent.CLICK, onCheckClick, false, 1);
			hitBox.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			hitBox.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
		}
		
		/*
		onCheckClick
		Toggle selected flag and set check mark to selected.
		*/
		private function onCheckClick(evt:MouseEvent):void
		{
			this._selected = !this._selected;
			this.checkMark.visible = this._selected;
		}
		
		/*
		onMouseRollOver
		*/
		private function onMouseRollOver(evt:MouseEvent):void {
			this.tlf.textColor = this._rollOverColor;
		}
		
		private function onMouseRollOut(evt:MouseEvent):void {
			this.tlf.textColor = this._labelColor;
		}
		
		
		
		
	} //class
} //package
