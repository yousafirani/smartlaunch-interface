/**
 * Application.as
 * Stores the data received from the SL client
 * that represents an object. This includes the
 * app name and app id.
 * 
 * The rest of the application data is only loaded on user request
 * with the the ExternalInterface.call("GetApplicationDetails", AppID)
 * function call.
 *
 * This class implements the IListItemObject because it can
 * be displayed in a list.
 */
package com.slskin.ignitenetwork.apps  
{
	import com.slskin.ignitenetwork.components.IListItem;
	
	public class Application implements IListItem
	{
		/* Constants */
		private const ASSETS_BASE_DIR: String = "./assets/apps/";
		private const BOX_SHOT_DIR: String = "./images/";
		private const ICON_FILENAME: String = "icon.png";
		
		/* Member Fields */
		private var _appID: String;
		private var _appName: String;
		
		public function Application(appID: String, appName: String) 
		{
			this._appID = appID;
			this._appName = appName;
		}
		
		/* Getters */
		public function get appID(): String {
			return this._appID;
		}
		
		public function get appName(): String {
			return this._appName;
		}
		
		public function get itemID(): String {
			return this.appID;
		}
		
		public function get itemLabel(): String {
			return this._appName;
		}
		
		public function get iconPath(): String {
			return this.assetPath + this.ICON_FILENAME;
		}
		
		public function get imagePath(): String {
			return this.BOX_SHOT_DIR + this.appID + ".jpg";
		}
		
		public function get assetPath(): String
		{
			return this.ASSETS_BASE_DIR + this._appID + "/";
			// var illegalCharacters: RegExp = /[\?\/\: \*\<\>\|\\ ]/gi;
			// return this.ASSETS_BASE_DIR + this._appName.toLocaleLowerCase().replace(illegalCharacters, "_") + "/";
		}

	} // class
} // package
