/**
 * AdsView
 * Loads and displays simple ads defined in config.xml under the footer.
 */
package com.slskin.ignitenetwork.views.desktop 
{
	import com.slskin.ignitenetwork.views.*;
	import com.slskin.ignitenetwork.events.SLEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import fl.containers.UILoader;
	import com.slskin.ignitenetwork.Main;
	import com.slskin.ignitenetwork.util.ArrayIterator;
	import flash.utils.Timer;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.events.TimerEvent;
	import flash.net.navigateToURL;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	
	public class AdsView extends SLView 
	{
		/* Constants */
		private const AD_WIDTH: Number = 608;
		private const AD_HEIGHT: Number = 50;
		private const LEFT_PADDING: Number = -93;
		private const TOP_PADDING: Number = 340;
		
		/* Private Fields */
		private var scrollTimer: Timer;
		private var currentAd: UILoader;
		private var currentLink: URLRequest;
		private var adPaths: Array;
		private var adIter: ArrayIterator;
		private var adSettings: XMLList;
		private var impressionData: URLVariables;
		
		public function AdsView() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/**
		 * Override width properties to reflect exact AD_WIDTH
		 */
		public override function get width(): Number {
			return this.AD_WIDTH;
		}
		
		/**
		 * Override height property to reflect exacth AD_HEIGHT;
		 */
		public override function get height(): Number {
			return this.AD_HEIGHT;
		}
		
		private function onAdded(evt: Event): void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			this.adSettings = new XMLList(this.main.config.adSettings);
			if (this.adSettings.length() == 0 || this.adSettings.@enabled == "false")
				return;
				
			// start at the bottom of the stage
			this.startPos = new Point(centerX, main.getStageHeight() + this.height);
			this.xPadding = this.LEFT_PADDING;
			this.yPadding = this.TOP_PADDING;
			this.startPos.x += this.xPadding;
			this.startPos.y += this.yPadding;
			this.moveToStart();
			
			var username: String = main.model.getProperty("Username", main.model.DATA_PATH);
			var age: Number = new Date().fullYear - Number(main.model.getProperty("Birthday_Year", main.model.DATA_PATH));
			var gender: String = main.model.getProperty("Sex", main.model.DATA_PATH) == "1" ? "m" : "f";
			this.impressionData = new URLVariables();
			this.impressionData.sl_username = username;
			this.impressionData.user_age = age;
			this.impressionData.gender = gender;
			
			// style container and add it to stage
			var adContainer: Sprite = new Sprite();
			adContainer.graphics.beginFill(0x333333, 1);
			adContainer.graphics.lineStyle(1, 0xFFFFFF, 1, true, "normal", CapsStyle.ROUND, JointStyle.ROUND); 
			adContainer.graphics.drawRoundRect(0, 0, this.width, this.height, 8);
			adContainer.graphics.endFill();
	
			// add glow
			var glow: GlowFilter = new GlowFilter(0x666666, 1, 6, 6, 1, 1, false, false);
			adContainer.filters = new Array(glow);
			adContainer.blendMode = BlendMode.MULTIPLY;
			this.addChild(adContainer);
			
			// configure UILoader
			this.currentAd = new UILoader();
			with (this.currentAd)
			{
				width = AD_WIDTH;
				height = AD_HEIGHT;
				scaleContent = true;
				maintainAspectRation = true;
				useHandCursor = true;
				buttonMode = true;
			}
			this.currentAd.addEventListener("click", onAdClick);
			
			// create mask for UILoader
			var mask: Sprite = new Sprite();
			mask.graphics.beginFill(0x333333, 1);
			mask.graphics.lineStyle(1, 0xFFFFFF, 1, true, "normal", CapsStyle.ROUND, JointStyle.ROUND); 
			mask.graphics.drawRoundRect(0, 0, this.width, this.height, 8);
			mask.graphics.endFill();
			this.currentAd.mask = mask;
			this.addChild(mask);
			this.addChild(this.currentAd);
			
			var adLoader = new URLLoader(new URLRequest(this.adSettings.adURL+"?"+Math.random()));
			adLoader.addEventListener(Event.COMPLETE, onAdsLoaded);
			
			this.showView();
		}
		
		private function onAdsLoaded(evt: Event): void
		{
			var ads: XML = new XML();
			try {
				ads = XML(evt.target.data);
			} catch (e: TypeError) {
				main.log("Failed to parse ad data: " + e);
			}
			
			var numAds: uint = ads.ad.length();
			this.adPaths = new Array();
			for (var i: uint = 0; i < numAds; i++) {
				this.adPaths.push(XML(ads.ad[i]));
			}
				
			this.adIter = new ArrayIterator(this.adPaths);
			
			// configure and create timer
			if (numAds > 1)
			{
				var timerDelay: Number = Number(adSettings.@autoScrollSeconds) * 1000;
				this.scrollTimer = new Timer(timerDelay);
				this.scrollTimer.addEventListener(TimerEvent.TIMER, onIntervalTick);
				this.scrollTimer.start();
			}
			
			this.loadNextImage();
		}
		
		private function loadNextImage(): void 
		{
			if (!this.adIter.hasNext())
				this.adIter.reset();
			
			var ad: XML = this.adIter.next();
			this.currentAd.load(new URLRequest(ad.@asset));
			
			// proxy ad href through impression the filter
			// and pass the meta-data via HTTP-POST.
			var req: URLRequest = new URLRequest(adSettings.impressionsURL);
			this.impressionData.ad_id = ad.@id;
			this.impressionData.redirect = ad.@href;
			req.data = this.impressionData;
			this.currentLink = req;
		}
		
		private function onAdClick(evt: Event): void {
			navigateToURL(this.currentLink, "_blank");
		}
		
		private function onIntervalTick(evt: Event): void {
			this.loadNextImage();
		}
	} //class
} //package
