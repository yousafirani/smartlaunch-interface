/*
Ruben Oanta
SL Interface

This is the document class for Interface_as3.fla. Facilitates
different views and maintains instances to various modules used
in the skin.
*/
package com.slskin.ignitenetwork
{
	import flash.system.Capabilities;
	import flash.display.*;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.events.ErrorEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.net.URLRequest;
	import flash.external.ExternalInterface;
	import fl.containers.UILoader;
	import flash.net.URLLoader;
	import flash.events.IOErrorEvent;
	import flash.utils.Dictionary;
	import fl.transitions.TweenEvent;
	import com.slskin.ignitenetwork.events.*;
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.views.accountsetup.*;
	import com.slskin.ignitenetwork.views.desktop.*
	import com.slskin.ignitenetwork.apps.*
	
	[SWF(backgroundColor="0x000000")]
	
	public class Main extends MovieClip
	{
		/* Constants */
		public const VERSION:String = "1.1.205";
		public const MIN_FLASH_VER:String = "10,1";
		public const CONFIG_FILE:String = "config.xml";
		
		/* Member Fields */
		private var _model:Model; //manages data passed between the SLClient and the interface
		private var _viewManager:ViewManager; //manages SLViews added to stage.
		private var _wallpaperManager:WallpaperManager; //manages skin wallpapers/backgrounds
		private var _appManager:AppManager; //manages the installed apps, app categories, etc.
		private var _lang:Language; //Helps manage the translation data.
		private var _config:XML; //stores the configuration file config.xml
		public var debugger:DebugConsole; //debug console component
		
		/* 
		Constructor 
		Instantiates the member fields. Also checks to see if
		the current flash player ActiveX version is the correct
		version.
		*/
		public function Main():void
		{ 
			this.debugger = new DebugConsole();
			this._model = new Model(this);
			this._viewManager = new ViewManager(this);
			this._appManager = new AppManager(this);
			this._wallpaperManager = new WallpaperManager();
			Language.model = this._model;
			Language.logFunction = this.log;
			
			//set the loading view parent display object
			LoadingView.parentObj = this;
			ErrorView.parentObj = this;
						
			//write to debug console versions
			this.debugger.write("Interface Version: " + this.VERSION);
			this.debugger.write("Flash Version: " + Capabilities.playerType + ", " + Capabilities.version);
			
			//check flash version
			if(!isValidFlashVersion())
			{
				var versionMisMatch:String = "Flash version " + Capabilities.version 
					+ " found. This interface requires version " + this.MIN_FLASH_VER  + " or above.";
				this.debugger.write(versionMisMatch);
				this.showMessageBox(versionMisMatch);
			}
				
			//listen for added to stage event.
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//listen for SL Event LOGIN_COMPLETED and LOGGGING_OUT
			this.model.addEventListener(SLEvent.LOGIN_COMPLETED, this.onLoginComplete);
			this.model.addEventListener(SLEvent.LOGGING_OUT, this.onLogoutStart);
			
			//global error handling
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		}
		
		/* Getters */
		public function get config():XML {
			return this._config;
		}
		
		public function get model():Model {
			return this._model;
		}
		
		public function get viewManager():ViewManager {
			return this._viewManager;
		}
		
		public function get appManager():AppManager {
			return this._appManager;
		}
		
		public function get wallpaperManager():WallpaperManager {
			return this._wallpaperManager;
		}
		
		/* 
		isValidFlashVersion
		Makes sure that the clients flash version
		meets the min requirement. If it does, return true
		else false.
		@return {Boolean} indicating if the flash version meets the min requirement.
		*/
		private function isValidFlashVersion():Boolean
		{
			var version:Array = Capabilities.version.split(",");
			var reqVersion:Array = this.MIN_FLASH_VER.split(",");
			
			//parse out platform
			version[0] = version[0].split(" ")[1];
			
			for(var i:int = 0; i < reqVersion.length; i++)
				if(Number(reqVersion[i]) > Number(version[i]))
					return false;
					
			return true;
		}
		
		/*
		uncaughtErrorHandler
		Global error event handler. If the event is in fact and error, show
		the ErrorView.
		*/
		private function uncaughtErrorHandler(event:UncaughtErrorEvent):void
        {
            if (event.error is Error)
            {
                var error:Error = event.error as Error;
				this.log("Uncaught Exception: " + error.toString());
				if(this.debugger.debug)
                	throw error;
				else
					ErrorView.getInstance().showError(this.config.Strings.ErrorString);
            }
            else if (event.error is ErrorEvent)
            {
                var errorEvent:ErrorEvent = event.error as ErrorEvent;
				this.log("Uncaught Exception: " + errorEvent.toString());
				if(this.debugger.debug)
                	ErrorView.getInstance().showError(errorEvent.text);
				else
					ErrorView.getInstance().showError(this.config.Strings.ErrorString);
            }
            //else a non-Error, non-ErrorEvent type was thrown and uncaught 
        }
		
		/*
		onAdded
		Sets up the stage and loads the configuration file
		after this element has been added to stage.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAdded);
			
			//register callback functions for .NET. This has to happen relatively early
			//so the .NET client can have access to these functions.
			if(ExternalInterface.available)
			{
				ExternalInterface.addCallback("dispatchEvent", _model.dispatcher);
				ExternalInterface.addCallback("addProperty", _model.addProperty);
				ExternalInterface.addCallback("getProperty", _model.getProperty);
				ExternalInterface.call("Ready");
				this.debugger.write("ExternalInterface Ready!");
			}
			else
				this.debugger.write("ExternalInterface is not Available!");
			
			//load configuration file - config.xml and 
			//listens for the events complete and io error.
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onConfigLoad);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onConfigLoadError);
			loader.load(new URLRequest(this.CONFIG_FILE));
			
			//after the config.xml file has loaded, configure the UI elements.
			this.addEventListener(SLEvent.CONFIG_LOADED, configureUI);
			
			//configure the stage
			with (stage)
			{
				frameRate = 31;
				showDefaultContextMenu = false;
				scaleMode = StageScaleMode.NO_SCALE;
				align = StageAlign.TOP_LEFT;
			}
		}
		
		/*
		onConfigLoad
		Event listener for EVENT_COMPLETE on the url loader
		that is loading config.xml.
		*/
		private function onConfigLoad(evt:Event):void
		{
			try
			{
				this._config = XML(evt.target.data);
				this.debugger.debug = (config.@debug == "true");
				
				this.dispatchEvent(new Event(SLEvent.CONFIG_LOADED));
			}
			catch (e:TypeError)
			{
				var errorStr:String = "XML Malformed in config.xml. Check log for more details.";
				this.log(e);
				this.showMessageBox(errorStr);
			}
		}
		
		/**
		onConfigLoadError
		Listens for an IO Error event when trying to load the config.xml
		*/
		private function onConfigLoadError(evt:IOErrorEvent):void
		{
			this.log(evt.text);
			this.showMessageBox("Error loading config.xml. Check log for details.");
		}
		
		/**
		configureUI
		Configures the starting UI elements. Called when the config.xml
		file is done loading.
		*/
		private function configureUI(evt:Event):void
		{
			this.removeEventListener(SLEvent.CONFIG_LOADED, configureUI);
			this.viewManager.removeEventListener(SLView.HIDE_COMPLETE, this.configureUI);
			
			//add background manager to stage
			this.addChildAt(this.wallpaperManager, 0);
			
			//add views to the view manager
			this.viewManager.addView(new LoginView());
			this.viewManager.addView(new DesktopView());
			
			//add the debug console to the stage if debug is true
			if(this.debugger.debug) 
				this.addChild(this.debugger);
			
			//initialize the wallpaper, then display the next view.
			this.wallpaperManager.init();
			this.wallpaperManager.addEventListener(TweenEvent.MOTION_FINISH, viewManager.displayNextView);
		}
		
		/* 
		onLoginComplete
		Triggered when the user has successfully logged in and the initial
		login process is complete. We need to check if the user needs to fill
		out some information (Password, User info, etc.)
		*/
		private function onLoginComplete(evt:SLEvent):void
		{
			var requiredInfo:uint = uint(model.getProperty("RequiredInformationAtLogin", model.DATA_PATH));
			var isInfoRequired:Boolean = requiredInfo != 0;
			
			//add AccountSetupViews as next view if info is required.
			if(isInfoRequired) 
			{
				//listen for account setup complete event
				this.model.addEventListener(SLEvent.REQUIRED_INFO_ENTERED, onAccountSetupComplete);
				
				this.viewManager.addViewAsNext(new AccountSetupView(requiredInfo));
			}
			
			viewManager.displayNextView();
		}
		
		/*
		onAccountSetupComplete
		Event handler for account setup complete event
		*/
		private function onAccountSetupComplete(evt:Event):void
		{
			this.removeEventListener(SLEvent.REQUIRED_INFO_ENTERED, onAccountSetupComplete);
			this.viewManager.displayNextView();
		}
		
		/*
		onLogoutStart
		Event handler for SLEvent.LOGGING_OUT. Creates an event handler for model VALUE_ADDED to
		check when the loggout is complete.
		*/
		private function onLogoutStart(evt:SLEvent):void {
			this.model.addEventListener(SLEvent.VALUE_ADDED, this.onLogoutValueAdded);
		}
		
		/*
		onLogoutValueAdded
		Listens for a loading status of done then "restarts" the interface.
		*/
		private function onLogoutValueAdded(evt:SLEvent):void
		{
			var split:Array = String(evt.argument).split(this.model.DIM);
			var key:String = split[0];
			var val:String = split[1];
			switch (key)
			{
				case this.model.DATA_PATH + "LoadingStatus":
					if(val == "Done")
					{
						this.model.removeEventListener(SLEvent.VALUE_ADDED, this.onLogoutValueAdded);
						this.onLogoutComplete();
					}
					break;
			}
		}
		
		/*
		onLogoutComplete
		Display nextView
		*/
		private function onLogoutComplete():void
		{
			this.viewManager.addEventListener(SLView.HIDE_COMPLETE, this.configureUI);
			this.viewManager.clearAllViews();
			this.wallpaperManager.fadeOutImage();
		}
		
		/*
		getStageHeight
		Helper function to get the stage height 
		from stageWidth or stageFullScreen.
		*/
		public function getStageHeight():int
		{
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
				return stage.fullScreenHeight;
			else
				return stage.stageHeight;
		}
		
		/*
		 getStageWidth
		 Helper functions to get the stage width from 
		 stageWidth or stageFullScreen.
		*/
		public function getStageWidth():int
		{
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
				return stage.fullScreenWidth;
			else
				return stage.stageWidth;
		}
		
		/* 
		log
		Simple helper function to write to SL log. The
		log can be viewed in the SL administrator.
		*/
		public function log(str:String):void
		{
			trace("Log: " + str);
			this.debugger.write("Log: " + str);
			if(ExternalInterface.available)
				ExternalInterface.call("LogAdd", str);
		}
		
		/* 
		showMessageBox
		Display a MessageBox in the SL client. The message box
		is a modal dialog box displayed from .NET.
		*/
		public function showMessageBox(str:String):void
		{
			if(ExternalInterface.available)
				ExternalInterface.call("MessageBox", str);
		}
		
	} //class
} //package