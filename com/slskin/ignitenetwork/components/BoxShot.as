package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import fl.containers.UILoader;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	import flash.filters.DropShadowFilter;
	import com.slskin.ignitenetwork.apps.Application;
	import com.slskin.ignitenetwork.Main;

	com.slskin.ignitenetwork.components.DiagonalLines;
	
	public class BoxShot extends MovieClip 
	{
		/* Constants */
		public static const BOX_WIDTH:Number = 103; //width of box image
		public static const BOX_HEIGHT:Number = 147; //height of box image - about 1:sqrt(2)
		public static const LABEL_HEIGHT:Number = 40; //height of the ListItem label.
		private const LABEL_FONT_SIZE:String = "10";
		private const LABEL_FONT_COLOR:uint = 0xcccccc;
		private const LABEL_BG_COLOR:uint = 0x333333;
		private const LABEL_PADDING:Number = 2; //padding between box image and label.

		/* Member fields */
		private var appLabel:ListItem; //displays the app name and icon under the box shot
		private var app:Application; //dataprovider for this box shot
		private var bg:Sprite; //box shot background.
		private var image:UILoader; //loads the box art image.
		
		public function BoxShot(app:Application) 
		{
			this.app = app;
			
			//create app label
			appLabel = new ListItem(app, BoxShot.BOX_WIDTH, BoxShot.LABEL_HEIGHT, LABEL_BG_COLOR, LABEL_FONT_SIZE, LABEL_FONT_COLOR);
			appLabel.seperatorVisible = false;
			appLabel.y = BOX_HEIGHT + LABEL_PADDING;
			
			//create box shot background
			bg = new Sprite();
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(evt:Event):void 
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			addChild(this.appLabel);
			addChild(new DiagonalLines());
			addChild(this.bg);
			
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
			
			this.image.addEventListener(IOErrorEvent.IO_ERROR, onIconLoadError);
			this.image.load(new URLRequest(this.app.imagePath));
			
			//add drop shadow to this object
			this.filters = [new DropShadowFilter(2, 45, 0, 1, 4, 4, 1, 15)];
		}
		
		private function onIconLoadError(evt:IOErrorEvent):void {
			(root as Main).log("Failed to load BoxShot. " + evt.text);
		}
		
	} //class
} //package
