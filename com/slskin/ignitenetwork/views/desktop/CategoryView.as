/*
CategoryView.as
Responsible for displaying MainCategory that have
SubCategories. The SubCategories and respective applications
are displayed in a ScrollPane.
*/
package com.slskin.ignitenetwork.views.desktop 
{
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
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
	import com.slskin.ignitenetwork.components.ListItem;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.apps.Category;
	import com.slskin.ignitenetwork.util.ArrayIterator;
	import com.slskin.ignitenetwork.apps.SubCategory;
	import com.slskin.ignitenetwork.apps.Application;
	import com.slskin.ignitenetwork.components.PanelBackground;
	import com.slskin.ignitenetwork.components.DottedSeperatorShort;
	import com.slskin.ignitenetwork.components.GreyArrow;
	import fl.text.TLFTextField;
	
	public class CategoryView extends SLView 
	{
		/* Constants */
		private const LEFT_PADDING:Number = -135; //Window left padding, makes room for dashboard
		private const TOP_PADDING:Number = -45; //Window top padding, makes room for footer
		private const LIST_ITEM_WIDTH:Number = 250; //app list item width
		private const LIST_ITEM_HEIGHT:Number = 25; //app list item height
		
		/* Member fields */
		public var category:MainCategory; //main category that this view displays
		private var subCategoryIter:ArrayIterator; //keeps track of current sub category while loading all apps
		private var listViews:Dictionary; //a cache that stores the ListView objects for each sub category
		private var allListItems:Array; //stores references to all the list items, used for filtering
		private var dropDownList:ListView; //list view used as the drop down menu for the sub categery selector.
		private var selectedApp:ListItem; //the currently selected app in the list
		
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
			
			this.createMockCategory();
			//create drop down list
			this.createDropDownList();
			
			//update window padding to make room for
			//other desktop content.
			this.xPadding = this.LEFT_PADDING;
			this.yPadding = this.TOP_PADDING;
			super.setupView();
			
			//align title bar to center of window and set the title
			this.title.text = this.category.localeName;
				
			//Load all applications and listen for load complete
			this.loadAllApplications();
			this.addEventListener(Event.COMPLETE, this.onAllAppsLoaded);
			this.onAllAppsLoaded(null);
			this.showView();
			
			//display this view when the initial load is complete
			this.addEventListener(Event.COMPLETE, showView);
		}
		
		private function createMockCategory():void
		{
			var apps:Array = main.appManager.parseAppString("Counter-Strike|1^World Of Warcraft|2^League of Legends|3^Starcraft II|4");
			var subCat:SubCategory = new SubCategory("-1", "Test", "Test Category", "4");
			subCat.applications = apps;
			this.category.addSubCategory(subCat);
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
			LoadingView.getInstance().loadingText = "Loading " + category.name + "...";
			LoadingView.getInstance().showLoader();
			//instatitate collections used to store applications in this Category
			this.subCategoryIter = new ArrayIterator(this.category.subCategories);
			this.listViews = new Dictionary();
			
			//disable the selector while loading apps
			this.disableSelector();
			
			//listen for SLEvent.UPDATE_APP_LIST event
			main.model.addEventListener(SLEvent.UPDATE_APP_LIST, this.onAppListUpdate);
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
				
				//tell SL client to send us an updated app list for the
				//next category
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
		onAllAppsLoaded
		Event handler for all sub category applications load complete.
		*/
		private function onAllAppsLoaded(evt:Event):void 
		{
			this.enableSelector();
			this.enableSearch();
			this.createAllListViews();
			this.displayAllApps();
			LoadingView.getInstance().hideLoader();
		}
		
		/*
		createAllListViews
		Creates all the list views for each sub category and stores them in
		the listViews dictionary. This includes a ListView for the 'All' category.
		*/
		private function createAllListViews():void
		{
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				var list:ListView = createListItems(category.subCategories[i]);
				this.listViews[category.subCategories[i].name] = list;
			}
		}
		
		/*
		createListItems
		Creates a ListView of ListItems for the specific category passed in based
		on the applications in that category. The new ListView is returned.
		*/
		private function createListItems(subCategory:SubCategory):ListView
		{
			var listItems:Array = new Array();
			var apps:Array = subCategory.applications;
			for(var i:uint = 0; i < apps.length; i++)
			{
				var item:ListItem = new ListItem(apps[i], LIST_ITEM_WIDTH, LIST_ITEM_HEIGHT);
				item.addEventListener(SLEvent.LIST_ITEM_CLICK, onAppListItemClick);
				listItems.push(item);
			}
				
			return new ListView(listItems, 0, 0);
		}
		
		/*
		displaySubCategory
		Change the loaded apps in the ScrollPane with 
		the apps for the passed in sub category.
		*/
		private function displaySubCategory(subCategory:SubCategory):void 
		{
			//check if we need to create the list view for this sub category
			if(this.listViews[subCategory.name] == null)
				this.listViews[subCategory.name] = this.createListItems(subCategory);
			
			var list:ListView = this.listViews[subCategory.name];
			//reset x and y
			list.x = list.y = 0;
			
			//reset filter if it exists
			if(list.filtered) 
				list.clearFilter();
			
			this.appPane.source = list;
			this.loadAppDetails(list.getItemAt(0));
			this.setSelectorTitle(subCategory.localeName);
		}
		
				
		/*
		displayAllApps
		Concats the ListViews for each sub category and sets
		that as the ScrollPane source.
		*/
		private function displayAllApps(evt:Event = null):void
		{
			//clear searchfield
			this.searchField.searchTLF.text = "";
			
			var container:Sprite = new Sprite();
			var yPos:Number = 0;
			var list:ListView;
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				list = this.listViews[category.subCategories[i].name];
				if(list != null)
				{
									
					//reset filter if it exists
					if(list.filtered) 
						list.clearFilter();
					
					//reset list position
					list.y = yPos;
					yPos += list.listHeight;
					container.addChild(list);
				}
			}
			
			this.appPane.source = container;
			this.setSelectorTitle("All " + this.category.localeName);
		}
		
		/*
		displayFilter
		Sets the source of the ScrollPane to ListItems that match the
		passed in filter. ListItems are compared to the filter based on
		the itemLabel.
		*/
		private function displayFilter(filterStr:String):void
		{
			var container:Sprite = new Sprite();
			var yPos:Number = 0;
			var list:ListView;
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				list = this.listViews[category.subCategories[i].name];
				if(list != null) 
				{
					list.y = yPos;
					list.filterList(filterStr);
					yPos += list.listHeight;
					container.addChild(list);
				}
			}
			
			this.appPane.source = container;
			this.loadAppDetails(list.getItemAt(0));
			this.setSelectorTitle("...");
		}
		
		/*
		onAppListItemClick
		Event handler for the application list item click.
		*/
		private function onAppListItemClick(evt:Event):void {
			this.loadAppDetails(evt.target as ListItem);
		}
		
		/*
		loadAppDetails
		Given a list item that represents an application, load
		the application details in the appDetailsView and select the
		list item object.
		*/
		private function loadAppDetails(appListItem:ListItem):void
		{
			if(appListItem == null) return;
			
			//unselect the old selected app
			if(this.selectedApp != null)
				this.selectedApp.selected = false;
			
			//set the new selected app
			this.selectedApp = appListItem;
			this.selectedApp.selected = true;
			this.appDetailsView.loadApp((this.selectedApp.targetObj as Application));
		}
		
		/*
		createDropDownList
		creates the drop down view shown when the sub category selector is
		clicked.
		*/
		private function createDropDownList():void
		{
			//create the ListView based on the sub categories
			var listItems:Array = new Array();
			var listItem:ListItem;
			
			//create the all category and add it to the list
			var allCategory:SubCategory = new SubCategory("-1", "allCategory", "All " + category.localeName, "-1");
			var allListItem:ListItem = new ListItem(allCategory, 150, 25, 0x333333, "11", 
										0xe1e1e1, new DottedSeperatorShort(), new GreyArrow());
			//listen for click
			allListItem.addEventListener(SLEvent.LIST_ITEM_CLICK, displayAllApps);
			listItems.push(allListItem);
			
			//add the rest of the sub categories
			for(var i:uint = 0; i < category.subCategories.length; i++)
			{
				listItem = new ListItem(category.subCategories[i], 150, 25, 0x333333, "11", 
										0xe1e1e1, new DottedSeperatorShort(), new GreyArrow());
				
				//listen for listItem click
				listItem.addEventListener(SLEvent.LIST_ITEM_CLICK, onSubCategoryClick);
				listItems.push(listItem);
			}
			
			this.dropDownList = new ListView(listItems, 0, 0, new PanelBackground());
			
			//add drop down to the selector
			this.dropDownList.x = this.selector.title.x;
			this.dropDownList.y = this.selector.height;
			this.selector.addChild(this.dropDownList);
		}
		
		
		/*
		enableSearch
		Enables the search field and adds the proper event listeners
		*/
		private function enableSearch():void 
		{
			this.searchField.searchTLF.addEventListener(Event.CHANGE, onSearchInput);
			this.searchField.clearButton.visible = false;
			this.searchField.clearButton.addEventListener(MouseEvent.CLICK, function(event) { 
														  displayAllApps(); 
														  event.target.visible = false;
														  });
		}
		
		/*
		onSearchInput
		Event handler for search field change. Displays the filter with
		the searchField input.
		*/
		private function onSearchInput(evt:Event):void 
		{
			var searchInput:String = this.searchField.searchTLF.text;
			this.displayFilter(searchInput);
			
			//show clear button in there is text in the field
			this.searchField.clearButton.visible = (searchInput.length > 0);
		}
		
		/*
		enableSelector
		Enables the sub category selector and the mouse event listeners.
		*/
		private function enableSelector():void
		{
			this.selector.alpha = 1;
			this.selector.buttonMode = true;
			this.selector.useHandCursor = true;
			this.selector.addEventListener(MouseEvent.CLICK, onSelectorClick);
			stage.addEventListener(MouseEvent.CLICK, onMasterClick);
		}
		
		/*
		disableSelector
		Disables the sub category selector and the mouse event listeners.
		*/
		private function disableSelector():void
		{
			this.selector.alpha = .5;
			this.selector.buttonMode = false;
			this.selector.useHandCursor = false;
			this.dropDownList.visible = false;
			this.selector.removeEventListener(MouseEvent.CLICK, onSelectorClick);
			stage.removeEventListener(MouseEvent.CLICK, onMasterClick);
		}
		
		/*
		setSelectorTitle
		Sets the title for the sub category selector.
		*/
		public function setSelectorTitle(str:String):void
		{
			//this.selector.title.autoSize = TextFieldAutoSize.LEFT; 
			this.selector.title.text = str;
		}
		
		/*
		onSelectorClick
		Show or hide the sub category list view depending on its current state.
		*/
		private function onSelectorClick(evt:MouseEvent):void {
			toggleDropDown();
			evt.stopPropagation(); //don't let the event propegate up to parent displayObjects.
		}
		
		/*
		onMasterClick
		Hides the sub categeroy drop down list. This allows for users to click anywhere
		and hide the drop down list if the dropdown is visible. (Expected behavior
		from a drop down list.)
		*/
		private function onMasterClick(evt:MouseEvent):void 
		{
			if(this.dropDownList.visible)
				toggleDropDown();
		}
		
		/*
		toggleDropDown
		Toggles the sub category selector drop down menu.
		*/
		private function toggleDropDown():void
		{
			if(this.dropDownList.visible)
				this.selector.background.gotoAndStop("Up");
			else
				this.selector.background.gotoAndStop("Down");
			
			this.dropDownList.visible = !(this.dropDownList.visible);
		}
		
		
		/*
		onSubCategoryClick
		Event listener for sub category selector listItem click. 
		*/
		private function onSubCategoryClick(evt:SLEvent):void 
		{
			//clear searchfield as well
			this.searchField.searchTLF.text = "";
			
			//display the category.
			this.displaySubCategory(evt.argument.targetObj as SubCategory);
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
		
		
	} //class
} //package
