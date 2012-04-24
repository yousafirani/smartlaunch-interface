/*
FavoritesWidget.as
Definition for the list of favorites displayed in the
DashBoardView.
*/
package com.slskin.ignitenetwork.views.desktop 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import com.slskin.ignitenetwork.*;
	import com.slskin.ignitenetwork.apps.Application;
	import com.slskin.ignitenetwork.components.ListItem;
	import com.slskin.ignitenetwork.views.ListView;
	import flash.text.TextFormat;
	import flash.events.MouseEvent;
	import flash.display.Sprite;
	
	public class FavoritesWidget extends MovieClip 
	{
		/* Constants */
		private const LIST_ITEM_WIDTH:Number = 250;
		private const LIST_ITEM_HEIGHT:Number = 25;
		
		/* Member fields */
		private var main:Main; //reference to main doc class
		
		public function FavoritesWidget() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded
		Read the favorites list and create the list of favorites based
		on the ListItem object. The list is displayed in a ScrollPane to add
		the vertical scroll functionality.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//set main
			main = (root as Main);
			
			//translate title
			this.titleTLF.text = Language.translate("Your_Favorites", "Your Favorites");
			
			//configure the scroll pane
			this.setPaneStyle();
			
			//create the favorite list from the favorites collection
			this.createFavList(main.appManager.favorites);
		}
		
		/*
		createFavList
		Creates a ListView based on the applications passed as parameter and
		sets the list view as the favePane source.
		*/
		private function createFavList(apps:Array):void
		{
			var listItems:Array = new Array();
			var item:ListItem;
			for(var i:uint = 0; i < apps.length; i++)
			{
				item = new ListItem(apps[i], LIST_ITEM_WIDTH, LIST_ITEM_HEIGHT);
				item.addEventListener(MouseEvent.CLICK, onFavoriteItemClick);
				listItems.push(item);
			}
			
			this.favePane.source = new ListView(listItems, 0, 2);
		}
		
		/*
		onFavoriteItemClick
		Call the launch application routine in the AppManager and set
		verify launch to true.
		*/
		private function onFavoriteItemClick(evt:MouseEvent):void 
		{
			var app:Application = ((evt.currentTarget as ListItem).targetObj as Application);
			this.main.appManager.verifyAppLaunch(app);
		}
		
		/*
		setPaneStyle
		Configure the ScrollPane with a custom skin.
		*/
		private function setPaneStyle():void
		{
			//set scrollPane scrollbar width
			this.favePane.setStyle("scrollBarWidth", 8);
			
			//hide arrows
			this.favePane.setStyle("scrollArrowHeight", 0);
			
			//setup track
			this.favePane.setStyle("trackUpSkin", ScrollTrack_Invisible);
			this.favePane.setStyle("trackOverSkin", ScrollTrack_Invisible);
			this.favePane.setStyle("trackDownSkin", ScrollTrack_Invisible);
			
			//setup thumb
			this.favePane.setStyle("thumbUpSkin", ScrollThumb_Up_Dark);
			this.favePane.setStyle("thumbOverSkin", ScrollThumb_Up_Dark);
			this.favePane.setStyle("thumbDownSkin", ScrollThumb_Up_Dark);
			
			//down arrow
			this.favePane.setStyle("downArrowUpSkin", ArrowSkin_Invisible); 
			this.favePane.setStyle("upArrowUpSkin", ArrowSkin_Invisible); 
		}
		
	}//class
}//package
