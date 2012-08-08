/**
 * Model.as
 * Facilitates the communication between the SL client which
 * has access to the database. Stores the data shared between .NET and
 * the client in a Dictionary. Triggers events based on
 * different data passed to/from the SL Client. The different type
 * of events are stored in SLEvent.
 */
package com.slskin.ignitenetwork
{
	import flash.external.ExternalInterface;
	import com.slskin.ignitenetwork.events.*;
	import flash.utils.Dictionary;
	import flash.events.EventDispatcher;

	public class Model extends EventDispatcher
	{
		/* Delimeters SL client uses to parse data. */
		public const DIM: String = "^";
		public const DlMSep: String = "|";
		public const DlMSep2: String = ";";

		/* Paths to maintain support for how SL client accesses data in flash */
		public const DATA_PATH: String = "_root.Data.";
		public const TEXT_PATH: String = "_root.Text.";
		public const ROOT_PATH: String = "_root.";
		public const APP_DATA_PATH: String = "_root.Data:";

		private var main: Main;// stores a reference to the main doc class
		private var propertyMap: Dictionary;// stores data shared between the flash client and the SL client.

		/**
		 * Takes a reference to the main document class and
		 * instatiates the member fields. Also, adds callback functions
		 * that are exposed to .NET (ExternalInterface).
		 */
		public function Model(main: Main)
		{
			this.main = main;
			this.propertyMap = new Dictionary();
		}

		/**
		 * Recieves an eventType and an argument from .NET and
		 * triggers the appropriate SLEvent in flash.
		 */
		public function dispatcher(eventType: String, argument: String): void
		{
			this.dispatchEvent(new SLEvent(eventType, argument));

			// store event and argument. This is incase the SL client passes an event
			// that we need to listen for but the object that is listening isn't instantiated
			// yet. An example is the UpdateNewsAndEvents is initially called before the NewsWidget is ready.
			this.propertyMap[eventType] = argument;

			if (eventType != "MouseWheel" && eventType != "UpdateApplicationList")
			{
				main.debugger.write("SL Event:  " + eventType + ", " + argument);
			}
		}


		/**
		 * The interface for the SL client to send variables
		 * over to flash. This method will add name/value pairs in the propertMap (Dictionary)
		 * for later use.
		 */
		public function addProperty(key: *, value: String): void
		{
			// add key - value to dictionary
			this.propertyMap[key] = value;

			// this.debugger.write("Replace key " + key + " for " + shortKey);

			// dispatch event
			this.dispatcher(SLEvent.VALUE_ADDED, key + this.DIM + value);
		}

		/**
		 * The interface used to access the variables that are in
		 * the propertyMap shared with the SL client. This function is also
		 * accessed by the SL client.
		 *
		 * The key path allows support for the old way that SL used to interface
		 * with flash. SL used to access items in flash based on their paths. For example,
		 * changing a headline variable would require the full path to the headline variable or
		 * item (ex. _root.Text.Headline1). We don't need that anymore, but in order to have
		 * unique keys in our map we need to prepend the path.
		 *
		 * A word about return types:  With this new system we could pass type
		 * information across the ExternalInterface. However the SL client converts
		 * all data recieved from flash toString. Therefore we can just
		 * return a string here.
		 */
		public function getProperty(key: String, keyPath: String = ""): String
		{
			var val: * = this.propertyMap[keyPath + key];
			return (val == undefined ? null :  val);
		}

	}// class
}// package