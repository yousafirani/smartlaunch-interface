package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import fl.containers.UILoader;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	import flash.filters.DropShadowFilter;
	import com.slskin.ignitenetwork.Main;
	import flash.events.MouseEvent;
	import com.slskin.ignitenetwork.events.SLEvent;
	
	public class BoxShot extends MovieClip 
	{
		/* Constants */
		public static const BOX_WIDTH:Number = 103; //width of box image
		public static const BOX_HEIGHT:Number = 147; //height of box image - about 1:sqrt(2)
		public static const LABEL_HEIGHT:Number = 40; //height of the ListItem label - including padding.
		public static const LABEL_PADDING:Number = 3; //padding between box image and label.
		private const LABEL_FONT_SIZE:String = "10";
		private const LABEL_FONT_COLOR:uint = 0xcccccc;
		private const LABEL_BG_COLOR:uint = 0x333333;

		/* Member fields */
		private var _label:ListItem; //displays the app name and icon under the box shot
		private var _dp:IListItem; //dataprovider for this box shot
		private var image:UILoader; //loads the box art image.
		private var launchButton:LaunchButton;
		
		public function BoxShot(dp:IListItem) 
		{
			this._dp = dp;
			this.launchButton = new LaunchButton();
			
			//create app label
			_label = new ListItem(dp, BoxShot.BOX_WIDTH, BoxShot.LABEL_HEIGHT, LABEL_BG_COLOR, LABEL_FONT_SIZE, LABEL_FONT_COLOR);
			_label.y = BOX_HEIGHT + BoxShot.LABEL_PADDING;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function get dataProvider():IListItem {
			return this._dp;
		}
		
		public function get label():ListItem {
			return this._label;
		}
		
		private function onAdded(evt:Event):void 
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			addChild(this._label);
			
			//enable mouse listeners
			this.buttonMode = this.useHandCursor = true;
			this.addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			this.addEventListener(MouseEvent.CLICK, onClick);
			
			//create a load image
			this.image = new UILoader();
			with(this.image)
			{
				width = BoxShot.BOX_WIDTH;
				height = BoxShot.BOX_HEIGHT;
				maintainAspectRatio = true;
				scaleContent = true;
			}
			
			addChild(this.image);
			
			this.image.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadError);
			this.image.load(new URLRequest(this._dp.imagePath));
			
			//add drop shadow to this object
			this.filters = [new DropShadowFilter(2, 45, 0, 1, 4, 4, 1, 15)];
			
			//add launch button and listen for events
			this.launchButton.y = (BoxShot.BOX_HEIGHT - this.launchButton.height) / 2;
			this.launchButton.visible = false;
			addChild(this.launchButton);
		}
		
		/*
		onImageLoadError
		Log the error and load the diagonal lines background.
		*/
		private function onImageLoadError(evt:IOErrorEvent):void 
		{
			(root as Main).log("Failed to load BoxShot. " + evt.text);
			this.addChildAt(new DiagonalLines(), 0);
		}
		
		private function onMouseOver(evt:MouseEvent):void 
		{
			this._label.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
			this.launchButton.visible = true;
		}
		
		private function onMouseOut(evt:MouseEvent):void 
		{
			this._label.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			this.launchButton.visible = false;
		}
		
		private function onClick(evt:MouseEvent):void {
			this.dispatchEvent(new SLEvent(SLEvent.LIST_ITEM_CLICK, this));
		}
		
	} //class
} //package
