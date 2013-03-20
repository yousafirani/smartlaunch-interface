/**
 * Definition for the debug console. This definition
 * represents the DebugConsole movieclip found in the library.
 */
package com.slskin.ignitenetwork.views
{
	import flash.external.ExternalInterface;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.display.InteractiveObject;
	import flash.utils.setTimeout;
	import flash.events.MouseEvent;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.Main;
	
	public class DebugConsole extends MovieClip
	{
		private var _debug: Boolean;
		private var main: Main;
		
		public function DebugConsole(debug: Boolean = true)
		{
			this.debug = debug;
			this.tabChildren = false;
			this.write("Debug Mode Enabled. You can toggle this console with the ` key.");
			this.addEventListener(Event.ADDED_TO_STAGE, this.onAdded);
		}
		
		/* Setters and Getters */
		public function set debug(d: Boolean): void { this._debug = d; }
		public function get debug(): Boolean { return this._debug; }
		
		/**
		 * Adds the a series of commands to the data shared between
		 * SL and the client interface.
		 */
		private function onInjectClick(evt: MouseEvent): void
		{
			this.write("Injecting the following Data:  ");
			main.model.addProperty(main.model.DATA_PATH + "RequiredInformationAtLogin", "0");
			main.model.addProperty(main.model.DATA_PATH + "Firstname", "Ruben");
			main.model.addProperty(main.model.DATA_PATH + "Email", "ruben@ignitenetwork.com");
			main.model.addProperty(main.model.DATA_PATH + "Username", "rubeydoo");
			main.model.addProperty(main.model.DATA_PATH + "Birthday_Year", "1987");
			main.model.addProperty(main.model.DATA_PATH + "Balance", "-30.50");
			main.model.addProperty(main.model.DATA_PATH + "Time", "-375");
			main.model.addProperty(main.model.TEXT_PATH + "Welcome_Message", "Welcome back Ruben<br><font color='#0080FF' size='+1'>Time used: </font> 6 hour and 30 minutes<br><font color='#0080FF' size='+1'>Last Visit: </font> 2/8/2012 2: 24: 27 pm");
			main.model.addProperty(main.model.TEXT_PATH + "Headline1", "ignite network gaming lounge");
			main.model.addProperty(main.model.TEXT_PATH + "Headline2", "2/09/2012 - PC 48");
			main.model.addProperty(main.model.ROOT_PATH + "OptionsList", "Your Profile|-2");
			main.model.addProperty(main.model.TEXT_PATH + "Logout_UpperCase", "LOGOUT");
			main.model.dispatcher(SLEvent.UPDATE_CATEGORY_LIST, "Games;1;0;Games|Most Played FPS;23;15;Most Played FPS|Strategy;32;14;Strategy|mmorpgs;22;3;mmorpgs|FPS;35;8;FPS|Classics;16;17;Classics|^Programs;17;0;Programs|Chat;33;6;Chat|Office;20;1;Office|Pictures;36;3;Pictures|Media;34;1;Media|Other;21;4;Other|^Internet;3;1;Internet|^Options;-2;4;Options|");
			main.model.dispatcher(SLEvent.UPDATE_FAVORITES, "Counter-Strike|1^World Of Warcraft|2^League of Legends|3^Warcraft III:  Frozen Throne|6^Modern Warfare 3|7");
			main.model.addProperty(main.model.DATA_PATH + "Sex", "2");
			main.model.addProperty("InjectApps", "1");
			main.model.addProperty("showAppIDs", "0");
			main.model.addProperty(main.model.APP_DATA_PATH + "Application_Status", '<FONT COLOR="#FFFFFF"><B>Players: </B></FONT><BR><FONT COLOR="#B5B5A4">7 users are currently playing this game.</FONT><BR><BR><FONT COLOR="#FFFFFF"><B>Game type: </B></FONT><BR><FONT COLOR="#B5B5A4">Singleplayer, Multiplayer</FONT>');
			main.model.addProperty(main.model.APP_DATA_PATH + "Application_Headline", "Unreal Tournament 2004");
			main.model.addProperty(main.model.APP_DATA_PATH + "Application_Type", "Game");
			main.model.addProperty(main.model.DATA_PATH + "Application_1_ActiveSessions", "4");
			main.model.addProperty(main.model.APP_DATA_PATH + "Application_Description", "The original StarCraft made its debut in 1998, and it quickly became one of the most popular real-time strategy games of all time.We've waited a long time for an updated sequel, and rumors of it were periodically dangled in front of us like a space carrot over the years.");
			main.model.addProperty(main.model.DATA_PATH + "RequiredUserInformation", "11111111101111111");
			main.model.addProperty(main.model.DATA_PATH + "PersonalInfoArray", "Firstname|Lastname|Birthday|Address|City|Zip|State|Country|Email|Telephone|Mobilephone|Sex|PersonalNumber");
			main.model.dispatcher(SLEvent.UPDATE_NEWS_EVENTS, "1/28/2012|Join us on facebook.|You can now follow us on facebook. Connect with others who come to ignite and keep up with new games, events, and promotions at facebook.com/ignitenetwork.|http: // facebook.com/ignitenetwork");
			main.model.dispatcher(SLEvent.LOGIN_COMPLETED, "Complete");
		} 
		
		/**
		 * Listens for the added to stage event. Sets up the objects
		 * on the stage properly.
		 */
		private function onAdded(evt: Event): void
		{
			// remove listener
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAdded);
			
			if (!this.debug) 
			{
				this.toggleConsole();
				return;
			}
			
			// set reference to main
			main = (root as Main);
			
			// sim stage resize
			this.onStageResize(null);
			
			// listen for stage resize
			this.stage.addEventListener(Event.RESIZE, this.onStageResize);
			
			// listen for key press
			stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyPress);
			
			// setup inject button
			this.injectButton.label = "Inject";
			this.injectButton.button.addEventListener(MouseEvent.CLICK, onInjectClick);
		}
		
		/**
		 * Setup the debug console properties and location on
		 * the stage.
		 */
		public function showView(): void
		{
			this.x = 0;
			this.y = stage.stageHeight - this.debugOut.height - 50;
		}
		
		/**
		 * Removes it's self from stage.
		 */
		public function hideView(): void {
			(parent as MovieClip).removeChild(this);
		}
		
		
		/**
		 * Listen for keypress and if key is backquote, show/hide debug console
		 */
		private function onKeyPress(keyEvent: KeyboardEvent): void
		{
			if (keyEvent.keyCode == Keyboard.BACKQUOTE)
				this.toggleConsole();
		}
		
		/**
		 * Toggles the debug console on/off.
		 */
		private function toggleConsole(): void
		{
			if (this.visible)
				this.visible = false;
			else
				this.visible = true;
		}
		
		/**
		 * Listens for stage resize event
		 */
		private function onStageResize(evt: Event): void {
			this.showView();
		}
		
		/**
		 * Writes a line to the debug console.
		 */
		public function write(line: String): void
		{
			// don't waste any cpu writing to console if
			// debug mode is off.
			if (this.debug)
			{
				this.debugOut.appendText("==> " + line + "\n");
				// update scroll bar position.
				setTimeout(function(): void{debugOut.verticalScrollPosition = debugOut.maxVerticalScrollPosition;}, 100);
			}
		}
	} // class
} // package