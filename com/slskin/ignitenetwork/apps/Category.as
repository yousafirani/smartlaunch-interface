/*
MainCategory.as
Base class for main category and sub category.
*/
package com.slskin.ignitenetwork.apps 
{
	import com.slskin.ignitenetwork.util.Strings;
	
	public class Category 
	{
		/* Member Fields */
		protected var _id:String; //category id
		protected var _name:String; //category english name
		protected var _localeName:String; //category locale name
		protected var _numApps:int; //number of apps in this main category
		protected var _apps:Array; //collection of applications in this category.
		
		public function Category(id:String, name:String, localeName:String, numApps:String) 
		{
			this._id = id;
			this._name = name;
			//verify local name because it's passed in from SL
			this._localeName = (localeName == null ? "undefined" : localeName);
			this._numApps = int(numApps);
			this._apps = new Array();
		}
		
		/* Getters */
		public function get id():String {
			return this._id;
		}
		
		public function get name():String {
			return this._name;
		}
		
		public function get localeName():String {
			return this._localeName;
		}
		
		public function set applications(apps:Array):void {
			this._apps = apps;
		}
		
		public function get applications():Array {
			return this._apps;
		}
		
		public function get numOfApps():int {
			return this._numApps;
		}
		
		/*
		toString
		*/
		public function toString():String {
			return "Category [ " + this._name + " has " + this._numApps + "  application(s).]";
		}
		
	} //class
} //package
