/**
 * Defines the ErrorView component found in the library. A modal type
 * window that displays an error dialogue in the center of the screen.
 * 
 * This component is obstrusive and blocks access to the UI by displaying an overlay
 * over the entire UI.
 *
 * Also lets the user play some Asteroids : )
 */

package com.slskin.ignitenetwork.views
{
	import flash.display.MovieClip;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.Sprite;
	import fl.text.TLFTextField;
	import flash.text.TextFieldAutoSize;
	import com.slskin.ignitenetwork.*;
	import com.slskin.ignitenetwork.events.*;
	import com.slskin.ignitenetwork.asteroids.AsteroidsGame;
	import com.slskin.ignitenetwork.components.ErrorCloseButton;

	public class ErrorView extends MovieClip
	{
		/* Constants */
		private const DEFAULT_TEXT: String = ": ("; // default error text
		private const OVERLAY_COLOR: uint = 0x000000;
		private const OVERLAY_ALPHA: Number = .7;
		private const CLOSE_BUTTON_PADDING: Number = 10;
		
		/* Singleton instance */
		private static var instance: ErrorView;
		
		/* private vars */
		private var overlay: Sprite; // overlay used as a background for the loader
		private var closeButton: ErrorCloseButton;
		private var asteroids: AsteroidsGame;
		
		/* Adds Loading View to this display object */
		public static var parentObj: DisplayObjectContainer;
		
		public function ErrorView(key: SingletonKey) 
		{
			if (key == null)
				throw new Error("Error:  Instantiation failed:  Use ErrorView.getInstance() instead of new.");
			else
			{
				this.overlay = new Sprite();
				this.closeButton = new ErrorCloseButton();
				closeButton.addEventListener(MouseEvent.CLICK, hideError);
				
				this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
				this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
			}
		}
		
		/**
		 * Setter for the error tlf text.
		 */
		public function set error(errorStr: String): void 
		{ 
			this.errorTLF.text = errorStr;
			this.centerErrorText();
		}
		
		/**
		 * returns the single instance to this object.
		 */
		public static function getInstance(): ErrorView
		{
			if (ErrorView.instance == null)
			{
				ErrorView.instance = new ErrorView(new SingletonKey);
				return ErrorView.instance;
			}
			else
				return ErrorView.instance;
		}
		
		/** 
		 * Show the overlay, set the default text, and setup listeners.
		 */
		private function onAdded(evt: Event): void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			this.stage.addEventListener(Event.RESIZE, onStageResize);

			// setup the screen
			this.overlay.graphics.clear();
			this.overlay.graphics.beginFill(this.OVERLAY_COLOR, this.OVERLAY_ALPHA);
			this.overlay.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			this.overlay.graphics.endFill();
			this.addChildAt(this.overlay, 0);
			
			// setup error tlf to autosize
			this.errorTLF.autoSize = TextFieldAutoSize.LEFT;
			
			// start asteroids
			this.asteroids = new AsteroidsGame();
			stage.addChild(this.asteroids);
			
			// setup close button
			closeButton.x = stage.stageWidth - closeButton.width - this.CLOSE_BUTTON_PADDING;
			closeButton.y = CLOSE_BUTTON_PADDING;
			this.addChild(closeButton);
		}
		
		/**
		 * Adds the ErrorView to the parentObj.
		 */
		public function showError(errorText: String = this.DEFAULT_TEXT): void
		{
			if (ErrorView.parentObj == null)
				throw new Error("No parent display object defined in ErrorView.parentObj");
			
			// add to stage if we aren't already added
			if (this.stage == null)
				ErrorView.parentObj.addChild(this);
			
			this.error = errorText;
		}
		
		/**
		 * Remove the ErrorView from the parentObj.
		 */
		public function hideError(evt: Event = null): void
		{
			if (stage != null)
			{
				if (this.asteroids != null)
					stage.removeChild(this.asteroids);
				
				this.removeChild(this.overlay);
				this.removeChild(this.closeButton);
				this.stage.addEventListener(Event.RESIZE, onStageResize);
				ErrorView.parentObj.removeChild(this);
			}
		}

		/**
		 * On error removed, listen for added event again.
		 */
		private function onRemoved(evt: Event): void {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/**
		 * Centers the tlf relative to the stage size.
		 */
		private function centerErrorText(): void
		{
			if (stage == null) return;

			this.errorTLF.x = (stage.stageWidth - this.errorTLF.width) / 2;
			this.errorTLF.y = (stage.stageHeight- this.errorTLF.height) / 2;
		}
		
		/**
		 * Resizes the overlay and centers the loader.
		 */
		private function onStageResize(evt: Event): void
		{
			if (stage == null) return;
			
			this.centerErrorText();
		}
	}// class
}// package

// This class is used to simulate the singletone design pattern. AS3
// does not allow private constructiors.
internal class SingletonKey {};