/*
CategoryView.as
Responsible for displaying MainCategory that have
SubCategories. The respective applications
are displayed in a ScrollPane in a TileView.
*/
package com.slskin.ignitenetwork.views.desktop 
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import flash.events.TextEvent;
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.apps.MainCategory;
	import com.slskin.ignitenetwork.components.IListItem;
	import com.slskin.ignitenetwork.components.ListItem;
	import com.slskin.ignitenetwork.components.List;
	import com.slskin.ignitenetwork.components.TileList;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.apps.Category;
	import com.slskin.ignitenetwork.util.ArrayIterator;
	import com.slskin.ignitenetwork.apps.SubCategory;
	import com.slskin.ignitenetwork.apps.Application;
	import com.slskin.ignitenetwork.components.DropDownSelector;
	import com.slskin.ignitenetwork.components.SearchField;
	import com.slskin.ignitenetwork.util.Strings;
	import com.slskin.ignitenetwork.components.BoxShot;
	import fl.events.ScrollEvent;
	import fl.text.TLFTextField;
	import flash.net.URLRequest;
	import fl.transitions.easing.*;
	import fl.transitions.*;
	import flash.display.MovieClip;
	
	public class CategoryView extends SLView 
	{
		/* Constants */
		private const LEFT_PADDING:Number = -135; //Window left padding, makes room for dashboard
		private const TOP_PADDING:Number = -53; //Window top padding, makes room for footer
		private const ICON_PATH:String = "./assets/dock/";
		private const TOTAL_STRING:String = "{0} of {1}";
		private const BOX_VPADDING:Number = 10; //vertical padding between BoxShot tiles.
		private const BOX_HPADDING:Number = 30; //horizontal padding between BoxShot tiles.
		
		/* Member fields */
		public var category:MainCategory; //main category that this view displays
		private var subCategoryIter:ArrayIterator; //keeps track of current sub category while loading all apps
		private var boxShots:Dictionary; //a cache that stores the BoxShot objects for each category.
		private var selector:DropDownSelector; //a reference to the drop down selector on stage.
		private var searchField:SearchField; //a reference to the search field on stage.
		private var totalApps:int = 0; //count of total apps in this category.
		private var allCategory:SubCategory; //a sub category that includes all the subcategory apps.
		
		/* Member Fields */
		public function CategoryView(category:MainCategory) 
		{
			this.category = category;
			this.allCategory = new SubCategory("-1", "allCategory", "All " + category.localeName, "-1");
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
			this.statusTLF.autoSize = "left";
			
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
			
			/* DEBUG */
			if(main.model.getProperty("InjectApps") == "1")
			{
				this.createMockApps();
				this.onAllAppsLoaded(null);
				this.showView();
			}
			
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
			this.boxShots = new Dictionary();
			
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
			
			this.totalTLF.text = Strings.substitute(TOTAL_STRING, 0, this.totalApps);
			
			//listen for list item clicks on selector and search field
			this.selector.addEventListener(SLEvent.LIST_ITEM_CLICK, this.onSubCategoryClick);
			this.searchField.addEventListener(SLEvent.LIST_ITEM_CLICK, this.onSearchItemClick);
			this.searchField.addEventListener(SearchField.SEARCH_RESULTS, this.onSearchResults);
			this.scrollPane.addEventListener(ScrollEvent.SCROLL, onScrollPaneScroll);
			
			createBoxShots();
			this.displaySubCategory(allCategory);
		}
		
		/*
		createDropDownDP
		Creates the SubCategory drop down list shown when the sub category selector is
		clicked.
		*/
		private function createDropDownDP():Vector.<IListItem>
		{
			var dp:Vector.<IListItem> = new Vector.<IListItem>();
			dp.push(this.allCategory);
			for(var i:uint = 0; i < category.subCategories.length; i++)
				dp.push(category.subCategories[i]);
			
			return dp;
		}
		
		/*
		createSearchDP
		Create the dataProvider used to populate the drop down in the search field.
		The data provider takes a Vector.<IListItemObject>.
		*/
		private function createSearchDP():Vector.<IListItem> 
		{
			var dp:Vector.<IListItem> = new Vector.<IListItem>();
			var apps:Array;
			var subCategory:SubCategory;
			
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				subCategory = category.subCategories[i];
				apps = subCategory.applications;
				totalApps += apps.length;
				for(var j:uint = 0; j < apps.length; j++)
					dp.push(apps[j]);
			}
			
			return dp;
		}
		
		/*
		createBoxShots
		Creates all the BoxShot objects for each sub category and stores them in
		the the boxShots dictionary.
		*/
		private function createBoxShots():void
		{
			var allBoxShots:Array = new Array(); //used for a the allCategory.
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				var boxShotArr:Array = new Array();
				var apps:Array = category.subCategories[i].applications;
				
				for(var j:uint = 0; j < apps.length; j++)
				{
					var box:BoxShot = new BoxShot(apps[j]);
					box.addEventListener(SLEvent.LIST_ITEM_CLICK, onBoxShotClick);
					boxShotArr.push(box);
					allBoxShots.push(box);
				}
				
				this.boxShots[category.subCategories[i].name] = boxShotArr;
			}
			
			this.boxShots[this.allCategory.name] = allBoxShots;
		}
		
		
		/*
		displaySubCategory
		Change the loaded apps in the ScrollPane with 
		the apps for the passed in sub category.
		*/
		private function displaySubCategory(sc:SubCategory):void 
		{
			var boxShotArr:Array = this.boxShots[sc.name];
			var tl:TileList = new TileList(boxShotArr, this.scrollPane.width, BOX_VPADDING, BOX_HPADDING);
			this.scrollPane.source = tl;
			TransitionManager.start(tl, {type:Fade, direction:Transition.IN, duration:1, easing:Strong.easeOut});
			
			//update UI
			var subCatTotal:Number = (sc == this.allCategory ? this.totalApps : sc.applications.length);
			this.totalTLF.text = Strings.substitute(TOTAL_STRING, subCatTotal, this.totalApps);
			this.statusTLF.text = "Displaying " + sc.localeName;
			this.selector.label = sc.localeName;
			this.searchField.clearField();
		}
		
		/*
		onSearchResults
		Display search results in scroll pane. The search result event
		returns an array of ListItems, convert them to boxshots and display
		the boxshots in the scrollpane.
		*/
		private function onSearchResults(evt:SLEvent):void 
		{
			var searchResults:Array = (evt.argument as Array);
			var boxshotsArr:Array = new Array();
			
			for(var i:uint = 0; i < searchResults.length; i++)
			{
				var box:BoxShot = new BoxShot(searchResults[i].dataProvider);
				box.addEventListener(SLEvent.LIST_ITEM_CLICK, onBoxShotClick);
				boxshotsArr.push(box);
				
				//highlight search result in the BoxShot
				box.label.highlight(searchResults[i].highlightStart, searchResults[i].highlightEnd);
			}
			
			//set scrollpane
			var tl:TileList = new TileList(boxshotsArr, this.scrollPane.width, BOX_VPADDING, BOX_HPADDING);
			this.scrollPane.source = tl;
			TransitionManager.start(tl, {type:Fade, direction:Transition.IN, duration:1, easing:Strong.easeOut});
			
			//update UI
			this.totalTLF.text = Strings.substitute(TOTAL_STRING, searchResults.length, this.totalApps);
			this.statusTLF.text = "Search results for '" + this.searchField.text + "'";
			this.selector.label = "...";
			
		}
		
		
		/*
		onSubCategoryClick
		Event handler for sub category drop down ListItem click. 
		*/
		private function onSubCategoryClick(evt:SLEvent):void {
			this.displaySubCategory(evt.argument.dataProvider as SubCategory);
		}
		
		/*
		onBoxShotClick
		Event handler for box shot click.
		Launches the application.
		*/
		private function onBoxShotClick(evt:SLEvent):void {
			main.appManager.launchApp(evt.argument.dataProvider as Application);
		}
		
		/*
		onSearchItemClick
		Event handler for SearchField ListItem click. 
		Launch the application that was clicked on.
		*/
		private function onSearchItemClick(evt:SLEvent):void {
			main.appManager.verifyAppLaunch(evt.argument.dataProvider as Application);
		}
		
		/*
		onScrollPaneScroll
		Hide the AppDetailsView if it is visible.
		*/
		private function onScrollPaneScroll(evt:ScrollEvent):void {
			if(BoxShot.appDetails != null && BoxShot.appDetails.stage != null)
				this.main.removeChild(BoxShot.appDetails);
		}
		
		/*
		hideView
		Hide AppDetails View if it is visible.
		*/
		public override function hideView(evt:Event = null):void 
		{
			super.hideView();
			if(BoxShot.appDetails != null && BoxShot.appDetails.stage != null)
				this.main.removeChild(BoxShot.appDetails);
		}
	
		/*
		setPaneStyle
		Configure the Application ScrollPane with a custom skin.
		*/
		private function setPaneStyle():void
		{
			with(this.scrollPane)
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
				setStyle("thumbUpSkin", ScrollThumb_Up_Dark);
				setStyle("thumbOverSkin", ScrollThumb_Up_Dark);
				setStyle("thumbDownSkin", ScrollThumb_Up_Dark);
			
				//down arrow
				setStyle("downArrowUpSkin", ArrowSkin_Invisible); 
				setStyle("upArrowUpSkin", ArrowSkin_Invisible);
			} 
		}
		
				
		private function createMockApps():void
		{
			var appStr:String = "Counter-Strike|1^World of Warcraft|2^"+
			"League of Legends|3^Starcraft II|4^Warcraft III: Frozen Throne|6^"+
			"Call of Duty: Modern Warfare III|7^Counter-Strike: Source|9^Battlefield 3|10^"+
			"Left 4 Dead 2|320^Portal 2|342^Diablo 3|13";
			var apps:Array = main.appManager.parseAppString(appStr);
			var subCat:SubCategory = new SubCategory("-1", "Test", "Test Category", "4");
			subCat.applications = apps;
			this.category.addSubCategory(subCat);
		}
		
	} //class
} //package
