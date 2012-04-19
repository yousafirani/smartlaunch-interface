/*
NewsItem.as
Represents an SL news item or a tweet. Used
by the NewsWidget class.
*/
package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import fl.text.TLFTextField;
	import flash.text.TextFormat;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.text.TextFieldAutoSize;
	import flash.text.Font;
	import com.slskin.ignitenetwork.fonts.*;
	
	public class NewsItem extends MovieClip 
	{ 
		/* Member Fields */
		private var _contentTitle:String = "";
		private var _contentText:String = "";
		private var _datePosted:Date;
		private var _url:String;
		private var _isTweet:Boolean;
		private var urlRegex:RegExp = new RegExp("^http[s]?\:\\/\\/([^\\/]+)\\/");
		
		//text formats
		private var titleFormat:TextFormat = new TextFormat("Tahoma", 14, 0x0080FF);
		private var rollOverFormat:TextFormat = new TextFormat("Tahoma", 12, 0xFFFFFF);
		private var defaultFormat:TextFormat =  new TextFormat("Tahoma", 12, 0xCCCCCC);
		
		public function NewsItem() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function test(evt:Event) { trace(evt); }
		
		/* Setters and Getters */
		public function set contentTitle(str:String):void {
			this._contentTitle = str;
		}
		
		public function set contentText(str:String):void 
		{
			this._contentText = str;
			this.contentTLF.text = str;
			//autosize contentTLF
			this.contentTLF.autoSize = TextFieldAutoSize.LEFT;
		}
		
		public function set datePosted(d:Date):void {
			this._datePosted = d;
			this.headerTLF.text = this._datePosted.toDateString();
		}
		
		public function get datePosted():Date {
			return this._datePosted;
		}
		
		public function set isTweet(b:Boolean):void {
			this._isTweet = b;
			if(!_isTweet) this.newsIcon.gotoAndStop(2);
		}
		
		public function set url(urlStr:String):void 
		{
			//validate url
        	var result:Object = urlRegex.exec(urlStr);
       		if (result != null || urlStr.length < 4096)
				this._url = urlStr;
		}
		
		
		/*
		onAdded
		Event handler for added to stage event.
		*/
		private function onAdded(evt:Event):void 
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			//highlight title
			this.contentTLF.setTextFormat(titleFormat, 0, this._contentTitle.length);
			this.contentTLF.setTextFormat(defaultFormat, this._contentTitle.length, this._contentText.length);
			
			//setup text link if a url is set
			if(this._url.length > 0)
			{
				this.contentTLF.buttonMode = true;
				this.contentTLF.useHandCursor = true;
				
				//listen for mouse events
				this.contentTLF.addEventListener(MouseEvent.ROLL_OVER, onNewsRollOver);
				this.contentTLF.addEventListener(MouseEvent.ROLL_OUT, onNewsRollOut);
				//(this.contentTLF as TLFTextField). = this._url;
				this.contentTLF.addEventListener(MouseEvent.CLICK, onNewsClick);
			}
		}
		
		/*
		onNewsRollOver
		Indicate that the user has rolled over by decorating the text
		*/
		private function onNewsRollOver(evt:MouseEvent):void {
			this.contentTLF.setTextFormat(rollOverFormat, this._contentTitle.length, this._contentText.length);
		}
		
		/*
		onNewsRollOut
		Indicate that the user has rolled off the news item by returning
		to the default color.
		*/
		private function onNewsRollOut(evt:MouseEvent):void {
			this.contentTLF.setTextFormat(defaultFormat, this._contentTitle.length, this._contentText.length);
		}
		
		/*
		onNewsClick
		Fetch the url with the default browser.
		*/
		private function onNewsClick(evt:MouseEvent):void {
			navigateToURL(new URLRequest(this._url), "_blank");
		}
		
		/*
		toString
		*/
		public override function toString():String {
			return this._datePosted.toDateString();
		}
		

	} //class
} //package
