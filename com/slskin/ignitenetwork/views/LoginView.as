/**
 * Defines the LoginWindow component found in the library. Handles the behaviors
 * of the login ui elements, and communicates with .NET backend
 * to validate login.
 */
package com.slskin.ignitenetwork.views
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import fl.text.TLFTextField;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.display.InteractiveObject;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import flash.net.URLRequest;
	import com.slskin.ignitenetwork.*;
	import com.slskin.ignitenetwork.events.*;
	import com.slskin.ignitenetwork.util.Strings;
	import com.slskin.ignitenetwork.fonts.MyriadSemiBold;
	import com.slskin.ignitenetwork.components.TextInput;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.text.TextFormat;
	import flash.filters.GlowFilter;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.edit.EditManager;

	public class LoginView extends SLView
	{
		/* consts */
		private const INACTIVE_MILLISEC: Number = 30000;// 30 seconds

		/* Member Variables */
		private var userTF: TextInput;// stores a reference to the username field.
		private var passTF: TextInput;// stores a reference to the password field.
		private var headline1: TLFTextField;// text field that displays the headline1 field set in the SL server
		private var headline2: TLFTextField;// text field that displays the headline2 field set in the SL server
		private var errorTween: Tween;
		private var inactivityTimer: Timer = new Timer(INACTIVE_MILLISEC);

		public function LoginView()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, this.onAdded);
		}

		/** 
		 * Listens for added to stage event.
		 */
		public function onAdded(evt: Event): void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAdded);

			// load logo
			this.logoLoader.load(new URLRequest(main.config.Images.loginLogo));
			this.logoLoader.addEventListener(IOErrorEvent.IO_ERROR, onLogoLoadError);

			this.loginButton.buttonMode = this.loginButton.useHandCursor = true;
			this.loginButton.tabEnabled = false;
			this.loginButton.addEventListener(MouseEvent.CLICK, this.sendLogin);
			this.loginButton.addEventListener(MouseEvent.ROLL_OVER, function(evt: MouseEvent): void { evt.target.play() });

			this.headline1 = createHeadline(new TextFormat(new MyriadSemiBold().fontName, "16", 0xFFFFFF));
			this.headline2 = createHeadline(new TextFormat(new MyriadSemiBold().fontName, "14", 0xFFFFFF));
			this.headline1.text = main.model.getProperty("Headline1",main.model.TEXT_PATH);
			this.headline2.text = main.model.getProperty("Headline2",main.model.TEXT_PATH);
			// add to main to maintain the correct width and height of this view.
			main.addChild(this.headline1);
			main.addChild(this.headline2);

			// get a reference to the username and password fields
			this.userTF = this.usernameField;
			this.passTF = this.passwordField;
			this.userTF.hint = Language.translate("Username","Username");
			this.passTF.hint = Language.translate("Password","Password");
			this.passTF.displayAsPassword = true;
			this.userTF.upperCase = true;
			this.userTF.required = true;
			this.userTF.tabIndex = 1;
			this.passTF.tabIndex = 2;

			// make room for arrow button on login screen
			this.passTF.tlf.width -=  this.loginButton.arrow.width;

			// listen for key down
			this.userTF.addKeyDownListener(this.onKeyPress);
			this.passTF.addKeyDownListener(this.onKeyPress);

			// listener for inactivity
			this.inactivityTimer.addEventListener(TimerEvent.TIMER, onInactivityTick);

			// listen for login events from the SL client;
			this.setupSLListeners();

			// fade in view
			this.alpha = 0;
			this.startPos = new Point(this.centerX,this.centerY);
			this.moveToStart();
			this.showView();
		}

		function createHeadline(fmt:  TextFormat): TLFTextField
		{
			var tlf = new TLFTextField();
			tlf.defaultTextFormat = fmt;
			with (tlf)
			{
				selectable = multiline = false;
				embedFonts = true;
				autoSize = "left";
			}
			InteractiveObject(tlf.getChildAt(1)).tabEnabled = false;
			tlf.filters = new Array(new GlowFilter(0x000000,1,5,5,2,3));
			return tlf;
		}

		/**
		 * Configure the appropriate listeners for SL Events 
		 */
		public function setupSLListeners(): void
		{
			// listen for property added and changed event
			main.model.addEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);

			// listen for login completed event
			main.model.addEventListener(SLEvent.LOGIN_APPROVED, this.onLoginApproved);
			main.model.addEventListener(SLEvent.LOGIN_COMPLETED, this.onLoginComplete);

			// listen for login denied
			main.model.addEventListener(SLEvent.LOGIN_DENIED, this.onLoginError);
		}

		public override function showView(evt: Event = null): void
		{
			super.showView();
			this.alphaTween = new Tween(this,"alpha",Strong.easeInOut,this.alpha,1,1,true);
			this.positionHeadlines();
		}

		private function positionHeadlines(): void
		{
			if (this.headline1 == null || this.headline2 == null)
			{
				return;
			}

			// move headline1 into top right corner
			this.headline1.x = main.getStageWidth() - this.headline1.width - 10;
			this.headline1.y = 10;

			// move headline2 under headline1
			this.headline2.x = main.getStageWidth() - this.headline2.width - 10;
			this.headline2.y = this.headline1.y + this.headline1.textHeight + 10;
		}

		/**
		 * Animates the object out of view.
		 */
		public override function hideView(evt: Event = null): void
		{
			this.alphaTween = new Tween(this,"alpha",Strong.easeInOut,this.alpha,0,1,true);
			this.alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onHideTweenFinish);

			if (main.contains(this.headline1))
			{
				main.removeChild(this.headline1);
			}

			if (main.contains(this.headline2))
			{
				main.removeChild(this.headline2);
			}

			// remove listeners
			main.model.removeEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
			main.model.removeEventListener(SLEvent.LOGIN_APPROVED, this.onLoginApproved);
			main.model.removeEventListener(SLEvent.LOGIN_COMPLETED, this.onLoginComplete);
			main.model.removeEventListener(SLEvent.LOGIN_DENIED, this.onLoginError);
		}

		/**
		 * Event handler for SLEvent.VALUE_ADDED. Listen for any variable
		 * changes/additions that are relavent to this view.
		 */
		private function onValueAdded(evt: SLEvent): void
		{
			var split: Array = String(evt.argument).split(main.model.DIM);
			var key: String = split[0];
			var val: String = split[1];
			switch (key)
			{
				case main.model.TEXT_PATH + "Headline1" : 
					this.headline1.text = val;
					this.positionHeadlines();
					break;
				case main.model.TEXT_PATH + "Headline2" : 
					this.headline2.text = val;
					this.positionHeadlines();
					break;
				case main.model.TEXT_PATH + "LoadingText" : 
				case main.model.DATA_PATH + "LoadingText" : 
					LoadingView.getInstance().loadingText = val;
					break;
			}
		}

		/** 
		 * Called when the LOGIN_COMPLETE event is triggered by the SL Client. 
		 */
		public function onLoginComplete(evt: SLEvent): void
		{
			LoadingView.getInstance().hideLoader();
			this.inactivityTimer.stop();
			this.hideView();
		}

		/**
		 * Called when the LOGIN_APPROVED event is triggered by the SL Client. 
		 */
		public function onLoginApproved(evt: SLEvent): void
		{
			LoadingView.getInstance().showLoader();
		}

		/**
		 * Listens for any login errors that occur.
		 */
		private function onLoginError(evt: SLEvent): void
		{
			// pull the error text passed in from the SL client.
			var errorStr: String = main.model.getProperty("ErrorMessage",main.model.TEXT_PATH);

			// The type of error is passed in with the event as an argument.
			switch (evt.argument)
			{
				case "Username Not Found^" : 
				case "Account Locked^" : 
					this.userTF.showError(errorStr);
					break;
				case "Wrong Password^" : 
				case "Out Of Order^" : 
					this.passTF.showError(errorStr);
					break;
				default : 
					this.passTF.showError(errorStr);
					break;
			}

			// wake timer to hide errors
			this.wakeInactivityTimer();
		}

		/**
		 * KeyDown listener for username and password fields.
		 */
		private function onKeyPress(evt: KeyboardEvent): void
		{
			wakeInactivityTimer();

			if (evt.keyCode == Keyboard.ENTER)
			{
				this.sendLogin();
			}
		}

		/**
		 * Called by event handlers from mouse or the keyboard. Calls the login
		 * function in the SL client if the data in the fields are valid.
		 */
		private function sendLogin(evt: Event = null): void
		{
			wakeInactivityTimer();

			this.userTF.checkRequired();
			this.passTF.checkRequired();

			if (this.userTF.text == "")
			{
				return;
			}

			if (ExternalInterface.available)
			{
				this.userTF.hideError();
				this.passTF.hideError();

				this.main.debugger.write("Attempting to login...");

				// get username and password from fields.;
				var username: String = Strings.trim(this.userTF.text);
				var pass: String = Strings.trim(this.passTF.text);

				// pass user name and password to SL client for verification
				ExternalInterface.call("UserLogin", username + main.model.DIM + pass);
			}
		}
		
		private function onLogoLoadError(evt: IOErrorEvent): void
		{
			main.log(evt.text);
		}

		/**
		 * starts or resets inactivity timer.
		 */
		private function wakeInactivityTimer(evt: Event = null): void
		{
			if (this.inactivityTimer.running)
			{
				this.inactivityTimer.stop();
				this.inactivityTimer.start();
			}
			else
			{
				this.inactivityTimer.start();
			}
		}
		
		/**
		 * Clears errors and fields on inactivity
		 */
		private function onInactivityTick(evt: TimerEvent): void
		{
			this.userTF.clearField();
			this.passTF.clearField();
	
			// stop the timer
			this.inactivityTimer.stop();
		}
	}// class
}// package