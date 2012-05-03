﻿/*
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
	import com.slskin.ignitenetwork.fonts.TahomaRegular;
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
	import fl.transitions.easing.*;
	import fl.transitions.*;
	import flash.display.Sprite;
	
	public class AppDetailsView extends MovieClip 
	{
		private const WIN_MIN_HEIGHT:Number = 120; //min height of window.
		private const WIN_MAX_HEIGHT:Number = 300; //max height of window.
		private const DESC_START_X:Number = 32; //start x for content to fit into window
		private const DESC_START_Y:Number = 70; //start y for content to fit into window
		
		/* Member Fields */
		private var currentApp:Application; //reference to current application
		private var main:Main; //reference to main doc class
		private var defaultFormat:TextFormat; //default text format used for title
		private var rollOverFormat:TextFormat; //rollover text format used for title
		private var descTLF:TLFTextField; //hold the description of the application
		private var scrollPane:ScrollPane;
		
		public function AppDetailsView() 
		{
			//create text formats for title
			this.defaultFormat = new TextFormat(new MyriadRegular().fontName, "22", 0xFFFFFF, false, false, false);
			this.rollOverFormat = new TextFormat(new MyriadRegular().fontName, "22", 0xFFFFFF, false, false, true);
			
			//create app description field
			this.descTLF = new TLFTextField();
			with(this.descTLF)
			{
				defaultTextFormat = new TextFormat(new TahomaRegular().fontName, "11", 0xcccccc);
				selectable = false;
				embedFonts = true;
				antiAliasType = "advanced";
				mutiline = wordWrap = true;
				autoSize = "left";
				x = DESC_START_X;
				y = DESC_START_Y;
				paddingLeft = 3;
				paddingRight = 10;
			}
			
			this.addEventListener(Event.ADDED_TO_STAGE, onInitAdded);
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		public function set app(app:Application):void {
			this.currentApp = app;
		}
		
		/* 
		onInitAdded
		Called the first time the appDetailsView is added to stage. 
		*/
		private function onInitAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onInitAdded);
			
			//set reference to main
			this.main = (root as Main);
			
			//hide loader
			this.loader.visible = false;
			
			this.scrollPane = new ScrollPane();
			this.setPaneStyle();
			this.scrollPane.x = this.DESC_START_X;
			this.scrollPane.y = this.DESC_START_Y;
			this.scrollPane.width = this.bg.width - 2;
			this.scrollPane.horizontalScrollPolicy = "off";
			addChild(this.scrollPane);
			
			//add description tlf and scroll pane
			this.descTLF.width = this.bg.width;
			this.addChild(this.descTLF);
			
			this.scrollPane.source = this.descTLF;
			
			//setup title button
			this.content.titleTLF.buttonMode = this.content.titleTLF.useHandCursor = true;
			this.content.titleTLF.addEventListener(MouseEvent.CLICK, this.onTitleClick);
			this.content.titleTLF.addEventListener(MouseEvent.ROLL_OVER, onTitleRollOver);
			this.content.titleTLF.addEventListener(MouseEvent.ROLL_OUT, onTitleRollOut);
			this.content.moreInfoButton.addEventListener(MouseEvent.CLICK, onMoreInfoClick);
		}
		
		private function onAdded(evt:Event):void 
		{
			//show loader 
			this.loader.visible = true;
			this.content.visible = false;
			this.descTLF.visible = false;
			this.scrollPane.visible = false;
			this.bg.height = WIN_MIN_HEIGHT;
			
			
			if(this.currentApp == null) {
				this.content.titleTLF.text = "No App Defined";
				return;
			}
			
			//Requests details from the SL client about current app
			main.model.addEventListener(SLEvent.APP_DETAILS_RECEIVED, onAppDetailsReceived);
			if(ExternalInterface.available)
				ExternalInterface.call("GetApplicationDetails", this.currentApp.appID);
		}
		
		private function onRemoved(evt:Event):void {
			main.model.removeEventListener(SLEvent.APP_DETAILS_RECEIVED, onAppDetailsReceived);
		}
		
		/*
		onAppDetailsReceived
		Sets the application details received from the SL client.
		*/
		private function onAppDetailsReceived(evt:SLEvent):void
		{
			//remove the listener after we have received the details.
			main.model.removeEventListener(SLEvent.APP_DETAILS_RECEIVED, onAppDetailsReceived);
			
			//hide loader
			this.loader.visible = false;
			
			//get app details that were received.
			var headline:String = main.model.getProperty("Application_Headline", main.model.APP_DATA_PATH);
			var details:String = main.model.getProperty("Application_Description", main.model.APP_DATA_PATH);
			
			this.content.titleTLF.text = headline;
			this.descTLF.text = details;
			this.descTLF.textFlow.flowComposer.updateAllControllers();
			this.scrollPane.update();
			
			//write the app id to the debug console
			this.main.debugger.write("Loaded Application ID: " + this.currentApp.appID);
			
			//setup the app status
			this.setAppStatus();
			this.adjustHeight();
			
			//show content
			this.content.visible = true;
			this.descTLF.visible = true;
			this.scrollPane.visible = true;
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
				this.toggleGameStats(true);
				this.content.sessionsTLF.text = Number(statusStr.match(/\d+/)).toString();
				this.content.singleplayerStatus.gotoAndStop((statusStr.search("Singleplayer") != -1).toString());
				this.content.multiplayerStatus.gotoAndStop((statusStr.search("Multiplayer") != -1).toString());
			}
			else if(appType == "Program")
				this.toggleGameStats(false);
		}
		
		/*
		toggleGameStats
		Toggle the information about the application that pertains to games - mutliplayer, singleplayer, etc.
		*/
		private function toggleGameStats(enable:Boolean) 
		{
			var opacity:Number = (enable ? 1 : .3);
			this.content.sessionsTLF.alpha = opacity;
			this.content.singleplayerTLF.alpha = opacity;
			this.content.multiplayerTLF.alpha = opacity;
			this.content.sessionsSubTLF.alpha = opacity;
			this.content.singleplayerStatus.alpha = opacity;
			this.content.multiplayerStatus.alpha = opacity;
			if(!enable)
			{
				this.content.sessionsTLF.text = "-";
				this.content.singleplayerStatus.gotoAndStop("false");
				this.content.multiplayerStatus.gotoAndStop("false");
			}
		}
		/*
		adjustHeight
		Adjust the height of the window so it fits the content but does not 
		exceed MAX_HEIGHT.
		*/
		private function adjustHeight():void 
		{
			var windowHeight:Number = WIN_MIN_HEIGHT + this.descTLF.height;
			
			if(windowHeight > WIN_MAX_HEIGHT)
				windowHeight = WIN_MAX_HEIGHT;

			this.bg.height = windowHeight;
			this.scrollPane.height = windowHeight - this.WIN_MIN_HEIGHT + 10;
			
		}
		
		/*
		onMoreInfoClick
		Make external call to SL client to load app website.
		*/
		private function onMoreInfoClick(evt:MouseEvent):void
		{
			if(this.currentApp == null) return;
			
			//trace("Launching application website...");
			if(ExternalInterface.available)
				ExternalInterface.call("LaunchApplicationWebsite", this.currentApp.appID);
		}
		
		private function onTitleClick(evt:MouseEvent):void {
			this.main.appManager.verifyAppLaunch(this.currentApp);
		}
		
		private function onTitleRollOver(evt:MouseEvent):void {
			this.content.titleTLF.setTextFormat(this.rollOverFormat);
		}
		
		private function onTitleRollOut(evt:MouseEvent):void {
			this.content.titleTLF.setTextFormat(this.defaultFormat);
		}
		
		/*
		setPaneStyle
		Configure the Details ScrollPane with a custom skin.
		*/
		private function setPaneStyle():void
		{
			with(this.scrollPane)
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
				setStyle("thumbUpSkin", ScrollThumb_Up_Dark);
				setStyle("thumbOverSkin", ScrollThumb_Up_Dark);
				setStyle("thumbDownSkin", ScrollThumb_Up_Dark);
			
				//down arrow
				setStyle("downArrowUpSkin", ArrowSkin_Invisible); 
				setStyle("upArrowUpSkin", ArrowSkin_Invisible);
			} 
		}
		
	} //class
}//package
