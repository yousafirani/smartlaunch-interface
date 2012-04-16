/*
Language.as
Defines some helper methods to manage the different languages
and translations for the interface.
*/
package com.slskin.ignitenetwork  
{
	import com.slskin.ignitenetwork.Model;
	
	public class Language
	{
		private static var dataModel:Model; //reference to the data model
		private static var log:Function;
		
		public static function set model(model:Model):void {
			Language.dataModel = model;
		}
		
		public static function set logFunction(func:Function):void {
			Language.log = func;
		}
		
		/*
		translate
		Takes a translation key and looks up the translation in the data
		model. The sl client passes all relavent translation data to
		the model.
		
		If no translation is found the defaultStr is used.
		*/
		public static function translate(key:String, defaultStr:String = ""):String 
		{
			var word:String = Language.dataModel.getProperty(key, Language.dataModel.TEXT_PATH);
			if(word == null)
			{
				//Language.log("No translation found for key " + key);
				return defaultStr;
			}
			else
				return word;
		}

	} //class
} //package
