/* 
Class responsible for user info form. Sits
inside the AccountSetupView and is linked
to the SetupUserInfoView mc.
*/
package com.slskin.ignitenetwork.views.accountsetup
{
	import flash.display.MovieClip;
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.FocusEvent;
	import com.slskin.ignitenetwork.*;
	import com.slskin.ignitenetwork.components.TextInput;
	import com.slskin.ignitenetwork.components.SexSelector;
	import com.slskin.ignitenetwork.util.Strings;
	import flash.events.MouseEvent;
	import com.slskin.ignitenetwork.components.CheckBox;
	import flash.text.TextFieldAutoSize;
	
	public class AccountSetupInfo extends MovieClip 
	{
		/* Consts */
		private const OFFSET_X:Number = 0; //indicates the starting x value to place the fields
		private const OFFSET_Y:Number = 50; //indicates the starting y value to place the fields
		private const COLUMN_PADDING:Number = 22; //padding between fields in column
		private const ROW_PADDING:Number = 18; //padding between fields in row
		private const MAX_COLUMNS:int = 3; //number of columns in form.
		private const MAX_WIDTH:Number = 500; //in pixels
		
		/* Member fields */
		private var stepNumber:int; //stores the step we are in the setup process.
		private var main:Main; //reference to main document class
		private var fields:Array; //stores the fields used to gather user info
		private var mailingListField:CheckBox; //Used to ask to opt into mailing list
		
		public function AccountSetupInfo(main:Main, step:int = 2) 
		{
			this.stepNumber = step;
			this.main = main;
			
			//wait to be added to stage
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded
		Listens for the added to stage event
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
						
			//set the title
			this.header.title.autoSize = TextFieldAutoSize.LEFT;
			this.header.title.text = Language.translate("Personal_Information", "Personal Information");
			this.header.title.y = (this.header.height - this.header.title.height) / 2;
			
			//resize header line
			this.header.graphics.lineStyle(1, 0x666666);
			this.header.graphics.moveTo(this.width + 5, this.height / 2 );
			this.header.graphics.lineTo(this.MAX_WIDTH, this.height / 2);
			
			//remove focus from header
			InteractiveObject(this.header.title.getChildAt(1)).tabEnabled = false;
			
			//add fields to stage
			setupFields();
		}
		
		
		/* 
		setupFields
		Setup User info fields based on information from passed in from SL client.
		*/
		private function setupFields():void
		{
			//get required fields and info passed in from SL
			var requiredBitVector:String = main.model.getProperty("RequiredUserInformation", main.model.DATA_PATH);
			var possibleFields:Array = main.model.getProperty("PersonalInfoArray", main.model.DATA_PATH).split(main.model.DlMSep);
			
			var column:int = 0;
			var row:int = 0;
			var nextX:Number = 0;
			var nextY:Number = 0;
			this.fields = new Array();
			
			for(var i = 0; i < possibleFields.length; i++)
			{
				if(requiredBitVector.charAt(i) == "1")
				{
					var field:MovieClip; //stores field obj
					var fieldName:String = possibleFields[i];
					var fieldValue:String = main.model.getProperty(fieldName, main.model.DATA_PATH);
					
					if(fieldName == "Sex")
					{
						field = new SexSelector();
						field.name = fieldName;
						
						if(fieldValue == "1")
							field.selectedGender = SexSelector.MALE;
						else if(fieldValue == "2")
							field.selectedGender = SexSelector.FEMALE;
							
						field.addEventListener(MouseEvent.CLICK, dispatchProgress);
					}
					else
					{
						//create new field and pass in fieldName as hint.
						var fieldHint:String = Language.translate(fieldName, fieldName);
						field = new TextInput(fieldHint);
						
						//setup tabbing on field
						InteractiveObject(field.field.getChildAt(1)).tabIndex = i + 2;
						
						//setup other field variables
						field.required = true;
						field.name = fieldName;
						
						//fill in field if we already have a value for it.
						if(fieldValue != null)
							field.text = fieldValue;
						
						/* Special Fields */
						switch(fieldName)
						{
							case "Birthday":
							
								field.field.restrict = "0-9/";
								field.hint += " (MM/DD/YYYY)";
								field.field.maxChars = 10;
								field.fieldValidator = this.birthdayValidator;
								//Birthday is stored seperately by SL client
								fieldValue = main.model.getProperty(fieldName + "_Month", main.model.DATA_PATH) + "/" +
										   	main.model.getProperty(fieldName + "_Day", main.model.DATA_PATH) + "/" +
										   	main.model.getProperty(fieldName + "_Year", main.model.DATA_PATH);
											
								//make sure we have a found a valid date.
								//for some reason the client defaults to date 1/1/1900 for
								//new users which doesn't really make sense.
								if(fieldValue != "null/null/null" && fieldValue != "1/1/1900")
									field.text = fieldValue;
								
								break;
								
							case "Zip":
								field.field.restrict = "0-9";
								field.field.maxChars = "5";
								break;
								
							case "Email":
								field.fieldValidator = this.emailValidator;
								break;
								
							case "Telephone":
							case "Mobilephone":
							case "PersonalNumber":
								field.field.maxChars = 20;
								field.field.restrict = "0-9";
								field.fieldValidator = this.phoneValidator;
								break;
						}
						
						//listen for field validation change and focus events
						//to update the form progress.
						field.addEventListener(TextInput.VALIDATION_CHANGE, dispatchProgress);
						field.field.addEventListener(FocusEvent.FOCUS_OUT, dispatchProgress);
					}
					
					//calculate nextX and nextY
					nextX = (field.width * column) + (COLUMN_PADDING * column) + OFFSET_X;
					nextY = (field.height * row) + (ROW_PADDING * row) + OFFSET_Y;
					
					field.x = nextX;
					field.y = nextY;
					
					//store the field
					this.fields.push(field);
					
					//add to stage
					this.addChildAt(field, 0);
					
					//increase row and column accordingly
					column++;
					if(column % MAX_COLUMNS == 0)
					{
						row++;
						column = 0;
					}
				}
			}//for each possible field.
			
			//add mailchimp checkbox
			if(main.config.MailChimp.@enabled == "true")
			{
				this.mailingListField = new CheckBox(main.config.MailChimp);
				this.mailingListField.selected = (main.config.MailChimp.@selected == "true");
				this.mailingListField.x = this.OFFSET_X;
				this.mailingListField.y = this.height + this.mailingListField.height;
				this.addChild(this.mailingListField);
			}
			
			//add terms of service check box
			if(main.config.TermsOfService.@enabled == "true")
			{
				var tos:CheckBox = new CheckBox(main.config.TermsOfService);
				tos.x = this.OFFSET_X;
				tos.y = this.height + tos.height;
				tos.addEventListener(MouseEvent.CLICK, dispatchProgress);
				this.fields.push(tos);
				this.addChild(tos);
			}
			
			//dispatch progress update
			dispatchProgress();
		}
		
		/*
		dispatchProgress
		Calculates progress and dispatches a progress event
		with the status.
		*/
		private function dispatchProgress(evt:Event = null):void
		{
			var currentProgress:int = 0;
			
			//check each field and update the progress
			for(var i:int = 0; i < this.fields.length; i++)
			{
				var obj:MovieClip = this.fields[i];
				if(obj is TextInput)
				{
					if(!obj.isEmpty() && !obj.hasError)
						currentProgress++;
				}
				else if(obj is SexSelector)
				{
					if(obj.isSelected)
						currentProgress++;
				}
				else if(obj is CheckBox)
				{
					if(obj.selected)
						currentProgress++;
				}
			}
			
			var pe:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS);
			pe.bytesTotal = this.fields.length;
			pe.bytesLoaded = currentProgress;
			this.dispatchEvent(pe);
		}
		
		/*
		saveData
		Saves the form data to the data pool
		shared between the SL client and the interface.
		*/
		public function saveData():void
		{
			//store birthday for mail chimp
			var birthday:Date;
			
			//update data for each field
			for(var i:int = 0; i < this.fields.length; i++)
			{
				var obj:MovieClip = this.fields[i];
				var fieldName:String = obj.name;
				var fieldVal:String;
				if(obj is TextInput)
					fieldVal = obj.text;
				else if(obj is SexSelector)
					fieldVal = (obj.selectedGender == SexSelector.MALE ? "1" : "2");
				
				//trace(fieldName, fieldVal);
				if(fieldName == "Birthday")
				{
					birthday = new Date(Date.parse(fieldVal));
					var date:Array = fieldVal.split("/");
					main.model.addProperty(main.model.DATA_PATH + fieldName + "_Month", date[0]);
					main.model.addProperty(main.model.DATA_PATH + fieldName + "_Day", date[1]);
					main.model.addProperty(main.model.DATA_PATH + fieldName + "_Year", date[2]);
				}
				else
					main.model.addProperty(main.model.DATA_PATH + fieldName, fieldVal);
			}
			
			//subscribe to mail chimp
			if(this.mailingListField != null && this.mailingListField.selected)
			{
				var doublOpt:Boolean = (main.config.MailChimp.@doubleOptin == "true");
				var mcs:MailChimpSubscribe = new MailChimpSubscribe(main.config.MailChimp.@apiKey, 
																	main.config.MailChimp.@listID, doublOpt);
				
				//mcs.addEventListener(Event.COMPLETE, onSubscribeSuccess);
				mcs.addEventListener(ErrorEvent.ERROR, onSubscribeError);
				mcs.addEventListener(IOErrorEvent.IO_ERROR, onMailChimpError);
				
				var email:String = main.model.getProperty(main.model.DATA_PATH + "Email");
				var fname:String = main.model.getProperty(main.model.DATA_PATH + "Firstname");
				var lname:String = main.model.getProperty(main.model.DATA_PATH + "Lastname");
				var slusername:String = main.model.getProperty(main.model.DATA_PATH + "Username");
				mcs.subscribe(email, fname, lname, birthday, slusername);
			}
		}
		
		/*
		onSubscribeError
		*/
		private function onSubscribeError(evt:ErrorEvent):void {
			main.log("Mail Chimp Subscription Error: " + evt.text);
		}
		
		/*
		onMailChimpError
		Usually called when there was a problem accessing the mail chimp api. Maybe a network issue.
		*/
		private function onMailChimpError(evt:IOErrorEvent):void {
			main.log("Mail Chimp API Error: " + evt.text);
		}
		
		
		/*
		birthdayValidator
		Makes sure the birthday is in the correct format.
		*/
		private function birthdayValidator(bday:String):String
		{
			var dateRegEx:RegExp = new RegExp("[0-9]{1,2} / [0-9]{1,2} / [0-9]{4}", "x");
			
			if(!bday.match(dateRegEx))
				return main.config.Strings.InvalidBirthdayRegex;
			
			//if we have passed the regex validator, we can parse the date.
			var date:Array = bday.split("/");
			var month:Number = Number(date[0]);
			var day:Number = Number(date[1]);
			var year:Number = Number(date[2]);
			
			if(month > 12)
				return main.config.Strings.InvalidBirthdayMonth;
			
			if(day > 31)
				return main.config.Strings.InvalidBirthdayDay;
				
			var currentYear:Number = new Date().fullYear;
			var age:Number = currentYear - year;
			
			if(age > 100)
				return Strings.substitute(main.config.Strings.InvalidBirthdayTooOld, age);
			else if (age < 0)
				return main.config.Strings.InvalidBirthdayFuture;
			else if(age < 1)
				return main.config.Strings.InvalidBirthdayTooYoung;
			
			return null;
		}
		
		/* 
		phoneValidator
		Validates US phone numbers according to the format DDD-DDD-DDDD.
		*/
		private function phoneValidator(number:String):String
		{
			var usRegEx:RegExp = new RegExp("\\d{10} | \\d{11}}", "x");
			if(!number.match(usRegEx))
				return main.config.Strings.InvalidPhoneRegex;
			
			return null;
		}
		
		/*
		emailValidator
		Validates email string.
		*/
		private function emailValidator(email:String):String
		{
			var emailRegEx:RegExp = /^[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/i;
			
			if(email.search("@") == -1)
				return main.config.Strings.InvalidEmailMissingAt;
			else if(!email.match(emailRegEx))
				return main.config.Strings.InvalidEmailRegex;
				
			return null;
		}
		
	} //class
} //package

