/*
ListItem.as
Defines an object that is ideal for displaying in a list. This object
has a TLF for displaying a label, a seperator display object, and a rollover
sprite display object.

The ListItem can represent any object that implements the IListItemObject interface.
*/
package com.slskin.ignitenetwork.components 
{	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	import fl.text.TLFTextField;
	import flash.display.DisplayObject;
	import fl.containers.UILoader;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.components.IListItemObject;
	import com.slskin.ignitenetwork.components.BlueArrow;
	import com.slskin.ignitenetwork.components.DottedSeperator;
	import com.slskin.ignitenetwork.fonts.*;
	import flash.text.Font;
	import flash.text.TextFieldAutoSize;
	import flash.text.AntiAliasType;
	import flashx.textLayout.formats.VerticalAlign;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	public class ListItem extends MovieClip 
	{
		/* Constants */
		private var HPADDING:Number = 3; //horizontal padding betweem elements in ListItem
		
		/* Member fields */
		private var labelTLF:TLFTextField; //the label text field
		private var rollOverSprite:Sprite; //sprite that displays on roll over
		private var rollOverIcon:DisplayObject; //icon to display when rolling over list item.
		private var seperator:DisplayObject; //seperator that displays at the bottom of the list item
		private var defaultFormat:TextFormat; //default format for TLF
		private var defaultHighlight:TextFormat; //default format used to highlight the label
		private var defaultFont:Font; //default font for label
		private var _itemWidth:Number; //desired width of the list item
		private var _itemHeight:Number; //desired height of the list item
		private var _itemObj:IListItemObject; //The ListItemObject that this ListItem represents
		private var _icon:UILoader; //stores the icon for 
		private var _iconSize:Number; //height and width of list item icon
		
		public function ListItem(obj:IListItemObject, itemWidth:Number, itemHeight:Number, rollOverColor:uint = 0x333333,
								 labelSize:Object = "12", labelColor:uint = 0xCCCCCC, seperator:DisplayObject = null, 
								 rollOverIcon:DisplayObject = null, labelFont:Font = null, iconSize:Number = 24) 
		{
			this._itemObj = obj;
			this.seperator = (seperator == null ? new DottedSeperator() : seperator);
			this.rollOverIcon = (rollOverIcon == null ? new BlueArrow() : rollOverIcon);
			this.defaultFont = (labelFont == null ? new TahomaRegular() : labelFont); 
			this.defaultFormat = new TextFormat(this.defaultFont.fontName, labelSize, labelColor, false, false, false);
			this.defaultHighlight = new TextFormat(this.defaultFont.fontName, labelSize, 0x990000, false, false, true);
			this._itemWidth = itemWidth;
			this._itemHeight = itemHeight;
			this._iconSize = iconSize;
			
			//create rollOver sprite
			this.createRollOverSprite(rollOverColor);
			
			//setup the label tlf
			this.setupTLF();
			
			//listen for added to stage event
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/* Getters */
		public function get targetObj():IListItemObject {
			return this._itemObj;
		}
		
		public function get itemHeight():Number {
			return this._itemHeight;
		}
		
		public function get itemWidth():Number {
			return this._itemWidth;
		}
		
		public function get iconSize():Number {
			return this._iconSize;
		}
		
		/* Setters */
		public function set selected(select:Boolean):void 
		{
			this.buttonMode = !select;
			this.useHandCursor = !select;
			if(select)
			{
				this.removeEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
				this.removeEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
				this.removeEventListener(MouseEvent.CLICK, onMouseClick);
				this.rollOverSprite.alpha = .75;
				this.rollOverIcon.visible = true;
			}
			else
			{
				this.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
				this.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
				this.addEventListener(MouseEvent.CLICK, onMouseClick);
				this.rollOverSprite.alpha = 0;
				this.rollOverIcon.visible = false;
			}
		}
		
		
		/*
		setupTLF
		Setup the label TLFTextField.
		*/
		private function setupTLF():void
		{
			this.labelTLF = new TLFTextField();
			
			with(this.labelTLF)
			{
				embedFonts = true;
				multiline = false;
				autoSize = TextFieldAutoSize.LEFT;
				antiAliasType = AntiAliasType.ADVANCED;
				selectable = false;
				text = this._itemObj.itemLabel;
				verticalAlign = VerticalAlign.MIDDLE;
				y = (this.itemHeight - this.labelTLF.height)/2; 
			}
			
			//add the default format
			this.labelTLF.setTextFormat(this.defaultFormat);
		}
		
		/*
		createRollOverSprite
		Creates the background sprite that displays when rolling over
		the list item.
		*/
		private function createRollOverSprite(color:uint):void
		{
			this.rollOverSprite = new Sprite();
			this.rollOverSprite.graphics.beginFill(color);
			this.rollOverSprite.graphics.drawRect(0, 0, this._itemWidth, this._itemHeight);
			this.rollOverSprite.graphics.endFill();
			this.rollOverSprite.alpha = 0; //hide it initially
		}
		
		/*
		appendToLabel
		Appends text to the itemTLF with the specified format (if passed in).
		*/
		public function appendToLabel(txt:String, fontSize:Object = "12", fontColor:uint = 0xCCCCCC) 
		{
			this.labelTLF.text += txt;
			var format:TextFormat = new TextFormat(this.defaultFont.fontName, fontSize, fontColor);
			this.labelTLF.setTextFormat(format, this.labelTLF.text.length - txt.length, this.labelTLF.text.length);
		}
		
		/*
		highlight
		Highlights the label within the given range with the defaultHighlight TextFormat object. 
		If no range is passed in the default behavior is to highlight the entire label.
		*/
		public function highlight(beginIndex:uint = -1, endIndex:uint = -1):void 
		{
			try 
			{
				this.labelTLF.setTextFormat(this.defaultHighlight, beginIndex, endIndex);
			}
			catch(error:RangeError) {}
		}
		
		/*
		configureHighlight
		Configures the defaultHighlight TextFormat object with the passed in
		parameters. Enabling 'bold' typeface requires embedding a new font set into the label.
		However, this method does not take a font and uses the default font for the ListItem.
		*/
		public function configureHighlight(color:uint, size:Object, italic:Boolean, underline:Boolean):void {
			this.defaultHighlight = new TextFormat(this.defaultFont.fontName, size, color, false, italic, underline);
		}
		
		/*
		clearFormat
		Sets the format back to the defaultFormat.
		*/
		public function clearFormat():void {
			this.labelTLF.setTextFormat(this.defaultFormat);
		}
		
		/*
		onAdded
		Add children display elements, listen for mouseEvents, and
		set this object to be a button.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//layout list item ui elements
			layoutListItem();
			
			//enable button mode
			this.buttonMode = true;
			this.useHandCursor = true;
			
			//listen for mouse events
			this.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			this.addEventListener(MouseEvent.CLICK, onMouseClick);
		}
		
		/*
		layoutListItem
		Horizontially displays the elements in the ListItem. This
		includes the rollOverIcon, icon, and the label.
		*/
		private function layoutListItem():void
		{
			var xPos:Number = 0;
			
			//add roll over icon
			this.rollOverIcon.visible = false;
			this.rollOverIcon.x = xPos;
			this.rollOverIcon.y = (this._itemHeight - this.rollOverIcon.height) / 2;
			this.addChildAt(this.rollOverIcon, 0);
			xPos += this.rollOverIcon.width + this.HPADDING;
			
			//Configure the icon if a path exists
			if(this._itemObj.iconPath != null)
			{
				this._icon = new UILoader();
				with(this._icon)
				{
					width = height = this.iconSize;
					maintainAspectRatio = true;
					scaleContent = true;
					x = xPos;
					y = (this._itemHeight - this._icon.height) / 2;
				}
				
				this.addChild(this._icon);
				xPos += this._icon.width + this.HPADDING;
				
				//load the icon and add error event handling
				this._icon.addEventListener(IOErrorEvent.IO_ERROR, onIconLoadError);
				this._icon.load(new URLRequest(this._itemObj.iconPath));
			}
			
			//add the TLF
			this.labelTLF.x = xPos;
			this.addChild(this.labelTLF);

			
			//add seperator under the itemTLF
			this.seperator.y = this._itemHeight;
			this.addChild(this.seperator);
			
			//add screen (hide it initially) and listen for mouse events to activate it
			this.addChildAt(this.rollOverSprite, 0);
		}
		
		/*
		onIconLoadError
		The error handling will fail gracefully.
		If there is an IOError when trying to load the icon,
		simply move the label TLF over to the left.
		*/
		private function onIconLoadError(evt:IOErrorEvent):void {
			this.labelTLF.x -= this.iconSize;
		}
		
		/* Mouse Event Handlers */
		private function onMouseRollOver(evt:MouseEvent):void {
			this.rollOverSprite.alpha = .5;
			this.rollOverIcon.visible = true;
		}
		
		private function onMouseRollOut(evt:MouseEvent):void {
			this.rollOverSprite.alpha = 0;
			this.rollOverIcon.visible = false;
		}
		
		/*
		onMouseClick
		Dispatch an SLEvent passing this object as a parameter.
		*/
		private function onMouseClick(evt:MouseEvent):void {
			this.dispatchEvent(new SLEvent(SLEvent.LIST_ITEM_CLICK, this));
			//trace("ListItem Clicked " + this._itemObj.itemLabel);
		}
		
	} //class
}//package
