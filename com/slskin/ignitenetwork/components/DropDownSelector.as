package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.InteractiveObject;
	import com.slskin.ignitenetwork.views.ListView;
	
	public class DropDownSelector extends MovieClip 
	{
		/* Member Fields */
		private var _dropDownList:ListView;
		
		public function DropDownSelector() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(evt:Event):void 
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			//disable tabbing on tlf
			InteractiveObject(this.title.getChildAt(1)).tabEnabled = false;
		}
		
		public function set dropDownList(listView:ListView):void 
		{
			if(_dropDownList != null && this.contains(_dropDownList))
				this.removeChild(_dropDownList);
				
			_dropDownList = listView;
			_dropDownList.x = this.title.x;
			_dropDownList.y = this.height;
			this.addChild(_dropDownList);
		}

		public function set label(str:String):void {
			this.title.text = str;
		}
		
		public override function set enabled(enable:Boolean):void
		{
			if(this.stage == null) return;
			
			super.enabled = enable;
			this.alpha = (enable ? 1 : .5);
			this.buttonMode = enable;
			this.useHandCursor = enable;
			if(!enable) 
				this._dropDownList.visible = false;
				
			if(enable)
			{
				this.addEventListener(MouseEvent.CLICK, onSelectorClick);
				stage.addEventListener(MouseEvent.CLICK, onMasterClick);
			}
			else
			{
				this.removeEventListener(MouseEvent.CLICK, onSelectorClick);
				stage.removeEventListener(MouseEvent.CLICK, onMasterClick);
			}
		}
		
		/*
		toggleDropDown
		Toggles the sub category selector drop down menu.
		*/
		private function toggleDropDown():void
		{
			if(this._dropDownList.visible)
				this.background.gotoAndStop("Up");
			else
				this.background.gotoAndStop("Down");
			
			this._dropDownList.visible = !(this._dropDownList.visible);
		}
		
		/*
		onSelectorClick
		Show or hide the sub category list view depending on its current state.
		*/
		private function onSelectorClick(evt:MouseEvent):void {
			toggleDropDown();
			evt.stopPropagation(); //don't let the event propegate up to parent displayObjects.
		}
		
		/*
		onMasterClick
		Hides the sub categeroy drop down list. This allows for users to click anywhere
		and hide the drop down list if the dropdown is visible. (Expected behavior
		from a drop down list.)
		*/
		private function onMasterClick(evt:MouseEvent):void {
			if(this._dropDownList.visible)
				toggleDropDown();
		}
		
	} //class
} //package
