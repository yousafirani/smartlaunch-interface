/*
AppManager.as
Manages the application data passed into
the SL interface. This includes data related to the
application categories / sub categories. Also defines the routines
for launching an application.

Refer to the DockView which handles and displays the 
main categories.

Refer to the CategoryView which displays the sub categories
and applications.
*/
package com.slskin.ignitenetwork.apps
{
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	import flash.events.Event;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.util.ArrayIterator;
	import com.slskin.ignitenetwork.Main;
	import com.slskin.ignitenetwork.Language;
	import com.slskin.ignitenetwork.views.LoadingView;
	import com.slskin.ignitenetwork.views.ErrorView;
	import com.slskin.ignitenetwork.util.Strings;
	import com.slskin.ignitenetwork.Model;
	import flash.events.TimerEvent;
	
	public class AppManager extends EventDispatcher
	{
		/* Constants */
		private const CATEGORY_NAME_INDEX:uint = 0;
		private const CATEGORY_ID_INDEX:uint = 1;
		private const CATEGORY_NUMAPPS_INDEX:uint = 2;
		private const CATEGORY_LOCALENAME_INDEX:uint = 3;
		private const LAUNCH_VERIFY_SECONDS:Number = 3; //The amount of time in seconds the user has to verify an app launch
		
		/* Member fields */
		private var main:Main; //reference to document class.
		private var mainCategories:Array; //a collection of main categories
		private var faves:Array; //a collection of Application objects
		private var launchTimer:Timer; //timer used to verify and app launch
		private var appToLaunch:Application; //stores the current app that will launch after launch verification
		private var timeToLaunch:uint; //keeps track of current seconds to launch
		
		public function AppManager(main:Main) 
		{
			//set doc class reference
			this.main = main;
			
			//
			
			//instatiate arrays
			this.mainCategories = new Array();
			this.faves = new Array();
			
			//listen for category updates from sl client
			this.main.model.addEventListener(SLEvent.UPDATE_CATEGORY_LIST, parseCategories);
			this.main.model.addEventListener(SLEvent.UPDATE_FAVORITES, parseFavorites);
		}
		
		/* Getters */
		public function get categories():Array {
			return this.mainCategories;
		}
		
		public function get favorites():Array {
			return this.faves;
		}
		
		/*
		parseCategories
		Parse the category list string received from the SL client and create
		the appropriate objects based on the data. The main categories are stored
		in a local array and the sub categories are stored in each main category
		object.
		
		The category list string can be parsed into a 3d array.
		1st dimension: The main categories.
		2nd dimension: The sub categories for each main category.
		3rd dimension: The properties of each sub category.
		[i][j][0] - The english name for the category.
		[i][j][1] - The category ID
		[i][j][2] - The number of apps in this category
		[i][j][3] - The locale name for the category.
		*/
		private function parseCategories(evt:SLEvent):void
		{
			//categoryList string is in the argument field of the event
			var categoryStr:String = evt.argument;
			
			//split out the main categories
			this.mainCategories = categoryStr.split(main.model.DIM);
			var mainCategory:MainCategory;
			var subCategory:SubCategory;
			
			for(var i:uint = 0; i < this.mainCategories.length; i++)
			{
				//split string further and store it temporarily at position i
				this.mainCategories[i] = this.mainCategories[i].split(main.model.DlMSep);
				this.mainCategories[i] = this.mainCategories[i].splice(0, this.mainCategories[i].length-1);
				
				//parse each category properties
				for (var j:uint = 0; j < this.mainCategories[i].length; j++)
					this.mainCategories[i][j] = this.mainCategories[i][j].split(main.model.DlMSep2);
				
				//create main category object.
				mainCategory = new MainCategory(this.mainCategories[i][0][this.CATEGORY_ID_INDEX], 
											this.mainCategories[i][0][this.CATEGORY_NAME_INDEX],
											this.mainCategories[i][0][this.CATEGORY_LOCALENAME_INDEX],
											this.mainCategories[i][0][this.CATEGORY_NUMAPPS_INDEX]);
				
				//push sub categories onto main category. Start at position 1
				//because the main category was at [i][0]
				for(j = 1; j < this.mainCategories[i].length; j++)
				{
					subCategory = new SubCategory(this.mainCategories[i][j][this.CATEGORY_ID_INDEX],
												  this.mainCategories[i][j][this.CATEGORY_NAME_INDEX],
												  this.mainCategories[i][j][this.CATEGORY_LOCALENAME_INDEX],
												  this.mainCategories[i][j][this.CATEGORY_NUMAPPS_INDEX]);
					
					//add sub category to main category
					mainCategory.addSubCategory(subCategory);
				}
				
				//replace position i with mainCategory object
				this.mainCategories[i] = mainCategory;
			}
						
			//inject home into main categories.
			mainCategory = new MainCategory("-1", "Home", Language.translate("Home", "Home"), "2");
			this.mainCategories.push(mainCategory);
			//this.mainCategories.splice(0, 0, mainCategory);
			
			//Dispatch event that indicates that the categories
			//have been updated and pass the new categories in as
			//the event parameter.
			var slEvent:SLEvent = new SLEvent(evt.type, this.mainCategories);
			this.dispatchEvent(slEvent);
		}
		
		
		/*
		parseAppString
		Parses an application string received from the SL client.
		Each application has an app name and an app id. This method 
		returns a collection of Application objects.
		*/
		public function parseAppString(appStr:String):Array
		{
			if(appStr.length == 0) return new Array();
			
			var appArr:Array = appStr.split(main.model.DIM);
			for(var i:uint = 0; i < appArr.length; i++)
			{
				appArr[i] = appArr[i].split(main.model.DlMSep);
				appArr[i] = new Application(appArr[i][1], appArr[i][0]);
			}
			
			return appArr;
		}
		
		/*
		parseFavorites
		Parse the favorites string received from SL and create a collection
		of Application objects which are stored in the favorties array.
		*/
		private function parseFavorites(evt:SLEvent):void
		{
			//parse apps and store them in member variable faves
			this.faves = this.parseAppString(evt.argument);
			
			//dispacth event
			var slEvent:SLEvent = new SLEvent(evt.type, this.faves);
			this.dispatchEvent(slEvent);
		}
		
		/*
		launchApp
		Calls the launch application routine in the SL client.
		app:Application - The application to launch.
		silent:Boolean - If boolean is set the loading view is not shown.
		*/
		public function launchApp(app:Application, silent:Boolean = false):void
		{
			trace("Launching " + app.appName);
			
			if(!silent) 
			{
				LoadingView.getInstance().showLoader();
				LoadingView.getInstance().enableClose();
				LoadingView.getInstance().loadingText = "Launching " + app.appName + "...";
			}
			
			//listen for app loading progress
			main.model.addEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
			
			//disable the close button once we have progress from the SL client.
			main.model.addEventListener(SLEvent.VALUE_ADDED, this.disableClose);
			
			if(ExternalInterface.available)
				ExternalInterface.call("LaunchApplication", app.appID);
		}
		
		/*
		verifyAppLaunch
		Starts the app launching process but gives the user a chance to cancel
		the launch.
		*/
		public function verifyAppLaunch(app:Application):void
		{
			//store a reference to the app to launch
			this.appToLaunch = app;
			
			//setup the verify timer.
			this.launchTimer = new Timer(1000);
			this.timeToLaunch = this.LAUNCH_VERIFY_SECONDS;
			this.launchTimer.addEventListener(TimerEvent.TIMER, onLaunchVerifyTick);
			this.launchTimer.start();
			
			//loader used to display timer status.
			LoadingView.getInstance().showLoader();
			LoadingView.getInstance().enableClose();
			
			//listen for user closing the launcher.
			LoadingView.getInstance().addEventListener(Event.CLOSE, onLoaderClose);
			
			//set count down status text.
			var statusStr:String = Strings.substitute(main.config.Strings.VerifyAppLaunch, app.appName, this.timeToLaunch);
			LoadingView.getInstance().loadingText = statusStr;
		}
		
		/*
		onLaunchVerifyTick
		Update the LoadingView to display the tick status.
		*/
		private function onLaunchVerifyTick(evt:TimerEvent):void 
		{
			this.timeToLaunch--;
			var statusStr:String = Strings.substitute(main.config.Strings.VerifyAppLaunch, this.appToLaunch.appName, this.timeToLaunch);
			LoadingView.getInstance().loadingText = statusStr;
			
			if(this.timeToLaunch == 0)
			{
				this.launchTimer.stop();
				this.launchApp(this.appToLaunch);
			}
		}
		
		/*
		onLoaderClose
		Stop the launch timer.
		*/
		private function onLoaderClose(evt:Event):void {
			this.launchTimer.stop();
			LoadingView.getInstance().removeEventListener(Event.CLOSE, onLoaderClose);
		}
		
		/*
		launchCategory
		Takes a main category that has one application in it and launches it.
		*/
		public function launchCategory(category:MainCategory):void
		{
			if(category.numOfApps > 1)
				throw new Error("Cannot launch a category with more than 1 application in it.");
				
			if(ExternalInterface.available)
					ExternalInterface.call("LaunchCategory", category.id);
		}
		
		/*
		onValueAdded
		Listens for value added events from the model and responds to the
		key value pairs that pertain to the application launch.
		*/
		private function onValueAdded(evt:SLEvent):void
		{
			var split:Array = String(evt.argument).split(main.model.DIM);
			var key:String = split[0];
			var val:String = split[1];
			switch (key)
			{
				case main.model.DATA_PATH + "LoadingStatus":
					if(val == "Done")
					{
						LoadingView.getInstance().hideLoader();
						main.model.removeEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
						main.wallpaperManager.stopTimer();
					}
					else if(val == "Failed")
					{
						LoadingView.getInstance().hideLoader();
						//ErrorView.getInstance().showError(main.config.Strings.ErrorString);
						main.model.removeEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
					}
					break;
				case main.model.TEXT_PATH + "LoadingText":
				case main.model.DATA_PATH + "LoadingText":
					LoadingView.getInstance().loadingText = val;
					break;
			}
		}
		
		/*
		disableClose
		Disable the close button once we are sure that the SL client has
		received our launch request. This is to offset an issue where the client
		ignores a launch request of the same application within 4 seconds.
		*/
		private function disableClose(evt:SLEvent):void 
		{
			var split:Array = String(evt.argument).split(main.model.DIM);
			var key:String = split[0];
			if(key == main.model.TEXT_PATH + "LoadingText" ||
				key == main.model.DATA_PATH + "LoadingText")
				{
					LoadingView.getInstance().disableClose();
					main.model.addEventListener(SLEvent.VALUE_ADDED, this.disableClose);
				}
		}
		

	} //class
} //package
