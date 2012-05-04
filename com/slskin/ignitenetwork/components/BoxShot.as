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
	import com.slskin.ignitenetwork.views.desktop.AppDetailsView;
	import flash.events.MouseEvent;
	import com.slskin.ignitenetwork.events.SLEvent;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import com.slskin.ignitenetwork.apps.Application;
	import com.slskin.ignitenetwork.components.CountBubble;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	
	public class BoxShot extends MovieClip 
	{
		/* Constants */
		public static const BOX_WIDTH:Number = 103; //width of box image
		public static const BOX_HEIGHT:Number = 147; //height of box image - about 1:sqrt(2)
		public static const LABEL_HEIGHT:Number = 40; //height of the ListItem label - including padding.
		public static const LABEL_PADDING:Number = 3; //padding between box image and label.
		private const SHOW_DETAILS_SECONDS:Number = 1.0; //number of rollover seconds until the details is shown.
		private const HIDE_DETAILS_SECONDS:Number = 1.0; //number of rollover seconds until the details is hidden.
		private const LABEL_FONT_SIZE:String = "10";
		private const LABEL_FONT_COLOR:uint = 0xcccccc;
		private const LABEL_BG_COLOR:uint = 0x333333;
		
		public static var appDetails:AppDetailsView;
				
		/* Member fields */
		private var _label:ListItem; //displays the app name and icon under the box shot
		private var app:Application; //reference the to application this BoxShot represents
		private var main:Main; //reference to the document class.
		private var image:UILoader; //loads the box art image.
		private var sessionsBubble:CountBubble;
		private var launchButton:LaunchButton;
		private var showDetailsTimer:Timer;
		private var hideDetailsTimer:Timer;
		
		public function BoxShot(dp:Application) 
		{
			this.app = dp;
			this.launchButton = new LaunchButton();
			this.sessionsBubble = new CountBubble();
			this.showDetailsTimer = new Timer(this.SHOW_DETAILS_SECONDS * 1000);
			this.hideDetailsTimer = new Timer(this.HIDE_DETAILS_SECONDS * 1000);
			this.hideDetailsTimer.addEventListener(TimerEvent.TIMER, onHideDetailsTimer);
			this.showDetailsTimer.addEventListener(TimerEvent.TIMER, onShowDetailsTimer);
			
			if(BoxShot.appDetails == null)
				BoxShot.appDetails = new AppDetailsView();
			
			//create app label
			_label = new ListItem(dp, BoxShot.BOX_WIDTH, BoxShot.LABEL_HEIGHT, LABEL_BG_COLOR, LABEL_FONT_SIZE, LABEL_FONT_COLOR);
			_label.y = BOX_HEIGHT + BoxShot.LABEL_PADDING;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onInitAdded);
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		public function get dataProvider():Application {
			return this.app;
		}
		
		public function get label():ListItem {
			return this._label;
		}
		
		private function onInitAdded(evt:Event):void 
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onInitAdded);
			this.main = (root as Main);
			
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
			this.image.load(new URLRequest(this.app.imagePath));
			
			//add drop shadow to this object and the active sessions bubble
			this.filters = [new DropShadowFilter(2, 45, 0, 1, 4, 4, 1, 15)];
			this.sessionsBubble.filter = [new DropShadowFilter(2, 45, 0, 1, 4, 4, 1, 15)];
			
			//add launch button and listen for events
			this.launchButton.y = (BoxShot.BOX_HEIGHT - this.launchButton.height) / 2;
			this.launchButton.visible = false;
			addChild(this.launchButton);
		}
		
		private function onAdded(evt:Event):void 
		{
			main.model.addEventListener(SLEvent.VALUE_ADDED, this.checkActiveSessions);
			this.updateActiveSessions();
		}
		
		private function onRemoved(evt:Event):void {
			main.model.removeEventListener(SLEvent.VALUE_ADDED, this.checkActiveSessions);
		}
		
		private function onAppDetailsRemoved(evt:Event):void {
			this.label.selected = false;
		}
		
		/*
		checkActiveSessions
		Check the model to see if this app has any active sessions. This check
		is an event handler for the model VALUE_ADDED event.
		*/
		private function checkActiveSessions(evt:SLEvent):void 
		{
			var split:Array = String(evt.argument).split(main.model.DIM);
			var key:String = split[0];
			switch (key) 
			{
				case main.model.DATA_PATH + "Application_" + this.app.appID + "_ActiveSessions":
					this.updateActiveSessions();
			}
		}
		
		/*
		updateActiveSessions
		Updates the active sessions CountBubble with the data from the model.
		*/
		private function updateActiveSessions():void 
		{
			var sessions:String = main.model.getProperty("Application_" + this.app.appID + "_ActiveSessions", main.model.DATA_PATH);
			if(sessions != null && sessions.length > 0)
			{
				//SL sends over a string with formatting data - parse out the number
				sessions = Number(sessions.match(/\d+/)).toString();
				
				//add session bubble to stage if we need to.
				if(this.sessionsBubble.stage == null)
				{
					this.sessionsBubble.x = BoxShot.BOX_WIDTH - (this.sessionsBubble.width * (3/4));
					this.sessionsBubble.y = (this.sessionsBubble.height / 4) * -1;
					this.addChild(this.sessionsBubble);
				}
				
				this.sessionsBubble.countTLF.text = sessions;
			}
			else if(this.sessionsBubble.stage != null)
				this.removeChild(this.sessionsBubble);
		}
		
		
		/*
		onShowDetailsTimer
		Show the AppDetailsView on timer tick.
		*/
		private function onShowDetailsTimer(evt:TimerEvent):void 
		{
			this.showDetailsTimer.stop();
			
			//listen for details rollover to stop hiding timer.
			BoxShot.appDetails.addEventListener(MouseEvent.ROLL_OVER, this.onDetailsRollOver);
			BoxShot.appDetails.addEventListener(MouseEvent.ROLL_OUT, this.onDetailsRollOut);
			
			//calculate the where the user rolled over taking into consideration the cursor height
			var cursorHeight:Number = 20;
			var yPos:Number = this.mouseY + (cursorHeight / 2);
			if(yPos > BoxShot.BOX_HEIGHT)
			   yPos -= cursorHeight / 2;
			else if(yPos <= cursorHeight)
				yPos += cursorHeight / 2;
			 
			//convert the local point to a global point.
			var point:Point = new Point(BoxShot.BOX_WIDTH, yPos);
			point = this.localToGlobal(point);
			BoxShot.appDetails.x = point.x;
			BoxShot.appDetails.y = point.y;
			
			if(BoxShot.appDetails.stage == null)
			{
				BoxShot.appDetails.app = this.app;
				this.main.addChild(BoxShot.appDetails);
				BoxShot.appDetails.addEventListener(Event.REMOVED_FROM_STAGE, this.onAppDetailsRemoved);
				this.label.selected = true;
			}
		}
		
		/*
		onHideDetailsTimer
		Remove the AppDetailsView on hide timer tick.
		*/
		private function onHideDetailsTimer(evt:TimerEvent):void 
		{
			this.hideDetailsTimer.stop();
			
			BoxShot.appDetails.removeEventListener(MouseEvent.ROLL_OVER, this.onDetailsRollOver);
			BoxShot.appDetails.removeEventListener(MouseEvent.ROLL_OUT, this.onDetailsRollOut);
			
			//remove app details
			if(BoxShot.appDetails != null && BoxShot.appDetails.stage != null)
			{
				this.main.removeChild(BoxShot.appDetails);
				BoxShot.appDetails.removeEventListener(Event.REMOVED_FROM_STAGE, this.onAppDetailsRemoved);
				this.label.selected = false;
			}
		}
		
		/*
		onImageLoadError
		Log the error and load the diagonal lines background.
		*/
		private function onImageLoadError(evt:IOErrorEvent):void {
			//this.main.log("Failed to load BoxShot. " + evt.text);
			this.addChildAt(new DiagonalLines(), 0);
		}
		
		/*
		onMouseOver
		Start the details timer and show the launch button.
		*/
		private function onMouseOver(evt:MouseEvent):void 
		{
			this._label.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
			this.launchButton.visible = true;
			this.showDetailsTimer.start();
					
			if(BoxShot.appDetails.stage != null)
				this.hideDetailsTimer.stop();
		}
		
		/*
		onMouseOut
		Hide the launch button and stop details timer.
		*/
		private function onMouseOut(evt:MouseEvent):void 
		{
			this._label.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			this.launchButton.visible = false;
			this.showDetailsTimer.stop();
			this.hideDetailsTimer.start();
		}
		
		private function onDetailsRollOver(evt:MouseEvent):void {
			this.hideDetailsTimer.stop();
		}
		
		private function onDetailsRollOut(evt:MouseEvent):void {
			this.hideDetailsTimer.start();
		}
		
		private function onClick(evt:MouseEvent):void {
			this.dispatchEvent(new SLEvent(SLEvent.LIST_ITEM_CLICK, this));
		}
		
	} //class
} //package
