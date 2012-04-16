/* 
Class responsible for password form verification. Sits
inside the AccountSetupView object and is linked
to the SetupPasswordView mc.
*/
package com.slskin.ignitenetwork.views.accountsetup
{
	import flash.display.MovieClip;
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.text.TextFieldAutoSize;
	import com.slskin.ignitenetwork.components.SLTextField;
	import com.slskin.ignitenetwork.*;
	
	public class AccountSetupPassword extends MovieClip
	{
		private const NUM_FIELDS:int = 2;
		private const MAX_WIDTH:Number = 650;
		private const MIN_PASSSWORD_LENGTH:int = 4; //If we change this, we need a better way to translate the error message in the validator.
		
		/* Member Fields */
		private var passwordField:SLTextField;
		private var repeatField:SLTextField;
		private var main:Main;
		
		public function AccountSetupPassword(main:Main) 
		{
			this.main = main;
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded
		Handler for added to stage event, configures listeners for
		fields.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			this.passwordField = this.Password;
			this.repeatField = this.Repeat;
			
			//set title
			this.header.title.autoSize = TextFieldAutoSize.LEFT;
			this.header.title.text = Language.translate("Account_Password", "Account Password");
			this.header.title.y = (this.header.height - this.header.title.height) / 2;
			
			//draw line to end
			this.header.graphics.lineStyle(1, 0x999999);
			this.header.graphics.moveTo(this.header.width + 5, this.header.height / 2);
			this.header.graphics.lineTo(this.MAX_WIDTH, this.header.height / 2);
			
			//setup both fields
			this.passwordField.displayAsPassword = true;
			this.repeatField.displayAsPassword = true;
			this.passwordField.hint = Language.translate("Desired_Password", "Desired Password");
			this.repeatField.hint = Language.translate("Repeat_Password", "Repeat Password");
			
			this.passwordField.fieldValidator = this.passwordValidator;
			this.repeatField.fieldValidator = this.repeatValidator;
			this.passwordField.required = true;
			this.repeatField.required = true;
			
			//fix tabbing
			InteractiveObject(this.header.title.getChildAt(1)).tabEnabled = false;
			InteractiveObject(this.passwordField.field.getChildAt(1)).tabIndex = 1;
			InteractiveObject(this.repeatField.field.getChildAt(1)).tabIndex = 2;
			
			
			//listen for field error events
			this.passwordField.addEventListener(SLTextField.VALIDATION_CHANGE, dispatchProgress);
			this.repeatField.addEventListener(SLTextField.VALIDATION_CHANGE, dispatchProgress);
		}
		
		/*
		dispatchProgress
		dispatch progress when validation has changed on a field.
		*/
		private function dispatchProgress(evt:Event):void
		{
			var currentProgress:int = 0;
			
			//check each field and update the progress
			if(!this.passwordField.isEmpty() && !this.passwordField.hasError)
				currentProgress++;
			
			if(!this.repeatField.isEmpty() && !this.repeatField.hasError)
				currentProgress++;
			
			var pe:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS);
			pe.bytesTotal = this.NUM_FIELDS;
			pe.bytesLoaded = currentProgress;
			this.dispatchEvent(pe);
		}
		
				
		/*
		saveData
		Saves the form data to the data pool
		shared between the SL client and the interface.
		*/
		public function saveData():void {
			//trace("NewPassword", this.passwordField.text);
			main.model.addProperty(main.model.DATA_PATH + "NewPassword", this.passwordField.text);
		}
		
		/* 
		Password Validator 
		Used to validate the password strength. Field Validators
		return null when there is no error.
		*/
		private function passwordValidator(pwd:String):String
		{
			//validate strength
			if(pwd.length < this.MIN_PASSSWORD_LENGTH)
				return Language.translate("Minimum_4_characters", "Minimum of " + this.MIN_PASSSWORD_LENGTH + " characters required.");
						
			//search regex for special character or digit
			var re:RegExp = /[!@#\\$%\\^&\\*_\\+=<>.\\?\\~`]+|\d+/;
			if(pwd.search(re) == -1)
				return main.config.Strings.InvalidPasswordRegex;
			
			//To completely validate this field, we need to make sure
			//the passwords match if the repeat feild is set.
			if(!this.repeatField.isEmpty())
				this.repeatField.validate();
			
			return null;
		}
		
		/*
		Repeat Validator
		Makes sure both passwords match.
		*/
		private function repeatValidator(pwd:String):String
		{
			var pwd:String = this.passwordField.text.toLowerCase();
			var pwdRepeat:String = this.repeatField.text.toLowerCase();
				
			if(pwd != pwdRepeat)
				return Language.translate("Passwords_does_not_match", "Passwords do not match");
			else
				return null;
		}
		
	}//class
} //package
