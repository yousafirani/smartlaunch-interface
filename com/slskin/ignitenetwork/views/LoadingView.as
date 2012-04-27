/*
LoadingView.as
Defines the LoadingView component found in the library. Can
be used by other components to indicate that there is background
processing going on. 

This component is obstrusive and blocks access to the UI by displaying an overlay
over the entire UI.
*/

package com.slskin.ignitenetwork.views
{
	import flash.display.MovieClip;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.display.Sprite;
	import fl.text.TLFTextField;
	import com.slskin.ignitenetwork.*;
	import com.slskin.ignitenetwork.events.*;
	import com.slskin.ignitenetwork.components.LoaderCloseButton;

	public class LoadingView extends MovieClip
	{
		/* Constants */
		private const DEFAULT_TEXT:String = "Loading..."; //default loading text
		private const TLF_DEFAULT_PADDING:Number = 10; //default padding around the TLF
		private const OVERLAY_COLOR:uint = 0x000000;
		private const OVERLAY_ALPHA:Number = .7;
		
		/* Singleton instance */
		private static var instance:LoadingView;
		
		/* private vars */
		private var overlay:Sprite; //overlay used as a background for the loader
		private var loadingTLF:TLFTextField; //The textfield used to display loading
		private var closeButton:LoaderCloseButton;
		
		
		/* Adds Loading View to this display object */
		public static var parentObj:DisplayObjectContainer;
		
		public function LoadingView(key:SingletonKey) 
		{
			if(key == null)
				throw new Error("Error: Instantiation failed: Use LoadingView.getInstance() instead of new.");
			else
			{
				//get a reference to the tlf
				this.loadingTLF = this.loader.loadingTLF;
				this.overlay = new Sprite();
				this.closeButton = new LoaderCloseButton();
				
				this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
				this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
			}
		}
		
		/*
		loadingText
		Setter for the loading tlf text.
		*/
		public function set loadingText(str:String):void 
		{
			if(this.stage != null)
			{
				this.loadingTLF.text = str;
				this.loadingTLF.width = this.loadingTLF.textWidth + this.loadingTLF.paddingLeft + TLF_DEFAULT_PADDING;
				this.loader.width = this.loadingTLF.width;
				this.centerLoader();
				this.positionCloseButton();
			}
		}
		
		/*
		getInstance
		returns the single instance to this object.
		*/
		public static function getInstance():LoadingView
		{
			if(LoadingView.instance == null)
			{
				LoadingView.instance = new LoadingView(new SingletonKey);
				return LoadingView.instance;
			}
			else
				return LoadingView.instance;
		}
		
		/*
		onAdded
		Show the overlay, set the default text, and position the UI
		elements correctly.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			this.stage.addEventListener(Event.RESIZE, onStageResize);
			
			
			//setup the overlay
			this.overlay.graphics.clear();
			this.overlay.graphics.beginFill(this.OVERLAY_COLOR, this.OVERLAY_ALPHA);
			this.overlay.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			this.overlay.graphics.endFill();
			this.addChildAt(this.overlay, 0);
			
			//setup default loading text
			this.loadingText = Language.translate("Loading", this.DEFAULT_TEXT);
			this.disableClose();
		}
		
		/*
		showLoader
		Adds the LoadingView to the parentObj.
		*/
		public function showLoader():void
		{
			if(LoadingView.parentObj == null)
				throw new Error("No parent display object defined in LoadingView.parentObj");
			
			//add to stage if we aren't already added
			if(this.stage == null)
				LoadingView.parentObj.addChild(this);
		}
		
		/*
		hideLoader
		Remove the LoadingView from the parentObj.
		*/
		public function hideLoader(evt:Event = null):void
		{
			if(stage != null)
			{
				this.removeChild(this.overlay);
				this.stage.removeEventListener(Event.RESIZE, onStageResize);
				this.dispatchEvent(new Event(Event.CLOSE));
				LoadingView.parentObj.removeChild(this);
			}
		}
		
		/*
		enableClose
		Enables the closing of the loading view by clicking anywhere.
		*/
		public function enableClose():void 
		{
			this.addChild(this.closeButton);
			this.closeButton.addEventListener(MouseEvent.CLICK, hideLoader);
		}

		/*
		disableClose
		Disables the closing of the loading view by clicking.
		*/
		public function disableClose():void 
		{
			if(this.contains(this.closeButton))
				this.removeChild(this.closeButton);
			
			if(this.closeButton.hasEventListener(MouseEvent.CLICK))
				this.closeButton.removeEventListener(MouseEvent.CLICK, hideLoader);
		}
		

		/*
		onRemoved
		On loader removed, listen for added event again.
		*/
		private function onRemoved(evt:Event):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		centerLoader
		Centers the loading tlf relative to the stage size.
		*/
		private function centerLoader():void
		{
			if(stage == null) return;

			this.loader.x = (stage.stageWidth - loader.width) / 2;
			this.loader.y = (stage.stageHeight- loader.height) / 2;
		}
		
		/*
		positionCloseButton
		positions the close button relative to the loader window.
		*/
		private function positionCloseButton():void
		{
			if(stage == null) return;
			
			this.closeButton.x = this.loader.x + this.loader.width;
			this.closeButton.y = this.loader.y;
		}
		
		/*
		onStageResize
		Resizes the overlay and centers the loader.
		*/
		private function onStageResize(evt:Event):void
		{
			if(stage == null) return;
			
			this.centerLoader();
		}
	
	}//class
}//package

//This class is used to simulate the singletone design pattern. AS3
//does not allow private constructiors.
internal class SingletonKey {};
