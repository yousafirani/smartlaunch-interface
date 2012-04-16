/*
SubCategory.as
*/
package com.slskin.ignitenetwork.apps  
{
	import com.slskin.ignitenetwork.components.IListItemObject;
	import fl.containers.UILoader;
	
	public class SubCategory extends Category implements IListItemObject
	{
		public function SubCategory(id:String, name:String, localeName:String, numApps:String) {
			super(id, name, localeName, numApps);
		}
		
		/* Getters */
		public function get itemLabel():String {
			return this._localeName;
		}
		
		public function get iconPath():String {
			return null;
		}
		
		/*
		toString
		*/
		public override function toString():String {
			return super.toString() + " => " + "Sub Category []";
		}
		
	} //class
} //package
