/**
 * FooterView.as
 * Manages and adds behavior to the headline, sub headline, social links, logout button
 * and the cafes logo.
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
	import com.slskin.ignitenetwork.apps.Application;
	import com.slskin.ignitenetwork.components.ListItem;
	import com.slskin.ignitenetwork.views.accountsetup.AccountSetupView;
	import flash.display.DisplayObject;
	
	public class FooterView extends SLView 
	{
		/* Constants */
		private const LEFT_PADDING: Number = -137;
		private const TOP_PADDING: Number = 268;
		private const LOGO_SIZE: Number = 75;
		private const ICON_PADDING: Number = 8; // padding between social icons
		private const RIBBON_PADDING: Number = 5; // padding at the end of the ribbon
		private const LOGOUT_TEXT_COLOR: uint = 0x333333;
		private const STATUS_USERNAME_COLOR: uint = 0x0080FF;
		private const STATUS_DEFAULT_COLOR: uint = 0xCCCCCC;
		private const LOGOUT_ROLLOVER_COLOR: uint = 0x990000;
		
		/* Member fields */
		private var socialIcons: MovieClip; // stores IconLinks for each social network link
		private var username: String; // current username
		private var setup: AccountSetupView; // used to edit profile if enabled.
		
		/* Text Formats used for profile status tlf */
		private var defaultFormat: TextFormat = new TextFormat("Tahoma", 12, STATUS_DEFAULT_COLOR, false, false, false);
		private var usernameFormat: TextFormat = new TextFormat("Tahoma", 13, STATUS_USERNAME_COLOR, false, false, false);
		private var linkUsernameFormat: TextFormat = new TextFormat("Tahoma", 13, STATUS_USERNAME_COLOR, false, false, true);
		private var rollOverUsername: TextFormat = new TextFormat("Tahoma", 13, STATUS_DEFAULT_COLOR, false, false, true);
		
		public function FooterView() 
		{
			this.socialIcons = new MovieClip();
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/** 
		 * Listens for added to stage event.
		 */
		private function onAdded(evt: Event): void
		{
			// remove event listener
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			// start at the bottom of the stage
			this.startPos = new Point(centerX, main.getStageHeight() + this.height);

			// update the start position point with
			// the new padding values
			this.xPadding = this.LEFT_PADDING;
			this.yPadding = this.TOP_PADDING;
			this.startPos.x += this.xPadding;
			this.startPos.y += this.yPadding;
			this.moveToStart();
			
			// load the logo
			with(this.logoLoader)
			{
				width = this.LOGO_SIZE;
				height = this.LOGO_SIZE;
				scale = maintainAspectRatio = true;
				load(new URLRequest(main.config.Images.footerLogo));
			}
			
			// set Headline
			this.setHeadline(main.model.getProperty("Headline1", main.model.TEXT_PATH));
			
			// set sub headline
			this.subHeadlineTLF.text = main.model.getProperty("Headline2", main.model.TEXT_PATH);
			
			// set logout button text
			// note, all registration points are right aligned.
			with(this.logoutButton) 
			{
				tlf.autoSize = "right"
				tlf.text = Language.translate("Logout", "Logout");
				bg.width = tlf.width + icon.width + 10;
				hitbox.width = bg.width;
				// set x to a whole number.
				icon.x = Math.floor((bg.width*-1) + icon.width + 6);
			}
			
			// set current user
			this.username = main.model.getProperty("Username", main.model.DATA_PATH);
			this.statusTLF.text =  Language.translate("Current_User", "Current user") + " " + this.username;
			this.setUsernamFormat(this.usernameFormat);
			
			
			// listen for logout button events
			this.logoutButton.hitbox.tabEnabled = false;
			this.logoutButton.hitbox.addEventListener(MouseEvent.CLICK, onLogoutClick);
			this.logoutButton.hitbox.addEventListener(MouseEvent.ROLL_OVER, onLogoutRollOver);
			this.logoutButton.hitbox.addEventListener(MouseEvent.ROLL_OUT, onLogoutRollOut);
			
			// add social links
			this.addSocialIcons();
			
			// add 'Your Profile' link
			this.addEditProfileLink();
			
			// show view
			this.showView();
			
			// listen for logging out event.
			this.main.model.addEventListener(SLEvent.LOGGING_OUT, this.onUserLoggingOut);
		}
		
		/**
		 * Sets the format of the username string in the status TLF.
		 */
		private function setUsernamFormat(fmt: TextFormat): void 
		{
			this.statusTLF.setTextFormat(this.defaultFormat, 0, (this.statusTLF.text.length - username.length));
			this.statusTLF.setTextFormat(fmt, (this.statusTLF.text.length - username.length), this.statusTLF.length);
		}
		
		/**
		 * Sets the headline property in the headTLF and resizes / moves the UI
		 * depending the headline textWidth.
		 */
		private function setHeadline(str: String): void
		{
			this.headLineTLF.text = str;
			var textWidth: Number = this.headLineTLF.textWidth + ICON_PADDING;
			this.headLineTLF.width = textWidth;
			this.ribbon.bar.width = textWidth + RIBBON_PADDING;
			this.ribbon.lines.width = this.ribbon.bar.width;
		}
		
		/**
		 * Displays social links that are set in the config.xml file.
		 */
		private function addSocialIcons(): void
		{
			// set the x and y
			this.socialIcons = new MovieClip();
			socialIcons.x = this.ribbon.bar.width + (ICON_PADDING * 2) + LOGO_SIZE;
			socialIcons.y = this.ribbon.y;
			
			var link: IconLink;
			var numLinks: uint = main.config.Social.link.length();
			for (var i: uint = 0; i < numLinks ; i++)
			{
				// create link object from xml values
				link = new IconLink(main.config.Social.link[i].@alias, main.config.Social.link[i], 
									main.config.Social.link[i].@iconPath);
				
				// set x and y
				link.x = (i * link.width) + (i * this.ICON_PADDING);
				
				// add to mc holder
				this.socialIcons.addChild(link);
			}
			
			// add the social icons mc to stage
			this.addChild(this.socialIcons);
		}
		
		/**
		 * Adds the edit profile link if set in options list.
		 */
		private function addEditProfileLink(): void 
		{
			var optionsList: String = main.model.getProperty("OptionsList", main.model.ROOT_PATH);
			if (optionsList == null || optionsList.search("-2") == -1) return;
			
			// parse out the 'Your Profile' application name from the OptionsList string.
			var optionsArr: Array = optionsList.split(main.model.DIM);
			optionsArr[0] = optionsArr[0].split(main.model.DlMSep);
			
			// set formats to make username in status tlf to look like a link
			this.setUsernamFormat(this.linkUsernameFormat);
			
			// listen for click handlers
			this.statusTLF.buttonMode = this.statusTLF.useHandCursor = true;
			this.statusTLF.addEventListener(MouseEvent.ROLL_OVER, onStatusRollOver);
			this.statusTLF.addEventListener(MouseEvent.ROLL_OUT, onStatusRollOut);
			this.statusTLF.addEventListener(MouseEvent.CLICK, onStatusClick);
		}
		
		/**
		 * Call the logout routine in the sl client, listen for progress,
		 * and show a LoadingView.
		 */
		private function onLogoutClick(evt: Event): void 
		{
			if (ExternalInterface.available) 
			{
				ExternalInterface.call("UserLogout", "");
				this.main.model.addEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
			}
		}
		
		/**
		 * Show the loader
		 */
		private function onUserLoggingOut(evt: SLEvent): void 
		{
			// remove account setup if its added
			if (this.setup != null && main.contains(this.setup))
				main.removeChild(this.setup);
				
			LoadingView.getInstance().showLoader();
			LoadingView.getInstance().loadingText = Language.translate("Logging_Out", main.config.Strings.LoggingOut);
			this.main.model.removeEventListener(SLEvent.LOGGING_OUT, this.onUserLoggingOut);
		}
		
		
		private function onAccountEditComplete(evt: SLEvent): void 
		{
			if (this.setup == null) return;
			
			main.model.removeEventListener(SLEvent.REQUIRED_INFO_ENTERED, this.onAccountEditComplete);
			this.setup.hideView();
			this.setup.addEventListener(SLView.HIDE_COMPLETE, function(evt: Event): void {
										main.removeChild(evt.target as DisplayObject);
										setup = null;
										});
		}
		
		/**
		 * Listens for value added events from the model and responds to the
		 * key value pairs that pertain to the logout process.
		 */
		private function onValueAdded(evt: SLEvent): void
		{
			var split: Array = String(evt.argument).split(main.model.DIM);
			var key: String = split[0];
			var val: String = split[1];
			switch (key)
			{
				case main.model.DATA_PATH + "LoadingStatus": 
					if (val == "Done")
					{
						LoadingView.getInstance().hideLoader();
						main.model.removeEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
					}
					else if (val == "Failed")
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
		
		/**
		 * Change the button background.
		 */
		private function onLogoutRollOver(evt: MouseEvent): void {
			this.logoutButton.tlf.textColor = this.LOGOUT_ROLLOVER_COLOR;
			this.logoutButton.bg.gotoAndStop("Down");
		}
		
		/**
		 * Change the background back to up.
		 */
		private function onLogoutRollOut(evt: MouseEvent): void {
			this.logoutButton.tlf.textColor = this.LOGOUT_TEXT_COLOR;
			this.logoutButton.bg.gotoAndStop("Up");
		}
		
		/**
		 * Display an account setup view.
		 */
		private function onStatusClick(evt: MouseEvent): void 
		{
			if (this.setup != null) return;
			
			this.setup = new AccountSetupView(2);
			main.model.addEventListener(SLEvent.REQUIRED_INFO_ENTERED, this.onAccountEditComplete);
			main.addChild(setup);
		}
		
		private function onStatusRollOver(evt: MouseEvent): void {
			this.setUsernamFormat(this.rollOverUsername);
		}
		
		private function onStatusRollOut(evt: MouseEvent): void {
			this.setUsernamFormat(this.linkUsernameFormat);
		}
	} // class
} // package
