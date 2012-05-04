/*
WallpaperManager.as
Manages the multiple wallpapers defined in the config.xml.
Adds the wallpapers to stage (fades them in/out) and scrolls through
them accordingly.

The wallpaper manager gets added to stage by the main document class.
*/
package com.slskin.ignitenetwork
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import fl.containers.UILoader;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
 	import fl.transitions.easing.*;
 	import flash.utils.Timer;
 	import flash.events.TimerEvent;
 	import com.slskin.ignitenetwork.util.ArrayIterator;
 	import flash.display.DisplayObject;
 	import flash.display.Loader;
	
	public class WallpaperManager extends MovieClip 
	{
		/* Member variables */
		private var currentImage:UILoader; //stores a reference to the current background image
		private var tmpImage:UILoader; //stores a reference to a temp UILoader reference when attempting to load a new wallpaper.
		private var fadeIn:Tween; //used to fade in the background
		private var fadeOut:Tween; //used to fade out the background
		private var main:Main; //reference to the document class
		private var timer:Timer; //maintains the interval for changing wallpapers
		private var imagePaths:Array; //stores urls to background images.
		private var imageIterator:ArrayIterator; //iterator that points to the current index in imagePaths
		
		/*
		Constructor
		Instantiate the UILoader used to load images and
		add event listener for added to stage.
		*/
		public function WallpaperManager() {
			//listen for added to stage event.
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAddedhandler for added to stage event.
		Configures the UI loader and sets up the timer to
		switch between background images at an interval.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//add stage resize listeners
			this.stage.addEventListener(Event.RESIZE, this.onStageResize);
			
			//set document class reference
			this.main = (root as Main);
		}
		
		/*
		init
		Read the wallpaper data from the config.xml, start the wallpaper
		scrolling timer, and load the first wallpaper.
		*/
		public function init():void
		{
			var numWallPapers:uint = main.config.Images.backgrounds.bg.length();
			this.imagePaths = new Array();
			
			//move all the urls into a local array
			for(var i:uint = 0; i < numWallPapers; i++)
				this.imagePaths.push(main.config.Images.backgrounds.bg[i]);
				
			//create iterator for image url array
			this.imageIterator = new ArrayIterator(this.imagePaths);
			
			//if there is more than 1 wallpaper 
			//setup for scrolling through the wallpapers
			if(numWallPapers > 1)
			{
				var randomOrder:Boolean = (main.config.Images.backgrounds.@randomOrder == "true");
				var timerDelay:Number = Number(main.config.Images.backgrounds.@autoScrollSeconds) * 1000;
				
				//if randomOrder is set, shuffle the imagePaths array
				if(randomOrder)
					this.shuffle(this.imagePaths);
			
				this.timer = new Timer(timerDelay);
				
				//listen for tick event
				this.timer.addEventListener(TimerEvent.TIMER, onIntervalTick);
				this.timer.start();
			}
			
			//load the first image
			this.currentImage = new UILoader();
			configureLoader(this.currentImage);
			
			//load the login background
			this.currentImage.removeEventListener(Event.COMPLETE, this.onImageLoadComplete);
			this.currentImage.load(new URLRequest(this.imageIterator.next()));
			
			//add the current image to stage
			this.addChild(this.currentImage);
			
			//tween in the current image
			this.fadeIn = new Tween(this.currentImage, "alpha", Strong.easeInOut, this.currentImage.alpha, 1, 2, true);
			this.fadeIn.addEventListener(TweenEvent.MOTION_FINISH, onTweenComplete);
		}
		
		/*
		stopScrolling
		Stops the timer from ticking.
		*/
		public function stopTimer():void 
		{
			if(this.timer != null)
				this.timer.stop();
		}
		
		/*
		startScrolling
		Starts the timer.
		*/
		public function startTimer():void 
		{
			if(this.timer != null && this.imagePaths.length > 1)
				this.timer.start();
		}
		
		/*
		restartTimer
		Resets the timer used to scroll through background images.
		*/
		public function resetTimer():void 
		{
			if(this.timer != null)
			{
				this.timer.stop();
				this.timer.start();
			}
		}
		
		/*
		fadeOutImage
		Wrapper to fade out current image.
		*/
		public function fadeOutImage():void {
			this.fadeOut = new Tween(this.currentImage, "alpha", Strong.easeInOut, this.currentImage.alpha, 0, 1, true);
		}
		
		/*
		configureLoader
		Configures the passed in UILoader with parameters from the config.xml and
		adds appropriate event listeners.
		*/
		private function configureLoader(loader:UILoader):void
		{
			with(loader)
			{
				alpha = 0;
				maintainAspectRatio = true;
				scaleContent = true;
				x = 0;
				y = 0;
				width = main.getStageWidth();
				height = main.getStageHeight();
				addEventListener(IOErrorEvent.IO_ERROR, onImageLoadError);
				addEventListener(Event.COMPLETE, onImageLoadComplete);
			}
		}
		
		/*
		shuffle
		Randomly shuffles the given array. The idea is to shuffle in
		place by selecting a random index (within our range)
		and swapping with our current index. The range is i to array.length.
		Anything before that is already shuffled.
		
		This operation will take O(n).
		*/
		private function shuffle(arr:Array):void
		{
			var maxRange:uint = arr.length-1;
			var range:uint;
			var swapIndex:uint = 0;
			var tmp:Object = null;
			
			for(var i:uint = 0; i < arr.length; i++)
			{
				//calculate new range
				range = maxRange - i;
				
				//generate a random index within our range
				swapIndex = Math.round(Math.random() * range) + i;
				
				//trace(i, (i+range), "swap index:" + swapIndex);
				
				//swap arr[i] and arr[swapIndex]
				tmp = arr[i];
				arr[i] = arr[swapIndex];
				arr[swapIndex] = tmp;
			}
			
			//trace(arr);
		}
		
		/*
		onIntervalTick
		Event listener for the interval timer tick. When the interval
		timer ticks, the background image needs to change. This function takes
		care of the change.
		*/
		private function onIntervalTick(evt:TimerEvent):void
		{
			//restart our iterator if we have reached the end
			if(!this.imageIterator.hasNext()) 
				this.imageIterator.reset();
				
			//load the next url
			this.loadImage(this.imageIterator.next());
		}
		
		/*
		loadImage
		loads the image referred to by the passed in path.
		*/
		public function loadImage(url:String):void
		{
			//make sure we aren't loading the same image!
			if(url == this.currentImage.source)
				return;
			
			//create tmp UILoader
			this.tmpImage = new UILoader;
			this.configureLoader(this.tmpImage);
			
			this.tmpImage.source = url;
			this.tmpImage.load();
		}
		
		/*
		onImageLoadComplete
		Switches to the tmpImage if the load was successful.
		*/
		private function onImageLoadComplete(evt:Event):void
		{
			//add loader to stage
			this.addChild(this.tmpImage);
			
			//fade in loader and fade out current loader
			this.fadeIn = new Tween(this.tmpImage, "alpha", Strong.easeInOut, this.tmpImage.alpha, 1, 1, true);
			this.fadeOut = new Tween(this.currentImage, "alpha", Strong.easeInOut, this.currentImage.alpha, 0, 1, true);
						
			//listen for fadeOut complete to remove current image from stage
			this.fadeOut.addEventListener(TweenEvent.MOTION_FINISH, onFadeOut);
			
			//set the new current image
			this.currentImage = this.tmpImage;
		}
		
		/*
		onFadeOut
		FadeOut tween complete event handler. 
		Removes the target from the stage.
		*/
		private function onFadeOut(evt:TweenEvent):void
		{
			var obj:UILoader = (evt.target as Tween).obj as UILoader;
			//trace(obj);
			if(this.contains(obj))
				this.removeChild(obj);
		}
		/* 
		onTweenComplete
		dispatched when the background image is done tweening initially.
		*/
		private function onTweenComplete(evt:TweenEvent):void {
			this.fadeIn.removeEventListener(TweenEvent.MOTION_FINISH, onTweenComplete);
			this.dispatchEvent(evt);
		}
		
		/*
		onStageResize
		Event handler for stage resize. Resizes the
		current UI loader to be the same size as the 
		stage.
		*/
		private function onStageResize(evt:Event):void
		{
			if(this.currentImage == null) return;
			
			//resize the current image to fit screen
			this.currentImage.width = main.getStageWidth();
			this.currentImage.height = main.getStageHeight();
		}
		
		/*
		onImageLoadError
		If the image file is not found or there is
		an IOError.
		*/
		private function onImageLoadError(evt:IOErrorEvent):void {
			main.debugger.write(evt.toString());
		}

	} //class
} //package
