/*
Ruben Oanta
SL Interface

Defines events that are called from .NET for the SL skin.
*/
package com.slskin.ignitenetwork.events
{
	
	import flash.events.Event;
	
	public class SLEvent extends Event
	{
		/* Define event types */
		public static const UPDATE_CATEGORY_LIST:String = "UpdateApplicationCategoryList";
		public static const UPDATE_APP_LIST:String = "UpdateApplicationList";
		public static const APP_DETAILS_RECEIVED:String = "ApplicationDetailsReceived";
		public static const LOGIN_APPROVED:String = "UserLoginApproved";
		public static const LOGIN_COMPLETED:String = "UserLoginCompleted";
		public static const LOGIN_DENIED:String = "UserLoginDenied";
		public static const LOGGING_OUT:String = "UserLoggingOut";
		public static const LOGGED_OUT:String = "UserLoggedOut";
		public static const UPDATE_FAVORITES:String = "UpdateUserFavoritesList";
		public static const PAGE_CHANGE:String = "ChangePage";
		public static const MOUSE_WHEEL:String = "MouseWheel";
		public static const REQUIRED_INFO_ENTERED:String = "RequiredInformationEntered";
		public static const UPDATE_NEWS_EVENTS:String = "UpdateNewsAndEvents";
		public static const PLAY_SOUND:String = "PlaySound";
		public static const VALUE_ADDED:String = "ValueAdded";
		public static const CONFIG_LOADED:String = "ConfigLoadComplete";
		
		/* Some custom UI Events */
		//public static const HIDE_UI_COMPLETE:String = "HideComplete";
		public static const DOCK_ICON_CLICK:String = "DockIconClick";
		public static const LIST_ITEM_CLICK:String = "ListItemClick";
		
		/* Member variables */
		private var _argument:*;
		
		/* getters */
		public function get argument():* { return this._argument; }
		
		/*
		Constructor
		@Description - calls the Event constructor and sets the argument
		*/
		public function SLEvent(type:String, argument:*, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
            super(type, bubbles, cancelable);
			this._argument = argument;
        }
		
		public override function toString():String 
		{
            return formatToString("SLEvent", "type", "argument", "bubbles", "cancelable");
        }

	} //class
}//package