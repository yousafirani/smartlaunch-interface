/*
Ruben Oanta
SL Interface

Defines the AccountSetupView. This as file is associated to the 
AccountSetupView movieclip in the fla library. The account setup
is split into steps - Password Step, and Personal Info Step.
*/
package com.slskin.ignitenetwork.views.accountsetup
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import com.slskin.ignitenetwork.components.*;
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.*;
	import fl.transitions.Tween;
	import flash.display.InteractiveObject;
	import com.slskin.ignitenetwork.events.SLEvent;
	import flash.external.ExternalInterface;

	public class AccountSetupView extends SLView
	{
		/* Consts */
		private const START_X:Number = 15; //the x value to give the children elements
		private const START_Y:Number = 55; //the y value to give the children elements
		private const PADDING:Number = 20; //padding between children elements
		
		/* Memeber Fields */
		private var requiredInfo:uint; //stores the required info integer loaded from SL.
		private var passwordSetup:AccountSetupPassword; //responsible for password setup.
		private var userInfoSetup:AccountSetupInfo; //responsible for user info setup.
		private var setupProgress:AccountSetupProgress; //responsible for visually displaying the setup progress.
		private var passwordRequired:Boolean;
		private var userInfoRequired:Boolean;
		
		public function AccountSetupView(requiredInfo:uint) 
		{
			this.requiredInfo = requiredInfo;
			
			//iterprets the requiredInfo int and stores the results.
			this.passwordRequired = (requiredInfo == 1 || requiredInfo == 3);
			this.userInfoRequired = (requiredInfo == 0 || requiredInfo == 2 || requiredInfo == 3);
			
			//setup title
			this.titleTab.title.text = Language.translate("Account_Setup", "Account Setup");
			this.titleTab.x = (this.width - this.titleTab.width)/2;
			
			//listen for added to stage event
			this.addEventListener(Event.ADDED_TO_STAGE, this.onAdded);
		}
		
		/*
		On added to stage event handler
		*/
		private function onAdded(evt:Event):void
		{
			//depending on our requiredInfo, create objects accordingly
			if(this.passwordRequired && this.userInfoRequired)
			{
				this.passwordSetup = new AccountSetupPassword(this.main);
				this.userInfoSetup = new AccountSetupInfo(this.main);
			}
			else if(this.passwordRequired)
				this.passwordSetup = new AccountSetupPassword(this.main);
			else
				this.userInfoSetup = new AccountSetupInfo(this.main, 1); //tell the user info obj that it is the first step
			
			//create account setup progress object that keeps track of the form progress.
			this.setupProgress = new AccountSetupProgress(passwordSetup, userInfoSetup);
			
			//listen for setup progress complete event
			this.setupProgress.addEventListener(AccountSetupProgress.PROGRESS_COMPLETED, onSetupComplete);
			
			//add elements to stage
			this.addChildren();
		}
		
		/*
		addChildren
		adds the account setup children elements to stage.
		*/
		private function addChildren():void
		{
			var nextItemY:Number = this.START_Y;
			
			//add password setup to stage
			if(this.passwordSetup != null)
			{
				this.passwordSetup.x = this.START_X;
				this.passwordSetup.y = nextItemY;
				nextItemY += this.passwordSetup.height + this.PADDING;
				this.addChild(this.passwordSetup);
			}
			
			//add user info setup to stage
			if(this.userInfoSetup != null)
			{
				this.userInfoSetup.x = this.START_X;
				this.userInfoSetup.y = nextItemY;
				this.addChild(this.userInfoSetup);
				
				//calculate new height after we have added user info to stage
				nextItemY += this.userInfoSetup.height + this.PADDING;
			}
			
			//add progress to stage
			this.setupProgress.x = this.START_X;
			this.setupProgress.y = nextItemY;
			nextItemY += this.setupProgress.height + this.PADDING;
			this.addChild(this.setupProgress);
			
			//adjust the height of the window
			this.window.height = nextItemY + this.PADDING;
			
			//show the view, after we update the y to
			//reflect the changes in height to this window.
			this.setupView();
			this.showView();
		}
		
		/*
		onSetupComplete
		Event listener that is triggered when the user has completed the 
		forms correctly.
		*/
		private function onSetupComplete(evt:Event)
		{
			main.debugger.write("Saving Account Information...");
			
			//Tell each child to save data in shared data pool
			if(this.passwordSetup != null)
				this.passwordSetup.saveData();
			
			if(this.userInfoSetup != null)
				this.userInfoSetup.saveData();
			
			//Tell client that new data is available.
			ExternalInterface.call("UserInfoUpdated");
			
			//Listen for RequiredInformationEntered event triggered by SL client.
			//which indicates that the data was saved.
			main.addEventListener(SLEvent.REQUIRED_INFO_ENTERED, onDataSaved);
		}
		
		/*
		onDataSaved
		Event handler for event that is triggered when SL has received and saved the
		data correctly.
		*/
		private function onDataSaved(evt:SLEvent):void
		{
			main.debugger.write("User data has been saved by SL client!");
			this.hideView();
		}
		
	}//class
}//package