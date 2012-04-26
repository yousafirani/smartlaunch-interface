/*
Dock Icon represents a main category in SL. Each category
has a label and an icon.
*/

package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.IOErrorEvent;
	import fl.containers.UILoader;
	import flash.net.URLRequest;
	import com.slskin.ignitenetwork.Main;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
 	import fl.transitions.easing.*;
	import fl.transitions.*;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.display.BlendMode;
 	import com.slskin.ignitenetwork.apps.MainCategory;
 	import com.slskin.ignitenetwork.views.ListView;
	import flash.text.Font;
	import flash.text.TextFieldAutoSize;
	import flash.text.AntiAliasType;
	import flash.display.Sprite;
	import fl.text.TLFTextField;
	import flash.text.TextFormat;
	import flashx.textLayout.formats.VerticalAlign;
	import com.slskin.ignitenetwork.fonts.*;
	import com.slskin.ignitenetwork.loaders.Roller;
	
	public class DockIcon extends MovieClip 
	{
		/* Constants */
		public const ICON_SIZE:Number = 48;
		private const CAPTION_HEIGHT:Number = 20; //height of the icon hover caption
		private const CAPTION_MIN_WIDTH:Number = 75; //min width of icon hover caption
		private const PILL_PADDING:Number = 4; //left and right padding on the caption pill
		private const ICON_PATH:String = "./assets/dock/";
		
		/* Member fields */
		private var _category:MainCategory; //Category object that this icon represents
		private var _dropDownVisible:Boolean;
		private var _isSelected:Boolean;
		private var captionPill:Sprite; //background for caption on rollOver
		private var captionTLF:TLFTextField;
		private var captionContainer:MovieClip;
		private var dropDownContainer:MovieClip;
		private var iconLoader:UILoader;
		private var loaderMC:Roller;
		
		public function DockIcon(category:MainCategory) 
		{
			this._category = category;
			this.captionContainer = new MovieClip();
			this.captionContainer.y = this.ICON_SIZE;
			//create roller loader
			this.loaderMC = new Roller();
			
			//listen for added to stage event
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/* Getters */
		public function get category():MainCategory {
			return this._category;
		}
		
		public function get dropDownVisible():Boolean {
			return this._dropDownVisible;
		}
		
		public function get isSelected():Boolean {
			return this._isSelected;
		}
		
		/* Setters */
		public function set isSelected(select:Boolean) 
		{
			this._isSelected = select;
			
			if(select)
			{
				var glow:GlowFilter = new GlowFilter(0x666666, 1, 6, 6, 1, 1, false, false);
				this.iconLoader.filters = new Array(glow);
				this.iconButton.enabled = false;
				this.iconButton.useHandCursor = false;
				this.bubble.visible = true;
			} 
			else
			{
				this.iconLoader.filters = null;
				this.iconButton.enabled = true;
				this.iconButton.useHandCursor = true;
				this.bubble.visible = false;
			}
			
		}
		
		/*
		onAdded
		Event listener for added to stage
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//reference icon loader on stage
			this.iconLoader = this._iconLoader;
			
			this.isSelected = false;
			
			//hide corner
			this.corner.visible = false;
			this.loaderMC.visible = false;
			this.captionContainer.addChild(this.loaderMC);
			
			//hide the caption container and add it under the corner
			this.captionContainer.visible = false;
			this.addChildAt(this.captionContainer, this.getChildIndex(this.corner)-1);
			
			//setup loader
			with(this.iconLoader)
			{
				maintainAspectRatio = true;
				scaleContent = true;
				height = ICON_SIZE;
				height = ICON_SIZE;
				addEventListener(IOErrorEvent.IO_ERROR, onIconLoadError);
			}
			
			//load icon
			this.loadIcon(this.ICON_PATH + _category.name.toLowerCase().replace(" ", "_") + ".png");
			
			//create a tlf to hold the category local name
			this.createCaptionTLF();
			
			//set the caption
			this.setCaption(this.category.localeName);
			
			//move loader to the end of the caption
			this.loaderMC.x = this.captionPill.width - this.loaderMC.width;
			this.loaderMC.y = (this.captionPill.height - this.loaderMC.height) / 2;
			
			
			//listen for rollOver and rollOut events
			this.iconButton.addEventListener(MouseEvent.ROLL_OVER, onIconRollOver);
			this.iconButton.addEventListener(MouseEvent.ROLL_OUT, onIconRollOut);
		}
		
		
		/*
		loadIcon
		Loads the passed in icon
		*/
		public function loadIcon(path:String):void {
			this.iconLoader.load(new URLRequest(path));
		}
		
		/*
		createCaptionTLF
		Creates a TLF text field to display the category name.
		*/
		private function createCaptionTLF():void 
		{
			this.captionTLF = new TLFTextField();
			this.captionTLF.defaultTextFormat = new TextFormat(new MyriadSemiBold().fontName, "14", 0xFFFFFF, true);
			
			with(this.captionTLF)
			{
				embedFonts = true;
				multiline = false;
				autoSize = TextFieldAutoSize.LEFT;
				antiAliasType = AntiAliasType.ADVANCED;
				selectable = false;
			}
			
			this.captionContainer.addChild(this.captionTLF);
		}
		
		/*
		setCaption
		Sets the caption and resizes the caption
		pill accordingly.
		@param {String} - String to set the caption to.
		*/
		private function setCaption(str:String):void
		{
			if(this.captionTLF == null) return;
			
			//set text. The TLF is set to autosize based on
			//the text so the captionTLF will resize.
			this.captionTLF.text = str;
			
			//setup pill width
			var pillWidth:Number = this.captionTLF.width + this.PILL_PADDING;
			if(pillWidth < this.CAPTION_MIN_WIDTH)
				pillWidth = this.CAPTION_MIN_WIDTH;
			
			//setup pill height
			var pillHeight:Number = this.CAPTION_HEIGHT + this.PILL_PADDING;
			
			//draw pill
			this.drawPill(pillWidth, pillHeight);
			
			//center tlf x relative to the icon
			this.captionTLF.x = (this.ICON_SIZE - this.captionTLF.width) / 2;
			
			//center tlf y relative to the pill height
			this.captionTLF.y = (pillHeight - this.captionTLF.height) / 2;
		}
		
		/*
		drawPill
		Creates the pill object that is the background for the caption.
		*/
		private function drawPill(pillWidth:Number, pillHeight:Number):void
		{
			//remove it if it exists
			if(this.captionPill != null && this.captionPill.stage != null)
				this.removeChild(this.captionPill);
			
			var pill:Sprite = new Sprite();
			pill.graphics.beginFill(0x000000, .75);
			pill.graphics.lineStyle(1, 0x999999, 1, true, "normal"); 
			pill.graphics.drawRoundRect(0, 0, pillWidth, pillHeight, 4);
			pill.graphics.endFill();
	
			//add glow
			var glow:GlowFilter = new GlowFilter(0x000000, 1, 6, 6, 1, 1, false, false);
			pill.filters = new Array(glow);
			
			//center the pill
			pill.x = (this.ICON_SIZE - pillWidth) / 2;
						
			//store a reference to pill
			this.captionPill = pill;
			
			//add at 0
			this.captionContainer.addChildAt(pill, 0);
		}
		
		/*
		showLoader
		Shows the progress loader
		*/
		public function showLoader():void 
		{
			if(!this.loaderMC.visible)
			{
				this.captionPill.width += this.loaderMC.width + this.PILL_PADDING;
				this.loaderMC.visible = true;
			}
		}
		
		/*
		hideLoader
		Hides the progress loader
		*/
		public function hideLoader():void 
		{
			if(this.loaderMC.visible)
			{
				this.captionPill.width -= this.loaderMC.width + this.PILL_PADDING;
				this.loaderMC.visible = false;
			}
		}
		
		/*
		displayDropDown
		Displays an application list as a drop down menu to the dock icon.
		*/
		public function displayDropDown(list:ListView):void
		{
			if(this.dropDownContainer != null && this.dropDownContainer.stage != null)
				this.removeChild(this.dropDownContainer);
				
			this.captionContainer.visible = false;
			
			this.dropDownContainer = new MovieClip();
			this.dropDownContainer.y = this.ICON_SIZE;
			
			//draw background sprite
			var listPadding:Number = 2;
			var dropDownBack:Sprite = new Sprite();
			dropDownBack.graphics.beginFill(0x000000, .75);
			dropDownBack.graphics.lineStyle(1, 0x999999, 1, true, "normal"); 
			dropDownBack.graphics.drawRoundRect(0, 0, list.listWidth + listPadding, list.listHeight + listPadding, 8);
			dropDownBack.graphics.endFill();
			list.x = list.y = (listPadding / 2);
			dropDownBack.addChild(list);
	
			//add glow
			var glow:GlowFilter = new GlowFilter(0x000000, 1, 6, 6, 1, 1, false, false);
			dropDownBack.filters = new Array(glow);
			
			//add children
			this.dropDownContainer.addChild(dropDownBack);
			this.dropDownContainer.visible = false;
			this.addChildAt(this.dropDownContainer, this.getChildIndex(this.corner)-1);
			
			//fade in drop down list and corner
			TransitionManager.start(this.dropDownContainer, {type:Fade, direction:Transition.IN, duration:1, easing:Strong.easeInOut});
			TransitionManager.start(this.corner, {type:Fade, direction:Transition.IN, duration:1, easing:Strong.easeInOut});
			
			//disable rollover and rollout listeners
			this.iconButton.removeEventListener(MouseEvent.ROLL_OVER, onIconRollOver);
			this.iconButton.removeEventListener(MouseEvent.ROLL_OUT, onIconRollOut);
			
			this._dropDownVisible = true;
			
			//listen for outside click to hide the drop down.
			stage.addEventListener(MouseEvent.CLICK, onMasterClick);
			
		}
		
		/*
		hideDropDown
		Hides the drop down menu and re-enables appropriate mouse event listeners.
		*/
		public function hideDropDown():void
		{
			if(!this._dropDownVisible) return;
			
			if(this.dropDownContainer != null && this.dropDownContainer.stage != null)
				this.removeChild(this.dropDownContainer);
			
			this.corner.visible = false;
			this.iconButton.addEventListener(MouseEvent.ROLL_OVER, onIconRollOver);
			this.iconButton.addEventListener(MouseEvent.ROLL_OUT, onIconRollOut);
			
			this._dropDownVisible = false;
		}
		
		/*
		onMasterClick
		Mouse click event handler when a dock icon has a drop down menu. Hides
		the drop down menu and removes the listener if the click is outside this
		object and the drop down is visible.
		*/
		private function onMasterClick(evt:MouseEvent):void
		{
			if(this._dropDownVisible)
			{
				this.hideDropDown();
				stage.removeEventListener(MouseEvent.CLICK, onMasterClick);
			}
		}
		
		/*
		onIconRollOver
		Fade in the caption pill
		*/
		private function onIconRollOver(evt:Event):void 
		{
			if(this.isSelected) return;
			
			this.corner.visible = true;
			this.captionContainer.visible = true;
		}
		
		/*
		onIconRollOut
		Fade out the caption pill
		*/
		private function onIconRollOut(evt:Event):void  
		{
			this.corner.visible = false;
			this.captionContainer.visible = false;
		}
		
		/*
		onIconLoadError
		If the icon file is not found or there is
		an IOError.
		*/
		private function onIconLoadError(evt:IOErrorEvent):void
		{
			var main:Main = (root as Main); //reference main doc class
			main.debugger.write(evt.toString());
			main.log(evt.text);
			//show default icon
			this.defaultIcon.alpha = 1;
		}
		
	} //class
} //package
