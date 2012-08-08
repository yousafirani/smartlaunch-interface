/**
 * ListItem.as
 * Defines an object that is ideal for displaying in a list. This object
 * has a TLF for displaying a label, a seperator display object, and a rollover
 * sprite display object.
 *
 * The ListItem can represent any object that implements the IListItemObject interface.
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
	import com.slskin.ignitenetwork.Main;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.components.IListItem;
	import com.slskin.ignitenetwork.fonts.*;
	import flash.text.Font;
	import flash.text.AntiAliasType;
	import flashx.textLayout.formats.VerticalAlign;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flashx.textLayout.formats.TextLayoutFormat;
	
	public class ListItem extends MovieClip 
	{
		/* Constants */
		private var HPADDING: Number = 3; // horizontal padding betweem elements in ListItem
		private var ROLLOVER_ALPHA: Number = .5; // alpha to apply to roll over sprite onRollOver
		private var SELECTED_ALPHA: Number = .75; // alpha to apply to roll over sprite when selected
		
		/* Member fields */
		private var labelTLF: TLFTextField; // the label text field
		private var rollOverSprite: Sprite; // sprite that displays on roll over
		private var seperator: DisplayObject; // seperator that displays at the bottom of the list item
		private var defaultFormat: TextFormat; // default format for TLF
		private var defaultHighlight: TextFormat; // default format used to highlight the label
		private var defaultFont: Font; // default font for label
		private var _itemWidth: Number; // desired width of the list item
		private var _itemHeight: Number; // desired height of the list item
		private var _dp: IListItem; // the dataprovider that this ListItem represents
		private var _icon: UILoader; // stores the icon for 
		private var _iconSize: Number; // height and width of list item icon
		private var _selected: Boolean; // indicates if the item is selected.
		private var _highlightStart: int; // stores the start index of the highlight
		private var _highlightEnd: int; // stores the end index of the highlight.
		
		public function ListItem(dp: IListItem, itemWidth: Number, itemHeight: Number, rollOverColor: uint = 0x333333,
								 labelSize: Object = "12", labelColor: uint = 0xCCCCCC, seperator: DisplayObject = null, 
								 labelFont: Font = null, iconSize: Number = 16) 
		{
			this._dp = dp;
			this.seperator = seperator;
			this.defaultFont = (labelFont == null ? new TahomaBold() :  labelFont); 
			this.defaultFormat = new TextFormat(this.defaultFont.fontName, labelSize, labelColor, false, false, false);
			this.defaultHighlight = new TextFormat(this.defaultFont.fontName, labelSize, 0xFFFFFF, true, false, true);
			this._itemWidth = itemWidth;
			this._itemHeight = itemHeight;
			this._iconSize = iconSize;
			
			// create rollOver sprite
			this.createRollOverSprite(rollOverColor);
			
			// setup the label tlf
			this.setupTLF();
			
			// listen for added to stage event
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/* Getters */
		public function get dataProvider(): IListItem {
			return this._dp;
		}
		
		public function get itemHeight(): Number {
			return this._itemHeight;
		}
		
		public function get itemWidth(): Number {
			return this._itemWidth;
		}
		
		public function get iconSize(): Number {
			return this._iconSize;
		}
		
		public function get highlightStart(): int {
			return this._highlightStart;
		}
		
		public function get highlightEnd(): int {
			return this._highlightEnd;
		}
		
		/* Setters */
		public function set selected(select: Boolean): void {
			this._selected = select;
			this.rollOverSprite.alpha = (select ? this.SELECTED_ALPHA :  0);
		}
		
		public function set seperatorVisible(visible: Boolean): void {
			if (this.seperator != null)
				this.seperator.visible = visible;
		}
		
		/**
		 * Setup the label TLFTextField.
		 */
		private function setupTLF(): void
		{
			this.labelTLF = new TLFTextField();
			with(this.labelTLF)
			{
				width = this._itemWidth;
				height = this._itemHeight;
				defaultTextFormat = this.defaultFormat;
				embedFonts = true;
				multiline = false;
				selectable = false;
				antiAliasType = AntiAliasType.ADVANCED;
				text = this._dp.itemLabel;
				verticalAlign = VerticalAlign.MIDDLE;
				paddingRight = paddingLeft = this.HPADDING;
			}
			
			this.labelTLF.setTextFormat(this.defaultFormat);
			this.labelTLF.textFlow.flowComposer.updateAllControllers();
		}
		
		/**
		 * Creates the background sprite that displays when rolling over
		 * the list item.
		 */
		private function createRollOverSprite(color: uint): void
		{
			this.rollOverSprite = new Sprite();
			this.rollOverSprite.graphics.beginFill(color);
			this.rollOverSprite.graphics.drawRect(0, 0, this._itemWidth, this._itemHeight);
			this.rollOverSprite.graphics.endFill();
			this.rollOverSprite.alpha = 0;
		}
		
		/**
		 * Highlights the label within the given range with the defaultHighlight TextFormat object. 
		 * If no range is passed in the default behavior is to highlight the entire label.
		 */
		public function highlight(beginIndex: int = -1, endIndex: int = -1): void 
		{
			try 
			{
				this.labelTLF.setTextFormat(this.defaultHighlight, beginIndex, endIndex);
				this._highlightStart = beginIndex;
				this._highlightEnd = endIndex;
				this.labelTLF.textFlow.flowComposer.updateAllControllers();
			}
			catch(error: RangeError) {}
		}
		
		/**
		 * Configures the defaultHighlight TextFormat object with the passed in
		 * parameters. Enabling 'bold' typeface requires embedding a new font set into the label.
		 * However, this method does not take a font and uses the default font for the ListItem.
		 */
		public function configureHighlight(color: uint, size: Object, italic: Boolean, underline: Boolean): void {
			this.defaultHighlight = new TextFormat(this.defaultFont.fontName, size, color, false, italic, underline);
		}
		
		/**
		 * Sets the format back to the defaultFormat.
		 */
		public function clearFormat(): void {
			this.labelTLF.setTextFormat(this.defaultFormat);
			this.labelTLF.textFlow.flowComposer.updateAllControllers();
		}
		
		/**
		 * Add children display elements, listen for mouseEvents, and
		 * set this object to be a button.
		 */
		private function onAdded(evt: Event): void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			// layout list item ui elements
			layoutListItem();
			
			// add dataprovider id to label if set
			if ((root as Main).model.getProperty("showAppIDs") == "1")
				this.labelTLF.appendText(" (" + this._dp.itemID + ")");
			
			// enable button mode
			this.buttonMode = true;
			this.useHandCursor = true;
			
			// listen for mouse events
			this.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			this.addEventListener(MouseEvent.CLICK, onMouseClick);
		}
		
		/**
		 * Horizontially displays the elements in the ListItem. This
		 * includes the rollOverIcon, icon, and the label.
		 */
		private function layoutListItem(): void
		{
			var xPos: Number = this.HPADDING * 2;
			
			// Configure the icon if a path exists
			if (this._dp.iconPath != null)
			{
				this._icon = new UILoader();
				with(this._icon)
				{
					width = height = this.iconSize;
					maintainAspectRatio = true;
					scaleContent = true;
					x = xPos;
					y = (this._itemHeight - this.iconSize) / 2;
				}
				
				this.addChild(this._icon);
				xPos += this._icon.width + this.HPADDING;
				
				// load the icon and add error event handling
				this._icon.addEventListener(IOErrorEvent.IO_ERROR, onIconLoadError);
				this._icon.load(new URLRequest(this._dp.iconPath));
			}
			
			// add the TLF
			this.labelTLF.x = xPos;
			this.labelTLF.width -= xPos;
			this.addChild(this.labelTLF);

			// add seperator under the itemTLF
			if (this.seperator != null)
			{
				this.seperator.y = this._itemHeight;
				this.addChild(this.seperator);
			}
			
			// add screen (hide it initially) and listen for mouse events to activate it
			this.addChildAt(this.rollOverSprite, 0);
		}
		
		/**
		 * The error handling will fail gracefully.
		 * If there is an IOError when trying to load the icon,
		 * simply move the label TLF over to the left.
		 */
		private function onIconLoadError(evt: IOErrorEvent): void {
			this.labelTLF.x -= this.iconSize;
		}
		
		/* Mouse Event Handlers */
		private function onMouseRollOver(evt: MouseEvent): void {
			this.rollOverSprite.alpha = this.ROLLOVER_ALPHA;
			evt.stopPropagation();
		}
		
		private function onMouseRollOut(evt: MouseEvent): void {
			this.rollOverSprite.alpha = (this._selected ? this.SELECTED_ALPHA :  0);
			evt.stopPropagation();
		}
		
		/**
		 * Dispatch an SLEvent passing this object as a parameter.
		 */
		private function onMouseClick(evt: MouseEvent): void {
			this.dispatchEvent(new SLEvent(SLEvent.LIST_ITEM_CLICK, this));
		}
	} // class
}// package
