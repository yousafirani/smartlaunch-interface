package com.slskin.ignitenetwork.apps  
{
	import com.slskin.ignitenetwork.components.IListItem;
	
	public class SubCategory extends Category implements IListItem
	{
		public function SubCategory(id: String, name: String, localeName: String, numApps: String) {
			super(id, name, localeName, numApps);
		}
		
		public function get itemID(): String {
			return this.id;
		}
		
		public function get itemLabel(): String {
			return this._localeName;
		}
		
		public function get iconPath(): String {
			return null;
		}
		
		public function get imagePath(): String {
			return null;
		}
		
		public override function toString(): String {
			return super.toString() + " => " + "Sub Category []";
		}
		
	} //class
} //package
