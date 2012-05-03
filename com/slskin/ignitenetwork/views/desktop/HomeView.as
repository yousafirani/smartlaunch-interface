/*
HomeView.as
Responsible for displaying user defined videos and images on the home screen.
The content is defined in the config.xml file.
*/
package com.slskin.ignitenetwork.views.desktop  
{
	import com.slskin.ignitenetwork.views.SLView;
	import com.slskin.ignitenetwork.components.SpinnerLight;
	import com.slskin.ignitenetwork.util.Strings;
	import flash.events.Event;
	import flash.display.MovieClip;
	import flash.system.Security;
	import flash.display.BlendMode;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import fl.containers.UILoader;
	import flash.display.Sprite;
	import flash.display.BlendMode;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.events.MouseEvent;
	import flash.display.DisplayObject;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import fl.transitions.*;
	import fl.containers.ScrollPane;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.events.IOErrorEvent;
	import fl.text.TLFTextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.AntiAliasType;
	import flashx.textLayout.formats.VerticalAlign;
	import flash.text.TextFormat;
	import flashx.textLayout.elements.TextFlow
	import com.slskin.ignitenetwork.fonts.*;
	import flash.events.TextEvent;
	import flashx.textLayout.formats.TextLayoutFormat;
	import com.slskin.ignitenetwork.apps.Application;
	
	public class HomeView extends SLView
	{
		/* Constants */
		private const YOUTUBE_CHROMELESS_URL:String = "http://www.youtube.com/apiplayer?version=3";
		private const YOUTUBE_EMBEDDED_URL:String = "http://www.youtube.com/v/{0}?version=3&modestbranding=1&rel=0&fs=0";
		private const YOUTUBE_IMAGE_URL:String = "http://img.youtube.com/vi/{0}/default.jpg";
		private const LEFT_PADDING:Number = -135; //Window left padding, makes room for dashboard
		private const TOP_PADDING:Number = -53; //Window top padding, makes room for footer
		private const CONTENT_WIDTH:Number = 700;
		private const CONTENT_HEIGHT:Number = CONTENT_WIDTH / (16/9);
		private const THUMBNAIL_WIDTH:Number = 120;
		private const THUMBNAIL_HEIGHT:Number = 90;
		private const CONTROLS_PADDING:Number = 15; //paddding between content and media controls.
		private const THUMBNAIL_PADDING:Number = 10; //padding betweem thumbnails.
		private const CAPTION_FONT_SIZE:Number = 15;
		private const CAPTION_HEIGHT:Number = 30;
		private const CAPTION_LINK_COLOR:String = "#0080FF";
		private const CAPTION_PADDING:Number = 10;
		private const TIMER_PROGRESS_TINT:uint = 0x9CCE31;
		
		/* Member fields */
		private var bg:Sprite; //The background sprite use for the content.
		private var captionSprite:Sprite; //sprite used to display captions
		private var captionTLF:TLFTextField;
		private var captionTextFormat:TextLayoutFormat;
		private var contentParent:Sprite; //content is added as child to this display object
		private var contentArray:Array; //holds the content objects.
		private var contentThumbnails:Array; //stores the content thumbnails (media navigation)
		private var currentContentIndex:int; //the index of the current object that is being shown.
		private var currentVideo:Object; //a reference to the currently playing youtube video.
		private var contentTween:Tween; //tween used to switch between content.
		private var autoScrollTimer:Timer; //timer used to keep track of autoscroll progress
		private var autoScrollSeconds:Number; //number of seconds before the next content item is loaded, set in the config.xml
		private var timerTween:Tween; //tweens the timer progress bar.
		private var thumbScrollPane:ScrollPane; //used to horizontally scroll the thumbnails
		
		public function HomeView() 
		{
			//allow content to be loaded from youtube.com
			Security.allowDomain("http://www.youtube.com");
			Security.allowDomain("http://img.youtube.com");
			Security.allowDomain("http://s.ytimg.com");
			Security.allowDomain("http://i.ytimg.com");
			
			//create the content container
			this.bg = new Sprite();
			this.bg.graphics.beginFill(0x333333, 1);
			this.bg.graphics.lineStyle(1, 0xFFFFFF, 1); 
			this.bg.graphics.drawRect(0, 0, CONTENT_WIDTH, CONTENT_HEIGHT);
			this.bg.graphics.endFill();
			this.bg.filters = new Array(new GlowFilter(0x666666, 1, 6, 6, 1, 1, false, false));
			this.bg.blendMode = BlendMode.MULTIPLY;
			this.addChild(this.bg);
			
			//create content mask
			var contentMask:Sprite = new Sprite();
			contentMask.graphics.beginFill(0x000000, 1);
			contentMask.graphics.drawRect(1, 1, CONTENT_WIDTH-2, CONTENT_HEIGHT-1); //add padding around mask
			contentMask.graphics.endFill();
			this.addChild(contentMask);
			
			//create content parent and set the mask
			this.contentParent = new Sprite();
			this.contentParent.mask = contentMask;
			this.addChild(this.contentParent);
			
			//create caption tlf
			this.captionTLF = new TLFTextField();
			this.captionTLF.height = this.CAPTION_HEIGHT;
			this.captionTLF.width = this.CONTENT_WIDTH;
			this.captionTLF.addEventListener(TextEvent.LINK, this.onCaptionLinkClick);
			with(this.captionTLF)
			{
				embedFonts = true;
				multiline = false;
				selectable = false;
			}
			
			this.captionTextFormat = new TextLayoutFormat();
			with(this.captionTextFormat)
			{
				color = 0xFFFFFF;
	 			fontFamily = new TahomaRegular().fontName;
				fontSize = 12;
			}
			
			//create content caption tlf and background
			this.captionSprite = new Sprite();
			captionSprite.graphics.beginFill(0x333333, .3);
			captionSprite.graphics.drawRect(1,1, this.CONTENT_WIDTH-1, captionTLF.height);
			captionSprite.graphics.moveTo(1,1);
			captionSprite.graphics.lineStyle(1, 0x666666);
			captionSprite.graphics.lineTo(this.CONTENT_WIDTH-1, 1);
			captionSprite.graphics.endFill();
			captionSprite.y = this.CONTENT_HEIGHT - this.captionSprite.height;
			captionSprite.visible = false;
			captionSprite.addChild(this.captionTLF);
			this.addChild(captionSprite);
			
			this.currentContentIndex = -1;
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/* 
		width
		Override width properties to not reflect the content behind the mask.
		*/
		public override function get width():Number {
			return this.CONTENT_WIDTH;
		}
		
		/*
		height
		Override height property because of odd behavior with the youtube player height.
		*/
		public override function get height():Number {
			return this.CONTENT_HEIGHT + this.CONTROLS_PADDING + this.THUMBNAIL_HEIGHT;
		}
		
		/*
		onAdded
		Added to stage event handler.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//parse the xml content in the config.xml
			this.parseContent();
			
			//layout the content loaders horizontally
			this.layoutContent();
			
			//create thumbnails for each content item and setup the thumbnails
			//to allow content navigation.
			this.createContentControls();
			
			//display and load the first element
			this.loadAndDisplayAt(0);
			
			//start auto-scroll timer
			this.startAutoScroll();
			
			//start tweening the first thumbnail autoscroll timer progress bar
			var timerSprite:Sprite = this.contentThumbnails[0].timerSprite;
			if(timerSprite != null)
				this.timerTween = new Tween(timerSprite, "scaleX", Regular.easeInOut, 0, 1, this.autoScrollSeconds, true);

			//add padding and show view
			this.xPadding = this.LEFT_PADDING;
			this.yPadding = this.TOP_PADDING;
			this.setupView();
			this.showView();
		}
		
		
		/*
		hideView
		Stops the timer and the running video.
		*/
		public override function hideView(evt:Event = null):void
		{
			super.hideView(evt);
			this.stopAutoScroll();
			if(this.currentVideo != null)
				this.currentVideo.pauseVideo();
		}
		
		/*
		destroyPlayers
		Calls the stopVideo method on all the youtube players.
		*/
		public function destroyPlayers():void 
		{
			for(var i:uint = 0; i < this.contentArray.length; i++)
			{
				var obj:Object = this.contentArray[i];
				if(obj.type == "youtube" && obj.loader.content != null)
					obj.loader.content.stopVideo();
			}
		}
		
		/*
		parseContent
		Takes each child xml-node of the HomeContentView XMLList in the config.xml
		and creates an content object depending on the node type.
		*/
		private function parseContent():void 
		{
			this.contentArray = new Array();
			var contentXML:XMLList = this.main.config.HomeViewContent.content;
			
			for(var i:uint = 0; i < contentXML.length(); i++)
			{
				var item:XML = contentXML[i];
				
				if(item.localName() != "content")
				{
					this.main.log("Unsupported xml node " + item.localName())
					continue;
				}
				
				var type:String = item.@type;
				var thumbURL:String = item.@thumbnail;
				var url:String = item.url;
				var caption:String = item.caption;

				switch(type)
				{
					case "youtube":
						
						//parse the video id out of the url
						var videoID:String = parseYouTubeID(url);
						url = Strings.substitute(this.YOUTUBE_EMBEDDED_URL, videoID);
						
						//set the thumb url
						thumbURL = (thumbURL == "" ? Strings.substitute(this.YOUTUBE_IMAGE_URL, videoID) : thumbURL);
						
						this.contentArray.push( {"type": type,
											   "loader" : new Loader(), 
											   "contentURL": url, 
											   "caption" : caption,
											   "thumbURL": thumbURL} );
						break;
					case "image":
					case "swf":
						thumbURL = (thumbURL == "" ? item.url : thumbURL);
						this.contentArray.push( {"type": type, 
											   "loader" : new Loader(), 
											   "contentURL" : url, 
											   "caption" : caption,
											   "thumbURL": thumbURL} );
						break;
					default:
						this.main.log("HomeViewContent - unsupported attribute type " + type);
						break;
				}
			}
		}
		
		/*
		parseYouTubeID
		Parses the video id out of a youtube url and returns the id.
		*/
		private function parseYouTubeID(url:String):String
		{
			var idRegEx:RegExp = /[A-Za-z0-9_-]{11}/ig;
			var result:Object = url.match(idRegEx);
			if(result.length != 1 || result == null)
			{
				main.log("Unable to parse youtube video id. " + url + " might be malformed.");
				return "";
			}
			
			return result[0];
		}
				
		/*
		loadAndDisplayAt
		Loads and displays the the content at the given index % contentArray.length.
		index:uint - An index in contentArray to display.
		*/
		private function loadAndDisplayAt(index:uint):void
		{
			index %= contentArray.length;
			var contentItem:Object = this.contentArray[index];
			
			//check if the content is loaded
			if(contentItem.loader.content == null)
			{
				//trace("Loading " + index);
				this.contentThumbnails[index].spinner.visible = true;
				contentItem.loader.addEventListener(IOErrorEvent.IO_ERROR, this.onContentLoadError);
				contentItem.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, getLoadCompleteHandler(index));
				contentItem.loader.load(new URLRequest(contentItem.contentURL));
				
				//add different listeners for youtube video
				if(contentItem.type == "youtube")
					contentItem.loader.contentLoaderInfo.addEventListener(Event.INIT, onYouTubeInit);
			}
			else
			{
				//trace("Displaying " + index);
				this.contentThumbnails[index].spinner.visible = false;
				this.contentThumbnails[index].rollOverSprite.visible = true;
				this.contentThumbnails[index].buttonMode = false;
				
				//re-enable previous selection
				if(this.currentContentIndex != -1)
				{
					this.contentThumbnails[this.currentContentIndex].buttonMode = true;
					this.contentThumbnails[this.currentContentIndex].rollOverSprite.visible = false;
				}
				
				//set new current content index
				this.currentContentIndex = index;
				
				//move the contentParent x to the corrent position.
				var newX:Number = (index * CONTENT_WIDTH * -1);
				this.contentTween = new Tween(this.contentParent, "x", Strong.easeOut, this.contentParent.x, newX, 1, true);
				
				//show caption if applicable
				with(this.captionTLF)
				{
					htmlText = this.contentArray[index].caption;
					paddingLeft = paddingRight = paddingTop = this.CAPTION_PADDING;
					textFlow.hostFormat = this.captionTextFormat;
					textFlow.linkNormalFormat = {color:this.CAPTION_LINK_COLOR, textDecoration:"underline"};
					textFlow.linkHoverFormat = {color:0xFFFFFF, textDecoration:"underline"};
					textFlow.flowComposer.updateAllControllers();
				}
				
				this.captionSprite.visible = this.contentArray[index].caption.length > 0;
			}
		}
		
		/*
		startAutoScroll
		Instantiates the auto scroll timer and starts the timer.
		*/
		public function startAutoScroll():void 
		{
			this.autoScrollSeconds = Number(main.config.HomeViewContent.@autoScrollSeconds);
			this.autoScrollTimer = new Timer((this.autoScrollSeconds+.5) * 1000); //add time to offset tick from progress bar tween
			this.autoScrollTimer.addEventListener(TimerEvent.TIMER, onScrollTimerTick);
			this.autoScrollTimer.start();
		}
		
		/*
		stopAutoScroll
		Stops the auto scroll timer.
		*/
		public function stopAutoScroll():void 
		{
			if(this.currentContentIndex != -1)
			{
				this.timerTween.stop();
				this.contentThumbnails[this.currentContentIndex].timerSprite.scaleX = 0;
			}
				
			if(this.autoScrollTimer != null)
				this.autoScrollTimer.stop();
		}
		
		/*
		onScrollTimerTick
		Update the timer progress bar and move to the next content item.
		*/
		private function onScrollTimerTick(evt:TimerEvent):void
		{
			//disable current progress bar
			this.contentThumbnails[this.currentContentIndex].timerSprite.scaleX = 0;
			
			//load next content item
			var index:uint = (this.currentContentIndex+1) % this.contentArray.length;
			this.loadAndDisplayAt(index);
			
			//move the scroll pane to the current thumbnail.
			//not the best way to calculate this, but the scrollpane handles it well.
			this.thumbScrollPane.horizontalScrollPosition = this.contentThumbnails[index].x;
			
			//show progress
			var timerSprite:Sprite = this.contentThumbnails[index].timerSprite;
			this.timerTween = new Tween(timerSprite, "scaleX", Regular.easeInOut, 0, 1, this.autoScrollSeconds, true);
		}
		
		/*
		onYouTubeInit
		Listen for player on ready event.
		*/
		private function onYouTubeInit(evt:Event):void 
		{
			evt.target.loader.content.addEventListener("onReady", onYouTubeReady);
			evt.target.loader.content.addEventListener("onError", onYouTubeError);
			evt.target.loader.content.addEventListener("onStateChange", onVideoStateChange);
			evt.target.loader.content.addEventListener(MouseEvent.CLICK, onContentClick);
		}
		
		/*
		onVideoStateChange
		Pauses the currently playing video, if there is one.
		*/
		private function onVideoStateChange(evt:Event):void 
		{
			var player:Object = evt.currentTarget;
			var playerState:Number = Object(evt).data;
			
			if(playerState == 1) //playing
			{
				if(this.currentVideo != null)
					this.currentVideo.pauseVideo();
				
				this.currentVideo = player;
			}
			else if(playerState == 2) //paused
				this.currentVideo = null;
		}
		
		/*
		onContentClick
		Stop the scrolling timer and remove this listener.
		*/
		private function onContentClick(evt:MouseEvent):void 
		{
			evt.currentTarget.removeEventListener(MouseEvent.CLICK, onContentClick);
			this.stopAutoScroll();
		}
		
		/*
		onYouTubeReady
		Set the size for the youtube player.
		*/
		private function onYouTubeReady(evt:Event):void {
			evt.target.setSize(CONTENT_WIDTH, CONTENT_HEIGHT);
		}
		
		/*
		onYouTubeError
		Event handler for player error.
		*/
		private function onYouTubeError(evt:Event):void {
			main.log("Error loading youtube video: " + Object(evt).data);
		}
		
		
		/*
		getLoadCompleteHandler
		Returns an anonymous function that handles a Loader loadComplete event. The
		function displays the content at the given thumbIndex which is stored in a closure.
		*/
		private function getLoadCompleteHandler(thumbIndex:uint):Function
		{
			//thumbIndex remains in the scope of the anonymous function that is returned
			//because a closure is created. 
			return function(evt:Event):void {
				loadAndDisplayAt(thumbIndex);
			}
		}
		
		
		/*
		layoutContent
		Position the each content loader horizontally in the contentParent container.
		The content can be scrolled with the thumbnail controls.
		*/
		private function layoutContent():void
		{
			var contentItem:Object;
			for(var i:uint = 0; i < this.contentArray.length; i++)
			{
				contentItem = this.contentArray[i];
				contentItem.loader.x = (i * CONTENT_WIDTH);
				this.contentParent.addChild(contentItem.loader);
			}
		}
		
		/*
		createContentControls
		Creates thumbnails for each content item and listens for mouse events on each
		thumbnail to allow navigation of the content when a user clicks on a thumbnail.
		
		We can rely on http caching to handle the duplicate resources loaded if the content url
		and the thumbnail url are the same. There is no need to try to deep copy the content display
		objects loaded by the Loader objects.
		*/
		private function createContentControls():void 
		{
			if(this.contentArray == null) 
			{
				trace("Can't create content controls, the content array is null");
				return;
			}
			
			var controls:MovieClip = new MovieClip(); //parent mc that holds all the thumbnails
			this.contentThumbnails = new Array();
			
			for(var i:uint = 0; i < this.contentArray.length; i++)
			{
				var item:Object = this.contentArray[i];
				
				//each content item gets a thumbnail mc
				var thumbnail:MovieClip = new MovieClip();
				thumbnail.index = i; //tag on the index to each thumbnail
				thumbnail.graphics.beginFill(0x000000, 1);
				//thumbnail.graphics.lineStyle(1, 0x999999);
				thumbnail.graphics.drawRect(0, 0, this.THUMBNAIL_WIDTH, this.THUMBNAIL_HEIGHT);
				thumbnail.graphics.endFill();
				thumbnail.filters = [new DropShadowFilter(2, 45, 0, 1, 4, 4, 1, 15)];
				thumbnail.x = (i * this.THUMBNAIL_WIDTH) + (i * this.THUMBNAIL_PADDING);
				
				//create a UILoader and load the item thumbnail
				var uiLoader:UILoader = new UILoader();
				uiLoader.scaleContent = uiLoader.maintainAspectRatio = true;
				uiLoader.width = this.THUMBNAIL_WIDTH;
				uiLoader.height = this.THUMBNAIL_HEIGHT;
				uiLoader.addEventListener(IOErrorEvent.IO_ERROR, onContentLoadError);
				uiLoader.load(new URLRequest(item.thumbURL));
				
				//create a roll-over sprite
				var rollover:Sprite = new Sprite();
				rollover.graphics.beginFill(0xFFFFFF, 0);
				rollover.graphics.lineStyle(1.5, 0xFFFFFF);
				rollover.graphics.drawRect(0, 0, this.THUMBNAIL_WIDTH, this.THUMBNAIL_HEIGHT);
				rollover.graphics.endFill();
				rollover.visible = false;
				thumbnail.rollOverSprite = rollover;
				
				//add spinner
				var spinner:SpinnerLight = new SpinnerLight();
				spinner.x = (this.THUMBNAIL_WIDTH - spinner.width) / 2;
				spinner.y = (this.THUMBNAIL_HEIGHT - spinner.height) / 2;
				spinner.graphics.beginFill(0x000000, .9);
				var radius:Number = spinner.width / 2;
				spinner.graphics.drawCircle(radius, radius, radius + 2);
				spinner.graphics.endFill();
				spinner.visible = false;
				thumbnail.spinner = spinner;
				
				//add timer progress sprite
				var timerSprite:Sprite = new Sprite();
				timerSprite.graphics.lineStyle(1, TIMER_PROGRESS_TINT, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER, 3);
				timerSprite.graphics.moveTo(2, this.THUMBNAIL_HEIGHT - 3);
				timerSprite.graphics.lineTo(this.THUMBNAIL_WIDTH - 2, this.THUMBNAIL_HEIGHT - 3);
				timerSprite.graphics.endFill();
				timerSprite.scaleX = 0;
				thumbnail.timerSprite = timerSprite;
				
				thumbnail.addChild(uiLoader);
				thumbnail.addChild(timerSprite);
				thumbnail.addChild(rollover);
				thumbnail.addChild(spinner);
				
				//setup mouse events on the thumbnails
				thumbnail.buttonMode = true;
				thumbnail.addEventListener(MouseEvent.CLICK, onThumbClick);
				thumbnail.addEventListener(MouseEvent.CLICK, onContentClick);
				thumbnail.addEventListener(MouseEvent.ROLL_OVER, onThumbRollOver);
				thumbnail.addEventListener(MouseEvent.ROLL_OUT, onThumbRollOut);
				
				//add thumbnail to parent container
				controls.addChild(thumbnail);
				this.contentThumbnails[i] = thumbnail;
			}
			
			//add the controls to a scroll pane
			this.thumbScrollPane = new ScrollPane();
			this.thumbScrollPane.width = this.CONTENT_WIDTH;
			this.thumbScrollPane.height = this.THUMBNAIL_HEIGHT + (this.THUMBNAIL_PADDING * 1.5);
			this.thumbScrollPane.y = this.CONTENT_HEIGHT + this.CONTROLS_PADDING;
			this.thumbScrollPane.source = controls;
			this.thumbScrollPane.scrollDrag = false;
			
			//style the scroll pane and add it to the stage
			this.setPaneStyle(this.thumbScrollPane);
			this.addChild(this.thumbScrollPane);
		}
		
		/*
		onThumbClick
		displays the content from the clicked thumbnail.
		*/
		private function onThumbClick(evt:MouseEvent):void
		{
			if(this.currentContentIndex != evt.currentTarget.index)
				this.loadAndDisplayAt(evt.currentTarget.index);
		}
		
		/*
		onThumbRollOver
		Display the thumbnail rollover sprite.
		*/
		private function onThumbRollOver(evt:MouseEvent):void {
			evt.currentTarget.rollOverSprite.visible = true;
		}
		
		/*
		onThumbRollOut
		Hide the rollover sprite.
		*/
		private function onThumbRollOut(evt:MouseEvent):void 
		{
			if(this.currentContentIndex != evt.currentTarget.index)
				evt.currentTarget.rollOverSprite.visible = false;
		}
		
		/*
		onCaptionLinkClick
		Event handler for caption link click. Parses the launchApp link
		and calls the internal function with the passed in app id.
		*/
		private function onCaptionLinkClick(evt:TextEvent):void
		{
			var link:String = evt.text;
			
			//match the launchApp(id, appName) function call
			var fRegex:RegExp = /^launchApp\(\d+,(.)+\)$/;
			var paramRegex:RegExp = /\d+,(.)+/ig;
			
			if(link.search(fRegex) != -1)
			{
				var params:Array = link.match(paramRegex).toString().split(",");
				var appid:String = Strings.trim(params[0]);;
				var appname:String = Strings.trim((params[1] as String).substr(0, params[1].length-1));
				this.main.appManager.verifyAppLaunch(new Application(appid, appname));
			}
		}
		
		/*
		onContentLoadError
		Error event handler for loading content.
		*/
		private function onContentLoadError(evt:IOErrorEvent):void {
			main.log(evt.toString());
		}
		
		/*
		setPaneStyle
		Styles the scroll pane that is used to scroll the thumbnails.
		*/
		private function setPaneStyle(pane:ScrollPane):void
		{
			with(pane)
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
		
	} //class
} //package