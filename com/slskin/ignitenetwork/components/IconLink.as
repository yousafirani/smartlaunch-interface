/*
IconLink.as
A DisplayObject with a UILoader and a url. The url is display
when hovering over the icon and the the navigateToUrl method is
called when the icon is clicked on.
*/
package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import fl.containers.UILoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.IOErrorEvent;
	import com.slskin.ignitenetwork.Main;
	
	public class IconLink extends MovieClip 
	{
		/* Constants */
		private const ICON_SIZE:Number = 24;
		private const TLF_PADDING:Number = 5;
		
		/* Member fields */
		private var urlReq:URLRequest;
		private var iconPath:String;
		private var alias:String;
		
		public function IconLink(alias:String, url:String, iconPath:String) 
		{
			this.urlReq = new URLRequest(url);
			this.iconPath = iconPath;
			this.alias = alias;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/*
		onAdded
		Handler for added to stage event.
		*/
		private function onAdded(evt:Event):void 
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//hide hint field
			this.hintTLF.visible = false;
			this.corner.visible = false;
			this.missingIcon.visible = false;

			//use hand cursor on iconLoader
			with(this.iconLoader)
			{
				//listen for load error
				addEventListener(IOErrorEvent.IO_ERROR, onIconLoadError);
				
				//load icon
				load(new URLRequest(iconPath));
				
				buttonMode = true;
				useHandCursor = true;
				
				//set listeners for rollOver and rollOut
				addEventListener(MouseEvent.ROLL_OVER, onIconRollOver);
				addEventListener(MouseEvent.ROLL_OUT, onIconRollOut);
				addEventListener(MouseEvent.CLICK, onIconClick);
				
			}
		}
		
		/* Event listeners */
		private function onIconRollOver(evt:MouseEvent):void 
		{
			this.hintTLF.text = alias;
			this.hintTLF.width = this.hintTLF.textWidth + TLF_PADDING;
			this.hintTLF.visible = true;
			this.corner.visible = true;
		}
		
		private function onIconRollOut(evt:MouseEvent):void 
		{
			this.hintTLF.visible = false;
			this.corner.visible = false;
			this.hintTLF.text = "";
			this.hintTLF.width = this.hintTLF.textWidth;
		}
		
		private function onIconClick(evt:MouseEvent):void {
			navigateToURL(urlReq);
		}
		
		/*
		onIconLoadError
		If the icon file is not found or there is
		an IOError.
		*/
		private function onIconLoadError(evt:IOErrorEvent):void
		{
			var main:Main = (root as Main); //reference main doc class
			main.debugger.write(evt.toString());
			main.log(evt.text);
			//show default icon
			this.missingIcon.visible = true;
		}
		
	} //class
} //package
