/*
FooterView.as
Manages and adds behavior to the headline, sub headline, social links, logout button
and the cafes logo.
*/
package com.slskin.ignitenetwork.views.desktop 
{
	import flash.events.Event;
	import flash.geom.Point;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import com.slskin.ignitenetwork.Language;
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.apps.MainCategory;
	import com.slskin.ignitenetwork.components.IconLink;
	import com.slskin.ignitenetwork.util.Strings;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	import flash.net.URLRequest;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	public class FooterView extends SLView 
	{
		/* Constants */
		private const LEFT_PADDING:Number = -142;
		private const TOP_PADDING:Number = 268;
		private const LOGO_SIZE:Number = 75; //75 x 75
		private const ICON_PADDING:Number = 8; //padding between social icons
		private const RIBBON_PADDING:Number = 10; //padding at the end of the ribbon
		private const LOGOUT_TEXT_COLOR:uint = 0x333333;
		private const USERNAME_COLOR:uint = 0x0080FF;
		private const DEFAULT_COLOR:uint = 0xCCCCCC;
		private const LOGOUT_ROLLOVER_COLOR:uint = 0x990000;
		
		/* Member fields */
		private var socialIcons:MovieClip; //stores IconLinks for each social network link
		private var usernameFormat:TextFormat = new TextFormat("Tahoma", 13, USERNAME_COLOR);
		private var defaultFormat:TextFormat = new TextFormat("Tahoma", 12, DEFAULT_COLOR);
		
		public function FooterView() {
			this.socialIcons = new MovieClip();
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded 
		Listens for added to stage event.
		*/
		private function onAdded(evt:Event):void
		{
			//remove event listener
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//start at the bottom of the stage
			this.startPos = new Point(centerX, main.getStageHeight() + this.height);
			
			//update window padding to make room for
			//other home screen content.
			this.xPadding = this.LEFT_PADDING;
			this.yPadding = this.TOP_PADDING;
			
			//update the start position point with
			//the new padding values
			this.startPos.x += this.xPadding; 
			this.startPos.y += this.yPadding;
			this.moveToStart();
			
			//load the logo
			with(this.logoLoader)
			{
				width = this.LOGO_SIZE;
				height = this.LOGO_SIZE;
				load(new URLRequest(main.config.Images.footerLogo));
			}
			
			//set Headline
			this.setHeadline(main.model.getProperty("Headline1", main.model.TEXT_PATH));
			
			//set sub headline
			this.subHeadlineTLF.text = main.model.getProperty("Headline2", main.model.TEXT_PATH);
			
			//set logout button text
			this.logoutTLF.text = Language.translate("Logout", "Logout"); 
			
			//set current user
			var username:String = main.model.getProperty("Username", main.model.DATA_PATH);
			this.usernameTLF.text =  Language.translate("Current_User", "Current user") + " " + username;
			this.usernameTLF.setTextFormat(this.defaultFormat, 0, (this.usernameTLF.text.length - username.length));
			this.usernameTLF.setTextFormat(this.usernameFormat, (this.usernameTLF.text.length - username.length), this.usernameTLF.length);
			
			//listen for logout button events
			this.logoutButton.tabEnabled = false;
			this.logoutButton.addEventListener(MouseEvent.CLICK, onLogoutClick);
			this.logoutButton.addEventListener(MouseEvent.ROLL_OVER, onLogoutRollOver);
			this.logoutButton.addEventListener(MouseEvent.ROLL_OUT, onLogoutRollOut);
			
			//add social links
			this.addSocialIcons();
			
			//show view
			this.showView();
		}
		
		/*
		setHeadine
		Sets the headline property in the headTLF and resizes / moves the UI
		depending the headline textWidth.
		*/
		private function setHeadline(str:String):void
		{
			this.headLineTLF.text = str;
			var textWidth:Number = this.headLineTLF.textWidth + ICON_PADDING;
			this.headLineTLF.width = textWidth;
			this.ribbon.bar.width = textWidth + RIBBON_PADDING;
			this.ribbon.lines.width = this.ribbon.bar.width;
		}
		
		/*
		addSocialIcons
		Displays social links that are set in the config.xml file.
		*/
		private function addSocialIcons():void
		{
			//set the x and y
			this.socialIcons = new MovieClip();
			socialIcons.x = this.ribbon.bar.width + ICON_PADDING + LOGO_SIZE;
			socialIcons.y = this.ribbon.y;
			
			var link:IconLink;
			var numLinks:uint = main.config.Social.link.length();
			for(var i:uint = 0; i < numLinks ; i++)
			{
				//create link object from xml values
				link = new IconLink(main.config.Social.link[i].@alias, main.config.Social.link[i], 
									main.config.Social.link[i].@iconPath);
				
				//set x and y
				link.x = (i * link.width) + (i * this.ICON_PADDING);
				
				//add to mc holder
				this.socialIcons.addChild(link);
			}
			
			//add the social icons mc to stage
			this.addChild(this.socialIcons);
		}
		
		/*
		onLogoutClick
		Call the logout routine in the sl client, listen for progress,
		and show a LoadingView.
		*/
		private function onLogoutClick(evt:Event):void 
		{
			if(ExternalInterface.available)
			{
				ExternalInterface.call("UserLogout", "");
				this.main.model.addEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
				this.main.model.addEventListener(SLEvent.LOGGING_OUT, this.onUserLoggingOut);
			}
		}
		
		/*
		onUserLoggingOut
		Show the loader
		*/
		private function onUserLoggingOut(evt:SLEvent):void {
			LoadingView.getInstance().showLoader();
			LoadingView.getInstance().loadingText = Language.translate("Logging_Out", "Logging Out");
			this.main.model.removeEventListener(SLEvent.LOGGING_OUT, this.onUserLoggingOut);
		}
		
		/*
		onValueAdded
		Listens for value added events from the model and responds to the
		key value pairs that pertain to the logout process.
		*/
		private function onValueAdded(evt:SLEvent):void
		{
			var split:Array = String(evt.argument).split(main.model.DIM);
			var key:String = split[0];
			var val:String = split[1];
			switch (key)
			{
				case main.model.DATA_PATH + "LoadingStatus":
					if(val == "Done")
					{
						LoadingView.getInstance().hideLoader();
						main.model.removeEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
					}
					else if(val == "Failed")
					{
						LoadingView.getInstance().hideLoader();
						ErrorView.getInstance().showError(main.config.Strings.ErrorString);
						main.model.removeEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
					}
					break;
				case main.model.TEXT_PATH + "LoadingText":
				case main.model.DATA_PATH + "LoadingText":
					LoadingView.getInstance().loadingText = val;
					break;
			}
		}
		
		/*
		onLogoutRollOver
		Change the button background.
		*/
		private function onLogoutRollOver(evt:MouseEvent):void {
			this.logoutTLF.textColor = this.LOGOUT_ROLLOVER_COLOR;
			this.logoutBackground.gotoAndStop("Over");
		}
		
		/*
		onLogoutRollOut
		Change the background back to up.
		*/
		private function onLogoutRollOut(evt:MouseEvent):void {
			this.logoutTLF.textColor = this.LOGOUT_TEXT_COLOR;
			this.logoutBackground.gotoAndStop("Up");
		}
		
	} //class
} //package
