/*
Ruben Oanta
SL Interface

Defines the LoginWindow component found in the library. Handles the behaviors
of the login ui elements, and communicates with .NET backend
to validate login.
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
	import com.slskin.ignitenetwork.components.SLTextField;
	import com.slskin.ignitenetwork.components.SLCheckBox;
	import flash.geom.Point;
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	public class LoginView extends SLView
	{
		/* consts */
		private const INACTIVE_MILLISEC:Number = 30000; //30 seconds represents inactivity
		
		/* Member Variables */
		private var userTF:SLTextField; //stores a reference to the username field.
		private var passTF:SLTextField; //stores a reference to the password field.
		private var errorTween:Tween;
		private var inactivityTimer:Timer = new Timer(INACTIVE_MILLISEC); 
		
		/* Constructor */
		public function LoginView() {
			//listen for added to stage event
			this.addEventListener(Event.ADDED_TO_STAGE, this.onAdded);
		}
		
		/*
		onAdded 
		Listens for added to stage event.
		*/
		public function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAdded);
			
			//setup logo
			this.logoLoader.load(new URLRequest(main.config.Images.loginLogo));
			
			//set window title
			this.titleTab.title.text =  Language.translate("Account_Login", "Account Login");
			this.loginButton.label = Language.translate("Login", "Login");
			
			//set headline text
			this.subHeadlineTLF.text = main.model.getProperty("Headline2", main.model.TEXT_PATH);
			
			//center the title tab
			this.titleTab.x = (this.width - this.titleTab.width)/2;
			
			//setup error field
			this.errorField.text = "";
			this.errorField.alpha = 0;
			
			//get a reference to the username and password fields
			this.userTF = this.usernameField;
			this.passTF = this.passwordField;
			this.userTF.hint = Language.translate("Username", "Username");
			this.passTF.hint = Language.translate("Password", "Password");
			this.passTF.displayAsPassword = true;
			this.userTF.upperCase = true;
			this.userTF.required = true;
			
			//add listener to the login button
			this.loginButton.addEventListener("buttonClick", this.sendLogin);
			
			//listen for key down
			this.userTF.addKeyDownListener(this.onKeyPress);
			this.passTF.addKeyDownListener(this.onKeyPress);
			
			//disable tab enable on the login button and otber elements
			InteractiveObject(this.subHeadlineTLF.getChildAt(1)).tabEnabled = false;
			InteractiveObject(this.errorField.getChildAt(1)).tabEnabled = false;
			
			//listener for inactivity
			this.inactivityTimer.addEventListener(TimerEvent.TIMER, onInactivityTick);
			
			this.setupSLListeners();
			this.showView();
		}
		
		/*
		setupSLListeners
		Configure the appropriate listeners for SL Events 
		*/
		public function setupSLListeners():void
		{
			//listen for property added and changed event
			main.model.addEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
			
			//listen for login completed event
			main.model.addEventListener(SLEvent.LOGIN_APPROVED, this.onLoginApproved);
			main.model.addEventListener(SLEvent.LOGIN_COMPLETED, this.onLoginComplete);
			
			//listen for login denied
			main.model.addEventListener(SLEvent.LOGIN_DENIED, this.onLoginError);
		}
		
		/*
		hideView
		Animates the object out of view.
		*/
		public override function hideView(evt:Event = null):void
		{
			super.hideView();
			//remove listeners
			main.model.removeEventListener(SLEvent.VALUE_ADDED, this.onValueAdded);
			main.model.removeEventListener(SLEvent.LOGIN_APPROVED, this.onLoginApproved);
			main.model.removeEventListener(SLEvent.LOGIN_COMPLETED, this.onLoginComplete);
			main.model.removeEventListener(SLEvent.LOGIN_DENIED, this.onLoginError);
		}
		
		/*
		onValueAdded
		Event handler for SLEvent.VALUE_ADDED. Listen for any variable
		changes/additions that are relavent.
		*/
		private function onValueAdded(evt:SLEvent):void
		{
			var split:Array = String(evt.argument).split(main.model.DIM);
			var key:String = split[0];
			var val:String = split[1];
			switch (key)
			{
				case main.model.TEXT_PATH + "Headline1":
					break;
				case main.model.TEXT_PATH + "Headline2":
					this.subHeadlineTLF.text = val; //set the sub-headline
					break;
				case main.model.TEXT_PATH + "LoadingText":
				case main.model.DATA_PATH + "LoadingText":
					LoadingView.getInstance().loadingText = val;
					break;
			}
		}
				
		/*
		onLoginComplete
		Called when the LOGIN_COMPLETE event is triggered by the SL Client. 
		*/
		public function onLoginComplete(evt:SLEvent):void
		{
			LoadingView.getInstance().hideLoader();
			this.inactivityTimer.stop();
			this.hideView();
		}
		
		/*
		onLoginApproved
		Called when the LOGIN_APPROVED event is triggered by the SL Client. 
		*/
		public function onLoginApproved(evt:SLEvent):void
		{
			LoadingView.getInstance().showLoader();
			this.hideError();
		}
		
		/*
		onLoginError
		Listens for any login errors that occur.
		*/
		private function onLoginError(evt:SLEvent):void
		{
			//pull the error text passed in from the SL client.
			this.displayError(main.model.getProperty("ErrorMessage", main.model.TEXT_PATH));
			
			//The type of error is passed in with the event as an argument.
			/*switch(evt.argument)
			{
				case "Username Not Found^":
					this.displayError("Invalid username.");
					break;
				case "Wrong Password^":
					this.displayError("Invalid password.");
					break;
				case "Account Locked^":
					this.displayError("Your account is locked.");
					break;
				case "Out Of Order^":
					this.displayError("This computer is out of order.");
					break;
			}*/
		}
		
		/*
		onFieldKeyDown
		KeyDown listener for username and password fields.
		*/
		private function onKeyPress(evt:KeyboardEvent):void
		{
			wakeInactivityTimer();
			
			if(evt.keyCode == Keyboard.ENTER)
				this.sendLogin();
		}
		
		/*
		sendLogin
		Called by event handlers from mouse or the keyboard. Calls the login
		function in the SL client if the data in the fields are valid.
		*/
		private function sendLogin(evt:Event = null):void
		{
			wakeInactivityTimer();
			
			this.userTF.checkRequired();
			this.passTF.checkRequired();
			
			if(this.userTF.hasError || this.passTF.hasError)
				return;
			
			if(ExternalInterface.available)
			{
				this.userTF.hideError();
				this.passTF.hideError();
				//this.hideError();
				
				this.main.debugger.write("Attempting to login...");
				
				//get username and password from fields.
				var username:String = Strings.trim(this.userTF.text);
				var pass:String = Strings.trim(this.passTF.text);
				
				//pass user name and password to SL client for verification
				ExternalInterface.call("UserLogin", username + main.model.DIM + pass);
			}
		}
		
		/*
		displayError
		Fades in the error field with after setting it.
		Takes the error text.
		*/
		private function displayError(err:String):void
		{
			this.errorField.text = err;
			this.errorTween = new Tween(this.errorField, "alpha", Strong.easeIn, this.errorField.alpha, 1, .5, true);
		}
		
		/*
		hideError
		Fades out the error field
		*/
		private function hideError():void {
			this.errorTween = new Tween(this.errorField, "alpha", Strong.easeIn, this.errorField.alpha, 0, 1, true);
		}
		
		/*
		wakeInactivityTimer
		starts or resets inactivity timer.
		*/
		private function wakeInactivityTimer(evt:Event = null):void
		{
			if(this.inactivityTimer.running)
			{
				this.inactivityTimer.stop();
				this.inactivityTimer.start();
			}
			else
				this.inactivityTimer.start();
				
		}
		
		/*
		onInactivityTick
		Clears errors and fields on inactivity
		*/
		private function onInactivityTick(evt:TimerEvent):void
		{
			this.hideError();
			this.userTF.clearField();
			this.passTF.clearField();
			
			//stop the timer
			this.inactivityTimer.stop();
		}

	} //class
} //package
