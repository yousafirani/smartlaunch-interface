package com.slskin.ignitenetwork.views.desktop 
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import flash.utils.Dictionary;
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.apps.MainCategory;
	import flash.display.Sprite;
	
	public class DesktopView extends SLView
	{
		/* Member fields */
		private var dock: DockView;
		private var home: HomeView;
		private var dashboard: DashBoardView;
		private var footer: FooterView;
		private var currentCategoryView: SLView; // reference to current category view
		private var categoryViews: Dictionary; // stores a CategoryView for each main category with the key as category.name.
		private var fadeTween: Tween;
		
		public function DesktopView() 
		{
			this.tabChildren = false;
			dock = new DockView();
			home = new HomeView();
			footer = new FooterView();
			dashboard = new DashBoardView();
			this.categoryViews = new Dictionary();
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/** 
		 * Listens for added to stage event.
		 */
		private function onAdded(evt: Event): void
		{
			this.startPos = new Point(0, 0);
			this.moveToStart();
			
			// add the main desktop elements.
			this.addChild(dashboard);
			this.addChild(dock);
			this.addChild(footer);
			
			// listen for dock click events.
			this.dock.addEventListener(SLEvent.DOCK_ICON_CLICK, onDockIconClick);
			
			// create main category views
			this.createCategoryViews();
			
			// default to home screen.
			this.showCategoryView("Home");
			this.dock.clickIcon("Home");
			
			// listen for page change events from SL
			main.model.addEventListener(SLEvent.PAGE_CHANGE, onPageChangeEvent);
			
			this.showView();
		}
		
		/**
		 * Creates a new CategoryView object for each main category that has 
		 * atleast 1 sub category. The category view is responsible for displaying
		 * the sub categories and repective application in each sub category.
		 */
		private function createCategoryViews(): void
		{
			var categories: Array = main.appManager.categories;
			var category: MainCategory;
			
			for (var i: uint = 0; i < categories.length; i++)
			{
				category = categories[i];
				
				// If the category has sub categories,
				// create a CategoryView and store it in the local dictionary
				// indexed by the category name.
				if (category.numOfSubCategories != 0)
					this.categoryViews[category.name] = new CategoryView(category);
				else if (category.name == "Home")
					this.categoryViews[category.name] = this.home;
			}
		}
		
		/**
		 * Displays a CategoryView based on the passed in
		 * category name.
		 */
		private function showCategoryView(categoryName: String): void
		{
			var view: SLView = this.categoryViews[categoryName];
			
			// if we are already showing the view return
			if (view == this.currentCategoryView)
				return;
				
			if (view != null)
			{
				if (this.currentCategoryView != null) {
					this.currentCategoryView.hideView();
				}
				
				// check if the window is already on the stage
				if (view.stage == null)
				{
					this.addChildAt(view, 0);
				}
				else
				{
					view.setupView();
					view.showView();
				}
				
				this.currentCategoryView = view;
			}
			else
				throw new Error("Cannot find a CategoryView defined for category:  " + categoryName);
		}
		
		/**
		 * No effects, just gets added to stage.
		 */
		public override function showView(evt: Event = null): void {}
		
		/**
		 * Fade to black then call hide view.
		 */
		public override function hideView(evt: Event = null): void
		{
			// create a black overlay
			var overlay: Sprite = new Sprite();
			overlay.graphics.beginFill(0x000000, 1);
			overlay.graphics.drawRect(0, 0, main.getStageWidth(), main.getStageHeight());
			overlay.graphics.endFill();
			overlay.alpha = 0;
			this.addChild(overlay);
			
			// set all object references to null for garbage collection
			this.home.destroyPlayers();
			this.home = null;
			this.dashboard = null;
			this.dock = null;
			this.footer = null;
			
			this.fadeTween = new Tween(overlay, "alpha", Strong.easeOut, 0, 1, 1, true);
			this.fadeTween.addEventListener(TweenEvent.MOTION_FINISH, onFadeOutComplete);
		}
		
		/**
		 * Dispatach a HIDE_COMPLETE event.
		 */
		private function onFadeOutComplete(evt: TweenEvent): void 
		{
			this.fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, onFadeOutComplete);
			this.dispatchEvent(new Event(SLView.HIDE_COMPLETE));
		}
		
		
		/**
		 * Event handler for dock icon click.
		 * General behavior is to switch between different app browsers. However,
		 * behavior varies for some of the dock icons.
		 */
		private function onDockIconClick(evt: SLEvent): void 
		{
			var category: MainCategory = (evt.argument as MainCategory);
			this.showCategoryView(category.name);
		}
		
		/**
		 * Parse the page and call showCategoryView.
		 */
		private function onPageChangeEvent(evt: SLEvent): void
		{
			var page: String = evt.argument;
			switch(page)
			{
				case "Main": 
					this.showCategoryView("Home");
					this.dock.clickIcon("Home");
					break;
			}
		}
	} // class
} // package
