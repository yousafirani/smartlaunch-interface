/*
CategoryView.as
Responsible for displaying MainCategory that have
SubCategories. The respective applications
are displayed in a ScrollPane in a TileView.
*/
package com.slskin.ignitenetwork.views.desktop 
{
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.text.TextFieldAutoSize;
	import flash.events.TextEvent;
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.apps.MainCategory;
	import com.slskin.ignitenetwork.components.IListItemObject;
	import com.slskin.ignitenetwork.components.ListItem;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.apps.Category;
	import com.slskin.ignitenetwork.util.ArrayIterator;
	import com.slskin.ignitenetwork.apps.SubCategory;
	import com.slskin.ignitenetwork.apps.Application;
	import com.slskin.ignitenetwork.components.PanelBackground;
	import com.slskin.ignitenetwork.components.DottedSeperatorShort;
	import com.slskin.ignitenetwork.components.GreyArrow;
	import com.slskin.ignitenetwork.components.DropDownSelector;
	import com.slskin.ignitenetwork.components.SearchField;
	import fl.text.TLFTextField;
	import flash.net.URLRequest;
	
	public class CategoryView extends SLView 
	{
		/* Constants */
		private const LEFT_PADDING:Number = -135; //Window left padding, makes room for dashboard
		private const TOP_PADDING:Number = -53; //Window top padding, makes room for footer
		private const ICON_PATH:String = "./assets/dock/";
		
		/* Member fields */
		public var category:MainCategory; //main category that this view displays
		private var subCategoryIter:ArrayIterator; //keeps track of current sub category while loading all apps
		private var listViews:Dictionary; //a cache that stores the TileView objects for each sub category
		private var selector:DropDownSelector; //a reference to the drop down selector on stage.
		private var searchField:SearchField; //a reference to the search field on stage.
		
		/* Member Fields */
		public function CategoryView(category:MainCategory) 
		{
			this.category = category;
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded
		added to stage event listener.
		*/
		private function onAdded(evt:Event):void
		{
			//remove event listener
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//set the scroll pane style
			this.setPaneStyle();

			//set the reference to the search field and drop down selector
			this.selector = this._selector;
			this.searchField = this._searchField;
			this.searchField.hint = "Search " + this.category.localeName;
			
			//update window padding to make room for
			//other desktop content.
			this.xPadding = this.LEFT_PADDING;
			this.yPadding = this.TOP_PADDING;
			super.setupView();
			
			//set title and load icon
			this.title.autoSize = "left";
			this.title.text = this.category.localeName;
			var iconReq:URLRequest = new URLRequest(this.ICON_PATH + this.category.name.toLowerCase().replace(" ", "_") + ".png");
			this.titleIcon.load(iconReq);
				
			//Load all applications and listen for load complete
			this.loadAllApplications();
			this.addEventListener(Event.COMPLETE, this.onAllAppsLoaded);
			
			/** DEBUG **/
			this.createMockCategory();
			this.onAllAppsLoaded(null);
			this.showView();
			
			//display this view when the initial load is complete
			this.addEventListener(Event.COMPLETE, showView);
		}
		
		/*
		loadAllApplications
		Starts the loading process for each application 
		in each sub category in this main category.
		
		This process cannot be done in a simple loop because of how SL passes
		application data to the interface. The process is done through events and
		callbacks.
		*/
		private function loadAllApplications():void
		{
			//Display the loading view.
			LoadingView.getInstance().loadingText = "Loading " + category.localeName + "...";
			LoadingView.getInstance().showLoader();
			
			//instatitate collections used to store applications in this Category
			this.subCategoryIter = new ArrayIterator(this.category.subCategories);
			this.listViews = new Dictionary();
			
			//disable the selector while loading apps
			this.selector.enabled = false;
			
			//listen for SLEvent.UPDATE_APP_LIST event
			main.model.addEventListener(SLEvent.UPDATE_APP_LIST, this.onAppListUpdate);
			this.updateNextCategory();
		}
		
		/*
		onAppListUpdate
		Event handler for app list update. Stores the returned application list
		in the respective sub category.
		*/
		private function onAppListUpdate(evt:SLEvent):void
		{
			//get the previous category that was updated.
			var category:SubCategory = this.category.subCategories[this.subCategoryIter.getIndex()-1];
			
			//parse the application string into an array of applications
			var apps:Array = main.appManager.parseAppString(evt.argument);
			
			//set the application array in the respective category
			category.applications = apps;
			
			main.debugger.write("Received Application List for " + category.name + " => " + evt.argument);
			this.updateNextCategory();
		}
		
		/*
		updateNextCategory
		Makes an ExternalInterface call to GetApplicationList for
		the next category pointed to by the subCategoryIter.
		*/
		private function updateNextCategory():void
		{
			if(this.subCategoryIter.hasNext())
			{
				//get next category
				var category:SubCategory = this.subCategoryIter.next();
				
				//Trigger SL client to send us an updated app list for the next category
				if(ExternalInterface.available)
					ExternalInterface.call("GetApplicationList", category.id);
				
				main.debugger.write("Getting Application List for " + category.name);
			}
			else //we are done loading all the apps for each sub category
			{
				main.model.removeEventListener(SLEvent.UPDATE_APP_LIST, this.onAppListUpdate);
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		/*
		onAllAppsLoaded
		Event handler for load complete on all applications in each sub category.
		*/
		private function onAllAppsLoaded(evt:Event):void 
		{
			this.selector.enabled = true;
			LoadingView.getInstance().hideLoader();
			
			//set drop down list and search data provider
			this.selector.dataProvider = this.createDropDownDP();
			this.searchField.dataProvider = this.createSearchDP();
			
			//listen for drop down item click
			this.selector.addEventListener(SLEvent.LIST_ITEM_CLICK, this.onSubCategoryClick);
		}
		
				/*
		createDropDownDP
		Creates the SubCategory drop down list shown when the sub category selector is
		clicked.
		*/
		private function createDropDownDP():Vector.<IListItemObject>
		{
			var dp:Vector.<IListItemObject> = new Vector.<IListItemObject>();
			dp.push(new SubCategory("-1", "allCategory", "All " + category.localeName, "-1"));
			for(var i:uint = 0; i < category.subCategories.length; i++)
				dp.push(category.subCategories[i]);
			
			return dp;
		}
		
		/*
		createSearchDP
		Create the dataProvider used to populate the drop down in the search field.
		The data provider takes a Vector.<IListItemObject>.
		*/
		private function createSearchDP():Vector.<IListItemObject> 
		{
			var dp:Vector.<IListItemObject> = new Vector.<IListItemObject>();
			var apps:Array;
			var subCategory:SubCategory;
			
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				subCategory = category.subCategories[i];
				apps = subCategory.applications;
				for(var j:uint = 0; j < apps.length; j++)
					dp.push(apps[j]);
			}
			
			return dp;
		}
		
		/*
		createTileViews
		Creates all the list views for each sub category and stores them in
		the listViews dictionary. This includes a ListView for the 'All' category.
		*/
		/*private function createTileViews():void
		{
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				var list:ListView = createTileItems(category.subCategories[i]);
				this.listViews[category.subCategories[i].name] = list;
			}
		}*/
		
		/*
		createTileItems
		Creates a TileView of BoxShots for the specific category passed in based
		on the applications in that category. The new TileView is returned.
		*/
		/*private function createTileItems(subCategory:SubCategory):ListView
		{
			var listItems:Array = new Array();
			var apps:Array = subCategory.applications;
			for(var i:uint = 0; i < apps.length; i++)
			{
				var item:ListItem = new ListItem(apps[i], LIST_ITEM_WIDTH, LIST_ITEM_HEIGHT);
				//item.addEventListener(SLEvent.LIST_ITEM_CLICK, onAppListItemClick);
				listItems.push(item);
			}
				
			return new ListView(listItems, 0, 0);
		}*/
		
		/*
		displaySubCategory
		Change the loaded apps in the ScrollPane with 
		the apps for the passed in sub category.
		*/
		private function displaySubCategory(subCategory:SubCategory):void 
		{
			//check if we need to create the list view for this sub category
			/*if(this.listViews[subCategory.name] == null)
				this.listViews[subCategory.name] = this.createListItems(subCategory);
			
			var list:ListView = this.listViews[subCategory.name];
			//reset x and y
			list.x = list.y = 0;
			
			//reset filter if it exists
			if(list.filtered) 
				list.clearFilter();
			
			this.appPane.source = list;
			this.selector.label = subCategory.localeName;
			*/
		}
		
				
		/*
		displayAllApps
		Concats the ListViews for each sub category and sets
		that as the ScrollPane source.
		*/
		private function displayAllApps(evt:Event = null):void
		{
			var container:Sprite = new Sprite();
			var yPos:Number = 0;
			var list:ListView;
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				list = this.listViews[category.subCategories[i].name];
				if(list != null)
				{
					
					//reset list position
					list.y = yPos;
					yPos += list.listHeight;
					container.addChild(list);
				}
			}
			
			this.appPane.source = container;
			this.selector.label = "All " + this.category.localeName;
		}
		
		
		/*
		onSubCategoryClick
		Event listener for sub category drop down ListItem click. 
		*/
		private function onSubCategoryClick(evt:SLEvent):void {
			trace(evt.argument.listItemObj.itemLabel);
			//this.displaySubCategory(evt.argument.targetObj as SubCategory);
		}
	
		/*
		setPaneStyle
		Configure the Application ScrollPane with a custom skin.
		*/
		private function setPaneStyle():void
		{
			with(this.appPane)
			{
				//set scrollPane scrollbar width
				setStyle("scrollBarWidth", 8);
			
				//hide arrows
				setStyle("scrollArrowHeight", 0);
			
				//setup track
				setStyle("trackUpSkin", ScrollTrack_Invisible);
				setStyle("trackOverSkin", ScrollTrack_Invisible);
				setStyle("trackDownSkin", ScrollTrack_Invisible);
			
				//setup thumb
				setStyle("thumbUpSkin", ScrollThumb_Up_Light);
				setStyle("thumbOverSkin", ScrollThumb_Up_Light);
				setStyle("thumbDownSkin", ScrollThumb_Up_Light);
				setStyle("thumbIcon", thumbIcon_Light);
			
				//down arrow
				setStyle("downArrowUpSkin", ArrowSkin_Invisible); 
				setStyle("upArrowUpSkin", ArrowSkin_Invisible);
			} 
		}
		
				
		private function createMockCategory():void
		{
			var apps:Array = main.appManager.parseAppString("Counter-Strike|1^World Of Warcraft|2^League of Legends|3^Starcraft II|4");
			var subCat:SubCategory = new SubCategory("-1", "Test", "Test Category", "4");
			subCat.applications = apps;
			this.category.addSubCategory(subCat);
		}
		
	} //class
} //package
