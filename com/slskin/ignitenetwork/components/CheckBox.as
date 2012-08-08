/**
 * Defines the behavior for the checkbox component in the library.
 */
package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import fl.text.TLFTextField;
	import flash.text.TextFieldAutoSize;
	import flashx.textLayout.formats.TextDecoration;
	import flash.text.TextFormat;
	import flash.display.Sprite;
	import flash.display.InteractiveObject;
	import flashx.textLayout.formats.TextLayoutFormat;
	import com.slskin.ignitenetwork.fonts.TahomaRegular;

	public class CheckBox extends MovieClip 
	{
		/* Constants */
		private const LINK_COLOR: uint = 0x0080FF;
		private const LINK_ROLLOVER_COLOR: uint = 0xFFFFFF;
		
		/* Member Fields */
		private var _label: TLFTextField;
		private var checkMark: MovieClip;
		private var _labelText: String;
		private var _labelColor: uint;
		private var _rollOverColor: uint;
		private var _selected: Boolean;
		private var _fontSize: String;
		private var labelFormat: TextLayoutFormat;
		
		public function CheckBox(label: String = "Check Box", labelColor: uint = 0xCCCCCC, rollOverColor: uint = 0xFFFFFF, fontSize: String = "11") 
		{
			this._labelText = label;
			this._labelColor = labelColor;
			this._fontSize = fontSize;
			this._rollOverColor = rollOverColor;
			this._selected = false;
			this._label = new TLFTextField();
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function get selected(): Boolean {
			return this._selected;
		}
		
		/* Setters */
		public function set selected(b: Boolean) 
		{
			this._selected = b;
			if (this.checkMark != null)
				this.checkMark.visible = b;
		}
		
		public function set labelText(str: String): void 
		{
			this._labelText = str;
			this._label.htmlText = str;
			this._label.textFlow.flowComposer.updateAllControllers();
		}
		
		private function onAdded(evt: Event): void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
						
			this.checkMark = this.check;
			this.checkMark.visible = this._selected;
			
			// draw hit box
			var hitBox: Sprite = new Sprite();
			hitBox.tabEnabled = false;
			hitBox.buttonMode = true;
			hitBox.graphics.beginFill(0x000000, 0);
			hitBox.graphics.drawRect(0, 0, this.width, this.height);
			hitBox.graphics.endFill();
			this.addChild(hitBox);
						
			hitBox.addEventListener(MouseEvent.CLICK, onCheckClick, false, 1);
			hitBox.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			hitBox.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			
			configureLabel();

		}
		
		private function configureLabel(): void 
		{
			with(this._label)
			{
				x = this.width + 5;
				height = this.height;
				embedFont = true;
				selectable = false;
			}
			
			// hack to autosize htmlText
			this._label.defaultTextFormat = new TextFormat(new TahomaRegular().fontName, this._fontSize, this._labelColor);
			this._label.text = this._labelText;
			var textWidth: Number = this._label.textWidth;
			this._label.htmlText = this._labelText;
			this._label.width = textWidth;
			
			// create tlf format
			this.labelFormat = new TextLayoutFormat();
			with(this.labelFormat)
			{
				color = this._labelColor;
	 			fontFamily = new TahomaRegular().fontName;
				fontSize = this._fontSize;
			}
			
			this._label.textFlow.hostFormat = this.labelFormat;
			this._label.textFlow.linkNormalFormat = {color: LINK_COLOR, textDecoration: "underline"};
			this._label.textFlow.linkHoverFormat = {color: LINK_ROLLOVER_COLOR, textDecoration: "underline"};
			this._label.textFlow.flowComposer.updateAllControllers();
			
			InteractiveObject(this._label.getChildAt(1)).tabEnabled = false; // disable tabbing on label
			
			this._label.y = (this.height - this._label.textHeight) / 2;
			this._label.y += 2;
			this.addChild(this._label);
		}
		
		/**
		 * Toggle selected flag and set check mark to selected.
		 */
		private function onCheckClick(evt: MouseEvent): void
		{
			this._selected = !this._selected;
			this.checkMark.visible = this._selected;
		}
		
		/*
		onMouseRollOver
		*/
		private function onMouseRollOver(evt: MouseEvent): void 
		{
			this.labelFormat.color = this._rollOverColor;
			this._label.textFlow.hostFormat = this.labelFormat;
			this._label.textFlow.flowComposer.updateAllControllers();
		}
		
		private function onMouseRollOut(evt: MouseEvent): void 
		{
			this.labelFormat.color = this._labelColor;
			this._label.textFlow.hostFormat = this.labelFormat;
			this._label.textFlow.flowComposer.updateAllControllers();
		}
	} // class
} // package
