/*
MainCategory.as
Represents a MainCategory has a collection
that stores the sub categories that belong to it.
*/
package com.slskin.ignitenetwork.apps 
{
	public class MainCategory extends Category
	{
		/* Member Fields */
		private var _subCategories:Array; //collection of sub categories
		
		public function MainCategory(id:String, name:String, localeName:String, numApps:String) 
		{
			super(id, name, localeName, numApps);
			this._subCategories = new Array();
		}
		
		/* Getters */
		public function get numOfSubCategories():int {
			return this._subCategories.length;
		}
		
		public function get subCategories():Array {
			return this._subCategories;
		}
		
		/*
		addSubCategory
		Pushes a sub category onto the subCategory collection.
		@param subCat A SubCategory object.
		*/
		public function addSubCategory(subCat:SubCategory):void {
			this._subCategories.push(subCat);
		}
		
		/*
		toString
		*/
		public override function toString():String {
			return super.toString() + " => " + 
						"Main Category [" + this.numOfSubCategories  + " sub categorie(s).]";
		}
		
		

	} //class
} //package
