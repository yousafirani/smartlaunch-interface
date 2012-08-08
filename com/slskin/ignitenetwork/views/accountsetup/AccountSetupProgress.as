/**
 * Manages the progress of the account setup
 * process. The progress is displayed visually with
 * a progress bar and steps.
 */
package com.slskin.ignitenetwork.views.accountsetup
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import com.slskin.ignitenetwork.components.SLButton;
	import com.slskin.ignitenetwork.Language;
	import flash.events.ProgressEvent;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flash.geom.ColorTransform;
	import fl.transitions.TweenEvent;
	import flash.events.MouseEvent;
	import com.slskin.ignitenetwork.Main;
	
	public class AccountSetupProgress extends MovieClip 
	{
		/* Event */
		public static const PROGRESS_COMPLETED: String = "ProgressComplete";
		
		/* Consts */
		private const FULL_LENGTH: Number = 348; // total possible length for the progress bar
		private const STEP_ONE_LENGTH: Number = 127; // length to get to finish step one
		private const PROGRESS_COLOR: int = 0x71BF00; // color of progress tint
		private const DEFAULT_COLOR: int = 0x999999;
		
		/* Member fields */
		private var barLength: uint;
		private var stepOne: AccountSetupPassword; // stores reference to password setup.
		private var stepTwo: AccountSetupInfo; // stores reference to user info setup.
		private var stepOneProgress: Number; // Keeps track of the progress on step 1
		private var stepTwoProgress: Number; // Keeps track of the progress on step 2
		private var progressOneTween: Tween; // tweens progress bar
		private var progressTwoTween: Tween; // tweens progress bar
		
		public function AccountSetupProgress(stepOne: AccountSetupPassword, stepTwo: AccountSetupInfo) 
		{			
			this.tabChildren = false;
			
			this.stepOneProgress = 0;
			this.stepTwoProgress = 0;
			
			this.stepOne = stepOne;
			this.stepTwo = stepTwo;
			
			// wait to be added to stage
			this.addEventListener(Event.ADDED, onAdded);
		}
		
		/**
		 * Listens for added to stage event.
		 */
		private function onAdded(evt: Event): void
		{
			this.removeEventListener(Event.ADDED, onAdded);
			
			// check if we only have 1 step
			if (this.stepOne == null || this.stepTwo == null)
			{
				this.step2Text.visible = false;
				this.step2Circle.visible = false;
			}
			
			// disable the button until the progress is complete
			(this.button as SLButton).label = Language.translate("Done", "Done");
			(this.button as SLButton).disable();
			(this.button as SLButton).addEventListener(SLButton.CLICK_EVENT, onDoneClick);
			(this.button as SLButton).addEventListener(SLButton.DISABLED_CLICK_EVENT, onDisabledClick);
			
			// listen for progress events
			if (this.stepOne != null)
				this.stepOne.addEventListener(ProgressEvent.PROGRESS, onStepOneProgress);
				
			if (this.stepTwo != null)
				this.stepTwo.addEventListener(ProgressEvent.PROGRESS, onStepTwoProgress);
			
			// create color based on progress color
			var c: ColorTransform = new ColorTransform();
			c.color = this.PROGRESS_COLOR;
			
			// setup progress bar
			this.pBar.width = 0;
			(this.pBar as MovieClip).transform.colorTransform = c;
			
			// change color of step one circle
			(stepOneCircle as MovieClip).transform.colorTransform = c;
			
		}
		
		/**
		 * Listens for progress from step one and updates the progress bar
		 * accordingly.
		 */
		private function onStepOneProgress(evt: ProgressEvent): void
		{
			// store progress
			this.stepOneProgress = evt.bytesLoaded / evt.bytesTotal;
			
			// calculate max width of progress bar
			var maxWidth: Number = this.STEP_ONE_LENGTH;
			if (this.stepTwo == null)
				maxWidth = this.FULL_LENGTH;
			
			// tween width of progress bar
			var barWidth: Number = this.stepOneProgress * maxWidth;
			
			// if we have changed since last time.
			if (barWidth != this.pBar.width)
				this.progressOneTween = new Tween(this.pBar, "width", Regular.easeOut, this.pBar.width, barWidth, .2, true);
			
			// check if step one is complete
			if (this.stepOneProgress == 1)
			{
				this.progressOneTween.addEventListener(TweenEvent.MOTION_FINISH, colorStepTwo);
				// update the any progress we have made on step two
				if (this.stepTwo != null)
					this.updateStepTwo(this.stepTwoProgress);
				else
					(this.button as SLButton).enable();
			}
			else
			{
				colorStepTwo();
				(this.button as SLButton).disable();
			}
		}
		
		/**
		 * Listens from progress from step two and updates the progress accordingly.
		 */
		private function onStepTwoProgress(evt: ProgressEvent): void
		{
			// store progress
			this.stepTwoProgress = evt.bytesLoaded / evt.bytesTotal;
			
			// trace(this.stepTwoProgress);
			// move the logic for step two outside of event handler
			// because it could be called by step one.
			if (this.stepOne == null || this.stepOneProgress == 1)
				updateStepTwo(this.stepTwoProgress);
		}
		
		/**
		 * updates the progress on step two based on the 
		 * parameter passed in.
		 */
		private function updateStepTwo(percentage: Number): void
		{
			// calculate max width of progress bar
			var maxWidth: Number = this.FULL_LENGTH - this.STEP_ONE_LENGTH - this.step2Circle.width;
			if (this.stepOne == null)
				maxWidth = this.FULL_LENGTH;
			
			// calculate the percentage of barWidth taking into
			// consideration what we have already done.
			var barWidth: Number = (percentage * maxWidth);
			
			if (this.stepOne != null)
				barWidth += this.step2Circle.width + this.STEP_ONE_LENGTH;
			
			// if we have changed since last time.
			if (barWidth != this.pBar.width)
				this.progressTwoTween = new Tween(this.pBar, "width", Regular.easeOut, this.pBar.width, barWidth, .2, true);
			
			// check to see if we are done with step 2 also
			if (this.stepTwoProgress == 1)
				(this.button as SLButton).enable();
			else
				(this.button as SLButton).disable();
		}
		
		
		/**
		 * Changes the color of the step two circle based on the
		 * completion of step one. Also calls update progress on 
		 */
		private function colorStepTwo(evt: TweenEvent = null): void
		{
			var c: ColorTransform = new ColorTransform();
			c.color = (this.stepOneProgress == 1 ? this.PROGRESS_COLOR :  this.DEFAULT_COLOR);
			(this.step2Circle as MovieClip).transform.colorTransform = c;
		}
		
		/**
		 * Handler for event when user clicks on the done button. Trigger
		 * continue event.
		 */
		private function onDoneClick(evt: Event): void
		{
			this.dispatchEvent(new Event(AccountSetupProgress.PROGRESS_COMPLETED));
		}
		
		private function onDisabledClick(evt: Event): void 
		{
			var main: Main = (root as Main)
			main.playSound(main.config.Sounds.InvalidFields);
		}
	}// class
} // package
