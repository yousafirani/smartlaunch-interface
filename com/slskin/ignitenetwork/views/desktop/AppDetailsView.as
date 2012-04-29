/*
AppDetailsView.as
Defines the view that loads and displays application
details. This includes app description, image path, and
additional application details.
*/
package com.slskin.ignitenetwork.views.desktop 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.text.TextFieldAutoSize;
	import com.slskin.ignitenetwork.apps.Application;
	import com.slskin.ignitenetwork.fonts.MyriadRegular;
	import fl.text.TLFTextField;
	import flash.text.TextFormat;
	import fl.controls.UIScrollBar;
	import fl.containers.ScrollPane;
	import com.slskin.ignitenetwork.Main;
	import com.slskin.ignitenetwork.Language;
	import com.slskin.ignitenetwork.events.SLEvent;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	import fl.containers.UILoader;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import fl.transitions.*;
	
	public class AppDetailsView extends MovieClip 
	{
		/* Constants */
		private var APP_IMAGE:String = "image.jpg";
		private var APP_WALLPAPER:String = "wallpaper.jpg";
		private var IMAGE_WIDTH:Number = 320;
		private var IMAGE_HEIGHT:Number = 240;
		
		/* Member Fields */
		private var currentApp:Application; //current displayed app
		private var main:Main; //reference to main doc class
		private var detailsTLF:TLFTextField; //a reference to the details tlf in the AppDetailsView clip
		private var titleFormat:TextFormat; //text format used for the app title
		private var detailsFormat:TextFormat; //text format used for the app details
		private var fadeTween:Tween; //used to fade the app image in and out.
		
		public function AppDetailsView() 
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//create text formats.
			this.titleFormat = new TextFormat(new MyriadRegular().fontName, "30", 0x000000);
			this.detailsFormat = new TextFormat(new MyriadRegular().fontName, "13", 0x666666);
		}
		
		/*
		onAdded
		Event handler for added to stage event.
		*/
		private function onAdded(evt:Event):void
		{
			//set reference to main
			this.main = (root as Main);
			
			//hide loader
			this.loader.visible = false;
			
			//store a reference to the details field
			this.detailsTLF = this.detailsField;
			
			//setup autoSize for the details field
			this.detailsTLF.autoSize = TextFieldAutoSize.LEFT;
			this.detailsPane.source = this.detailsTLF;
			this.setPaneStyle();
			
			//setup app info button
			this.appStatus.appInfoButton.addEventListener(MouseEvent.CLICK, onMoreInfoClick);
			this.appStatus.appInfoButton.addEventListener(MouseEvent.ROLL_OVER, onMoreInfoRollOver);
			this.appStatus.appInfoButton.addEventListener(MouseEvent.ROLL_OUT, onMoreInfoRollOut);
		}
		
		
		/*
		loadApp
		Requests details from the SL client about the passed in application
		and waits for a reponse event.
		*/
		public function loadApp(app:Application):void
		{
			//show loader 
			this.loader.visible = true;
			
			if(ExternalInterface.available)
				ExternalInterface.call("GetApplicationDetails", app.appID);
				
			//set reference to current app
			this.currentApp = app;
			
			//listen for ApplicationDetailsReceived Event
			main.model.addEventListener(SLEvent.APP_DETAILS_RECEIVED, onAppDetailsReceived);
		}
		
		/*
		onAppDetailsReceived
		Sets the application details received from the SL client.
		*/
		private function onAppDetailsReceived(evt:SLEvent):void
		{
			//remove the listener after we have received the details.
			main.model.removeEventListener(SLEvent.APP_DETAILS_RECEIVED, onAppDetailsReceived);
			
			//get app details that were received.
			var headline:String = main.model.getProperty("Application_Headline", main.model.APP_DATA_PATH);
			var details:String = main.model.getProperty("Application_Description", main.model.APP_DATA_PATH);
			
			//write the app id to the debug console
			if(this.main.debugger.debug)
				this.main.debugger.write("==> Loaded Application ID: " + this.currentApp.appID);
						
			//hide loader
			this.loader.visible = false;
			
			//set button label
			var buttonLabel:String = Language.translate("Start", "Start") + " " + this.currentApp.appName;
			
			//set the details tlf and appropriate formats
			this.setGameDetails(headline, details);
			
			//load images
			this.loadAppImages();
			
			//setup the app status
			this.setAppStatus();
		}
		
		/*
		loadAppImages
		Loads the APP_IMAGE and changes the wallpaper to
		the game specific wallpaper.
		*/
		private function loadAppImages():void
		{
			if(this.currentApp != null)
			{
				//this.image.visible = false;
				//this.image.loader.load(new URLRequest(this.currentApp.assetPath + this.APP_IMAGE));
				
				//load app sepecifc wallpaper
				this.main.wallpaperManager.loadImage(this.currentApp.assetPath + this.APP_WALLPAPER);
				this.main.wallpaperManager.stopTimer();
			}
		}
		
		/*
		onImageLoadComplete
		Event handler for UILoader load complete. Transition in UILoader.
		*/
		private function onImageLoadComplete(evt:Event):void {
			//TransitionManager.start(this.image, {type:Iris, direction:Transition.IN, duration:1, easing:Strong.easeOut});
		}
		
		
		/*
		setGameDetails
		Sets the game headline and game details in the deatils TLF
		with the correct TextFormat.
		*/
		private function setGameDetails(headline:String, details:String):void
		{
			if(headline == null || details == null)
				this.detailsTLF.text = "...";
			else
			{
				this.detailsTLF.htmlText = headline + "  " + details;
				this.detailsTLF.setTextFormat(this.titleFormat, 0, headline.length);
				this.detailsTLF.setTextFormat(this.detailsFormat, headline.length, this.detailsTLF.length);
			}
			
			//make sure the scroll pane updates!
			this.detailsPane.update();
		}
		
		
		/*
		setAppStatus
		Configures the application status section depending on the application details. This
		includes information about the current amount of local players, if the game is multiplayer,
		online, or singleplayer, and the link to the app website.
		*/
		private function setAppStatus():void
		{
			var appType:String = main.model.getProperty("Application_Type", main.model.APP_DATA_PATH);
			var statusStr:String = main.model.getProperty("Application_Status", main.model.APP_DATA_PATH);
			
			//TO DO: Get the client to actually send over this data outside of a string. In this current
			//state this will not work with multiple languages because I am parsing the string for english words.
			var tlf:TLFTextField = new TLFTextField();
			tlf.htmlText = statusStr;
			statusStr = tlf.text;
			
			if(appType == "Game")
			{
				this.appStatus.sessionsTLF.text = Number(statusStr.match(/\d+/));
				this.appStatus.singleplayerStatus.gotoAndStop((statusStr.search("Singleplayer") != -1).toString());
				this.appStatus.multiplayerStatus.gotoAndStop((statusStr.search("Multiplayer") != -1).toString());
				this.appStatus.onlineStatus.gotoAndStop((statusStr.search("Online") != -1).toString());
			}
			else if(appType == "Program")
			{
				this.appStatus.sessionsTLF.text = "0";
				this.appStatus.singleplayerStatus.gotoAndStop("false");
				this.appStatus.multiplayerStatus.gotoAndStop("false");
				this.appStatus.onlineStatus.gotoAndStop("false");
			}
		}

		
		/*
		onMoreInfoClick
		Make external call to sl client to load app website.
		*/
		private function onMoreInfoClick(evt:MouseEvent):void
		{
			if(this.currentApp == null) return;
			
			trace("Launching application website...");
			if(ExternalInterface.available)
				ExternalInterface.call("LaunchApplicationWebsite", this.currentApp.appID);
		}
		
		/*
		onMoreInfoRollOver
		*/
		private function onMoreInfoRollOver(evt:MouseEvent):void {
			this.appStatus.moredetailsTLF.textColor = 0x000000;
		}
		
		/*
		onMoreInfoRollOut
		*/
		private function onMoreInfoRollOut(evt:MouseEvent):void {
			this.appStatus.moredetailsTLF.textColor = 0x666666;
		}
		
		/*
		setPaneStyle
		Configure the Details ScrollPane with a custom skin.
		*/
		private function setPaneStyle():void
		{
			with(this.detailsPane)
			{
				//set scrollPane scrollbar width
				setStyle("scrollBarWidth", 8);
			
				//hide arrows
				setStyle("scrollArrowHeight", 0);
			
				//setup track
				setStyle("trackUpSkin", ScrollTrack_Invisible);
				setStyle("trackOverSkin", ScrollTrack_Invisible);
				setStyle("trackDownSkin", ScrollTrack_Invisible);
			
				//setup thumb
				setStyle("thumbUpSkin", ScrollThumb_Up_Light);
				setStyle("thumbOverSkin", ScrollThumb_Up_Light);
				setStyle("thumbDownSkin", ScrollThumb_Up_Light);
				setStyle("thumbIcon", thumbIcon_Light);
			
				//down arrow
				setStyle("downArrowUpSkin", ArrowSkin_Invisible); 
				setStyle("upArrowUpSkin", ArrowSkin_Invisible);
			} 
		}
		
	} //class
}//package
