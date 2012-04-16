/*
Defines the behavior for the gender selector
component.
*/
package com.slskin.ignitenetwork.components 
{
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.text.TLFTextField;
	import com.slskin.ignitenetwork.Language;
	
	public class SLSexSelector extends MovieClip 
	{
		/* Constants */
		public static const MALE:String = "Male";
		public static const FEMALE:String = "Female";
		
		public function SLSexSelector() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/* Getters */
		public function get isSelected():Boolean {
			return this.maleCB.selected || this.femaleCB.selected;
		}
		
		public function get selectedGender():String
		{
			if(this.maleCB.selected)
				return SLSexSelector.MALE;
			else
				return SLSexSelector.FEMALE;
		}
		
		/* Setter */
		public function set selectedGender(gender:String):void
		{
			if(gender == SLSexSelector.MALE)
				this.maleCB.selected = true;
			else if(gender == SLSexSelector.FEMALE)
				this.femaleCB.selected = true;
		}
		
		private function onAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			this.maleCB.labelText = Language.translate("Male", "Male");
			this.femaleCB.labelText = Language.translate("Female", "Female");
			this.maleCB.addEventListener(MouseEvent.CLICK, onMaleSelected);
			this.femaleCB.addEventListener(MouseEvent.CLICK, onFemaleSelected);
		}
		
		private function onMaleSelected(evt:MouseEvent):void {
			this.femaleCB.selected = false;
		}
		
		private function onFemaleSelected(evt:MouseEvent) {
			this.maleCB.selected = false;
		}
		
	} //class
}//package
