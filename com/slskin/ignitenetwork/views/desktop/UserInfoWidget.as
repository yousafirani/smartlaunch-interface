/*
UserInfoWidget.as
Definition for user info widget in the DashBoardView.
This widget displays the welcome message, user time, and
balance.
*/
package com.slskin.ignitenetwork.views.desktop 
{	
	import flash.display.MovieClip;
	import flash.events.Event;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.*;
	import fl.controls.ScrollBarDirection;
	import fl.text.TLFTextField;
	import flash.text.TextFieldAutoSize;
	
	public class UserInfoWidget extends MovieClip 
	{
		/* Member Fields */
		private var main:Main; //reference to doc class
		
		public function UserInfoWidget() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded
		Event handler for added to stage. Updates the user info widget 
		and adds listener for value added events to update the widget as 
		new data comes into the model.
		*/
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAdded);
			
			//set reference to main
			this.main = (root as Main);
			
			//autosize welcome text
			this.welcomeTLF.autoSize = TextFieldAutoSize.LEFT;
			
			//update the user info
			this.updateUserInfo();
			
			//set the title from SL
			this.titleTLF.text = Language.translate("User_Info", "User Info");
			
			//setup the scroll bar for the welcome message
			this.setupScrollPane();
			this.welcomePane.source = this.welcomeTLF;
			
			//listen for value added events
			main.model.addEventListener(SLEvent.VALUE_ADDED, onValueAdded);
		}
		
				
		/*
		onValueAdded
		Event handler for SLEvent.VALUE_ADDED event. If the value is 
		Welcome_Message, Time, or Balance then update the UI accordingly.
		*/
		private function onValueAdded(evt:SLEvent):void
		{
			var split:Array = String(evt.argument).split(main.model.DIM);
			var key:String = split[0];
			var val:String = split[1];
			switch (key)
			{
				case main.model.TEXT_PATH + "Welcome_Message":
				case main.model.DATA_PATH + "Time":
				case main.model.DATA_PATH + "Balance":
					updateUserInfo();
					break;
				default:
					break;
			}
		}
		
		/*
		updateUserInfo
		Updates the user info widget welcome message, time left, and
		balance fields. The new values are read from the model getProperty
		method.
		*/
		private function updateUserInfo()
		{
			//set welcome message
			this.welcomeTLF.htmlText = main.model.getProperty("Welcome_Message", main.model.TEXT_PATH);
			
			//set time left / used field
			var time:Number = Number(main.model.getProperty("Time", main.model.DATA_PATH));
			var isNegative:Boolean = time < 0;
			if(isNegative) time *= -1; //convert to positive
			var hours:int = time / 60; //calculate hours
			var min:int = time % 60; //calculare remainder - minutes
			this.timeTLF.text = (isNegative ? "-" : "") + hours + "h " + min + "min";
			
			//set balanace
			var balance:Number = Number(main.model.getProperty("Balance", main.model.DATA_PATH));
			isNegative = balance < 0;
			if(isNegative) balance *= -1; //convert to positive
			this.balanceTLF.text = (isNegative ? "(" : "") + "$" + balance.toFixed(2) + (isNegative ? ")" : "");
		}
		
		/*
		setupScrollPane
		Styles and attaches the welcomeTLF to the ScrollPane.
		*/
		private function setupScrollPane():void 
		{
			//hide arrows
			this.welcomePane.setStyle("scrollArrowHeight", 0);
			this.welcomePane.setStyle("scrollBarWidth", 8);
			
			//setup track
			this.welcomePane.setStyle("trackUpSkin", ScrollTrack_Invisible);
			this.welcomePane.setStyle("trackOverSkin", ScrollTrack_Invisible);
			this.welcomePane.setStyle("trackDownSkin", ScrollTrack_Invisible);
			this.welcomePane.setStyle("trackDisabledSkin", ScrollTrack_Invisible);
			
			//setup thumb
			this.welcomePane.setStyle("thumbUpSkin", ScrollThumb_Up_Dark);
			this.welcomePane.setStyle("thumbOverSkin", ScrollThumb_Up_Dark);
			this.welcomePane.setStyle("thumbDownSkin", ScrollThumb_Up_Dark);
			
			//down arrow
			this.welcomePane.setStyle("downArrowUpSkin", ArrowSkin_Invisible); 
			this.welcomePane.setStyle("upArrowUpSkin", ArrowSkin_Invisible);
		}
		
	} //class
} //package
