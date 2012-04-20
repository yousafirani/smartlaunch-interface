/*
Implemention of the dock UI element on the home screen.
The dock displays icons that represent each application
category found in SL.
*/
package com.slskin.ignitenetwork.views.desktop
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import flash.display.MovieClip;
	import flash.external.ExternalInterface;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.display.BlendMode;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.components.SLDockIcon;
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.apps.MainCategory;
	import com.slskin.ignitenetwork.apps.Category;
	import com.slskin.ignitenetwork.components.ListItem;
	import com.slskin.ignitenetwork.components.DottedSeperatorShort;
	import com.slskin.ignitenetwork.components.GreyArrow;
	import com.slskin.ignitenetwork.apps.Application;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	public class DockView extends SLView 
	{
		/* Constant fileds */
		private const DOCK_HEIGHT:Number = 65;
		private const TOP_PADDING:Number = 8;
		private const LEFT_RIGHT_PADDING:Number = 10;
		private const ICON_PADDING:Number = 15; //padding between icons
		
		/* Member field */
		private var iconHolder:MovieClip;
		private var iconMap:Dictionary; //category name => SLDockIcon
		private var dockBackground:Sprite;
		private var selectedIcon:SLDockIcon; //currently selected dock icon
		private var clickedIcon:SLDockIcon; //recently clicked dock icon
		
		public function DockView() 
		{
			//create iconHolder
			this.iconHolder = new MovieClip();
			this.iconMap = new Dictionary();
			iconHolder.x = this.LEFT_RIGHT_PADDING;
			iconHolder.y = this.TOP_PADDING;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded 
		Listens for added to stage event.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAdded);
			
			//create the dock icons and the dock background
			this.refreshDockIcons();
			
			//move dock into start position
			centerX = (this.main.getStageWidth() - this.dockBackground.width) / 2;
			this.startPos = new Point(centerX, (this.height * -1));
			this.moveToStart();
			
			//add iconHolder as child
			this.addChild(iconHolder);
			
			//listen for category updates from the SL client
			main.appManager.addEventListener(SLEvent.UPDATE_CATEGORY_LIST, onCategoryListUpdate);
			
			this.showView();
		}
		
		/*
		showView
		Slide in dock from top.
		*/
		public override function showView(evt:Event = null):void
		{
			//center relative to dockBackground
			if(this.dockBackground != null)
				centerX = (this.main.getStageWidth() - this.dockBackground.width) / 2;
				
			this.endPos = new Point(centerX, 0);
			this.xTween = new Tween(this, "x", Strong.easeInOut, this.x, this.endPos.x, 1, true);
			this.yTween = new Tween(this, "y", Strong.easeInOut, this.y, this.endPos.y, 1, true);
		}
		
		/*
		onCategoryListUpdate
		Listener for category list update event triggered by SL client.
		*/
		private function onCategoryListUpdate(evt:SLEvent):void {
			this.refreshDockIcons();
		}
		
		/*
		refreshDockIcons
		Update the dock with the main category array from the AppManager.
		*/
		private function refreshDockIcons():void
		{
			//get a collection of the main categories from the
			//app manager.
			var categories:Array = main.appManager.categories;
			
			//remove all icons
			while(iconHolder.numChildren > 0)
				iconHolder.removeChildAt(0);
				
			//add new dock icons for each category
			var dockIcon:SLDockIcon;
			var combinedIconWidth:Number = 0;
			
			for(var i:uint = 0; i < categories.length; i++)
			{
				dockIcon = new SLDockIcon(categories[i] as MainCategory);
				this.iconMap[ (categories[i] as MainCategory).name ] = dockIcon;
				
				dockIcon.x = (i * dockIcon.ICON_SIZE) + (i * this.ICON_PADDING);
				
				//update combined width
				combinedIconWidth += dockIcon.ICON_SIZE + this.ICON_PADDING;
				
				//add dock Icon to holder
				iconHolder.addChildAt(dockIcon, 0);
				
				//listen for mouse click event on each icon
				dockIcon.addEventListener(MouseEvent.CLICK, onDockIconClick);
			}
			
			//create dock background
			this.drawDockBackground(combinedIconWidth, this.DOCK_HEIGHT);
			
			//update the view center
			this.updateCenter();
			this.x = centerX;
		}
		
		/*
		drawDockBackground
		Draws the dock background and adds filters to it.
		*/
		private function drawDockBackground(dockWidth:Number, dockHeight:Number):void 
		{
			//remove it if it exists
			if(this.dockBackground != null && this.dockBackground.stage != null)
				this.removeChild(this.dockBackground);
			
			//indicates how much to cut off the top of the dock.
			var dockCutOff:Number = -10;
			
			//update height and width
			dockHeight += (dockCutOff * -1);
			dockWidth += this.LEFT_RIGHT_PADDING;
			
			var dock:Sprite = new Sprite();
			dock.graphics.beginFill(0x333333);
			dock.graphics.lineStyle(1.5, 0xFFFFFF, 1, true, "normal", CapsStyle.ROUND, JointStyle.ROUND); 
			dock.graphics.drawRoundRect(0, dockCutOff, dockWidth, dockHeight, 8);
			dock.graphics.endFill();
	
			//add glow
			var glow:GlowFilter = new GlowFilter(0x666666, 1, 6, 6, 1, 1, false, false);
			dock.filters = new Array(glow);
	
			//set blend mode
			dock.blendMode = BlendMode.MULTIPLY;
			
			//store a reference to the dock
			this.dockBackground = dock;
			
			//add dock background at 0
			this.addChildAt(this.dockBackground, 0);
		}
		
		/*
		clickIcon
		Takes a category name and simulates a mouse click on the appropriate
		SLDockIcon found in iconMap.
		*/
		public function clickIcon(categoryName:String):void
		{
			if(categoryName == null) return;
			if(this.iconMap == null) return;
			
			var dockIcon:SLDockIcon = this.iconMap[categoryName];
			
			if(dockIcon == null)
				throw new Error(categoryName + " does not have a corresponding SLDockIcon.");
				
			dockIcon.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		}
		
		/*
		onDockIconClick
		Event handler for dock icon click. Dispatch the event on
		behalf of the dock depending on the number of sub categories
		in the dock's category.
		*/
		private function onDockIconClick(evt:MouseEvent):void 
		{
			//get a reference to the category that was clicked
			var category:MainCategory = (evt.currentTarget as SLDockIcon).category;
			
			this.clickedIcon = evt.currentTarget as SLDockIcon;
							
			//main category has sub categories, dispatch event.
			//The home view listens for DOCK_ICON_CLICK and acts accordingly.
			if(category.numOfSubCategories > 0 || category.name == "Home")
			{
				var slEvent:SLEvent = new SLEvent(SLEvent.DOCK_ICON_CLICK, category);
				this.dispatchEvent(slEvent);
							
				//deselect the previous icon
				if(this.selectedIcon != null)
					this.selectedIcon.isSelected = false;
					
				//select the new icon
				this.selectedIcon = evt.currentTarget as SLDockIcon;
				this.selectedIcon.isSelected = true;
			}
			else if(category.numOfApps == 1)//Launch the only available app
			{
				this.main.appManager.launchCategory(category);
			}
			else //More than 1 application with 0 sub categories.
			{
				//make sure the drop down isn't already visible
				if(!this.clickedIcon.dropDownVisible)
				{
					this.clickedIcon.showLoader();
					
					//listen for app update event
					this.main.model.addEventListener(SLEvent.UPDATE_APP_LIST, onReceiveAppList);
					
					//send request to SL client
					if(ExternalInterface.available)
						ExternalInterface.call("GetApplicationList", category.id);
				
					evt.stopPropagation();
				}
			}
		}
		
		/*
		onReceiveAppList
		Parse the application list, create a list view, and send it to the clicked icon.
		*/
		public function onReceiveAppList(evt:SLEvent):void
		{
			//remove event listener
			this.main.model.removeEventListener(SLEvent.UPDATE_APP_LIST, onReceiveAppList);
			this.clickedIcon.hideLoader();
			
			//parse application string
			//var str:String = "Your Profile|-2^Personal Drive|-1^Mouse Settings|22^Sound Settings|23";
			var apps:Array = this.main.appManager.parseAppString(evt.argument);
			
			//create list view based on list of applications
			var listItems:Array = new Array();
			var item:ListItem;
			for(var i:uint = 0; i < apps.length; i++)
			{
				//blue - 0x0080FF
				item = new ListItem(apps[i], 150, 30, 0x666666, "11", 0xe1e1e1, 
									new DottedSeperatorShort(), new GreyArrow(), null, 16);
				
				item.addEventListener(MouseEvent.CLICK, onAppItemClick);
				listItems.push(item);
			}
			
			this.clickedIcon.displayDropDown(new ListView(listItems, 0, 0));
		}
		
		/*
		onAppItemClick
		Launches the app silently.
		*/
		private function onAppItemClick(evt:MouseEvent):void
		{
			var app:Application = ((evt.currentTarget as ListItem).targetObj as Application);
			this.main.appManager.launchApp(app, true);
		}
		
	} //class
} //package