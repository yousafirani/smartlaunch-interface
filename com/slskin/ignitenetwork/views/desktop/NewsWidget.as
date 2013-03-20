/**
 * NewsWidet.as
 * Loads and parses news from twitter and the SL client. Items are loaded from twitter
 * only if showTweetsInNews is set in the config.xml. The tweets are merged with the news
 * data from SmartLaunch based on date in descending order. The news is then displayed in a
 * fl.container.ScrollPane that is configured with a custom skin.
 */
package com.slskin.ignitenetwork.views.desktop 
{
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import org.httpclient.*;
	import org.httpclient.http.Get;
	import org.httpclient.events.*;
	import com.adobe.serialization.json.JSON;
	import com.adobe.net.URI;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import fl.containers.ScrollPane;
	import flash.system.Security;
	import com.slskin.ignitenetwork.*;
	import com.slskin.ignitenetwork.events.SLEvent;
	import com.slskin.ignitenetwork.util.Strings;
	import com.slskin.ignitenetwork.views.desktop.DashBoardView;
	import com.slskin.ignitenetwork.components.NewsItem;
	import flash.utils.ByteArray;
	
	public class NewsWidget extends MovieClip 
	{
		/* Constants */
		private const TWITTER_API: String = "https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name={0}&count={1}&trim_user=true&exclude_replies={2}";
		private const TWEET_URL: String = "https://twitter.com/{0}/status/{1}";
		private const TWEET_COUNT: int = 15; // number of tweets to load
		private const PADDING: Number = 12; // padding in between news items
		private const LEFT_PADDING: Number = 5; // left padding for each news item
		
		/* Member Fields */
		private var main: Main; // stores a reference to the main doc class
		
		public function NewsWidget() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/**
		 * Handler for added to stage event.
		 */
		private function onAdded(evt: Event): void
		{
			// set reference to main
			main = (root as Main);
			
			// show loader
			this.loader.visible = true;
			
			// listen for parent tween finish
			(parent as DashBoardView).addEventListener(TweenEvent.MOTION_FINISH, onTweenComplete);
			
			// translate title
			this.titleTLF.text = Language.translate("News_And_Events", "News and Events"); 
			
			// configure ScrollPane
			this.setPaneStyle();
		}
		
		/**
		 * On parent tween complete, start the news load process. The 
		 * RPC to load the tweets can cause the tween to skip for a second, waiting for the 
		 * the tween to complete solves this issue.
		 */
		private function onTweenComplete(evt: TweenEvent): void
		{
			// remove tween complete event listener
			(parent as DashBoardView).removeEventListener(TweenEvent.MOTION_FINISH, onTweenComplete);
			
			// listen for UpdateNewsAndEvents from the model
			main.model.addEventListener(SLEvent.UPDATE_NEWS_EVENTS, loadNews);
			
			// load the news
			this.loadNews();
		}
		
		/**
		 * Starts loading the news from twitter or the SL server
		 * or both.
		 */
		private function loadNews(evt: SLEvent = null)
		{
			// dim current news if it is loaded
			if (this.newsPane.source is DisplayObject)
				this.newsPane.source.alpha = .5;
			
			// show loader
			this.loader.visible = true;
			
			// load twitter if it's set in config.xml
			if (main.config.Social.@showTweetsInNews == "true") 
			{
				var screenName: String = main.config.Social.@twitterScreenName;
				var excludeReplies: Boolean = !(main.config.Social.@showRepliesInNews == "true");
				var url: String = Strings.substitute(TWITTER_API, screenName, TWEET_COUNT, String(excludeReplies));
				
				var client: HttpClient = new HttpClient();
				var listener: HttpDataListener = new HttpDataListener();
				var uri: URI = new URI(url);      
				var request: HttpRequest = new Get();
				request.addHeader("Authorization", main.config.Social.@twitterAuthHeader);
				request.header.remove("Connection"); // let the tfe negotiate connection settings
				listener.onDataComplete = function(event: HttpResponseEvent, data: ByteArray): void {
					data.position = 0; // reset buffer read/write position
					onTweetLoadComplete(data.readUTFBytes(data.length));
				};
				client.request(uri, request, -1, listener);
			}
			else
			{
				var slNews: Array = this.parseSLNews(main.model.getProperty("UpdateNewsAndEvents"));
				this.addNewsItems(slNews);
				this.loader.visible = false;
			}
		}
		
		/**
		 * Parse JSON and merge tweets with SL news.
		 */
		private function onTweetLoadComplete(rawJson: String): void
		{
			// based on the api, the expected json root type should be
			// an array.
			var parsedJson: Array = new Array();
			try {
				parsedJson = JSON.decode(rawJson);
			} catch (e: Error) {
				main.log("Error parsing twitter json: " + e.message);
			}
			
			var tweets: Array = this.parseTweets(parsedJson);
			var slNews = this.parseSLNews(main.model.getProperty("UpdateNewsAndEvents"));

			var merged: Array = this.mergeNewsSources(tweets, slNews);
			this.addNewsItems(merged);
			
			this.loader.visible = false;
		}
		
		/**
		 * Parses the user_timeline json  loaded from the twitter API and
		 * creates NewsItem objects based on each tweet.
		 * @param timeline - The json object loaded from the twitter API v1.1.
		 * @return - An array of NewsItem objects.
		 */
		private function parseTweets(timeline: Array): Array
		{
			var numTweets: int = timeline.length;
			var screenName: String = main.config.Social.@twitterScreenName;
			var tweet: NewsItem;
			var result: Array = new Array();
			
			for (var i: uint = 0; i < numTweets; i++)
			{
				tweet = new NewsItem();
				tweet.contentText = timeline[i].text;
				tweet.datePosted = new Date(Date.parse(timeline[i].created_at));
				tweet.url = Strings.substitute(TWEET_URL, screenName, timeline[i].id_str);
				tweet.isTweet = true;
				result.push(tweet);
			}
			
			return result;
		}
		
		/**
		 * Parses the news string loaded from SL. This source of news can be set
		 * in the SL administrator. Takes an SL formatted string and parses the news
		 * elements.
		 * @param newsStr - An SL news and events formatted string.
		 * @return - An array with NewsItems representing each SL news item.
		 */
		private function parseSLNews(newsStr: String): Array
		{
			if (newsStr == null || newsStr.length == 0)
				return new Array()
			
			var SLNewsData: Array = newsStr.split(main.model.DIM);
			var itemData: Array; // stores data for each news item from SLNewsData
			var results: Array = new Array();
			
			var newsItem: NewsItem;
			for (var i: uint = 0; i < SLNewsData.length; i++)
			{
				// if empty string
				if (SLNewsData[i].length == 0) continue;

				// split news string into sub array
				itemData = SLNewsData[i].split(main.model.DlMSep);
				
				// create NewsItem object based on itemData
				newsItem = new NewsItem();
				newsItem.datePosted = new Date(Date.parse(itemData[0]));
				newsItem.contentTitle = (itemData[1] == null ? "" :  itemData[1] + " ");
				
				// concat title and text in the same tlf
				newsItem.contentText = (itemData[1] == null ? "" :  itemData[1] + " ") + 
										(itemData[2] == null ? "" :  itemData[2]);
				
				newsItem.url = (itemData[3] == null ? "" :  itemData[3]);
				newsItem.isTweet = false;
				
				// store NewsItem
				results.push(newsItem);
			}
			
			return results;
		}
		
		/**
		 * Takes two arrays of NewsItems and merges them in descending order based on their
		 * dates.
		 * @return A new array with the NewsItems merged.
		 */
		private function mergeNewsSources(a: Array, b: Array): Array
		{
			var aIndex: uint = 0;
			var bIndex: uint = 0;
			
			var results: Array = new Array();
			
			// merge while we have items to merge
			// in both arrays.
			while( (aIndex < a.length) && (bIndex < b.length) )
			{
				// if they are equal or a[aIndex] is greater
				if (compareDates(a[aIndex].datePosted, b[bIndex].datePosted) <= 0)
					results.push(a[aIndex++]);
				else
					results.push(b[bIndex++]);
			}
			
			// check for any remaining items in a
			while(aIndex < a.length)
				results.push(a[aIndex++]);
			
			// check for any remaining items in b
			while(bIndex < b.length)
				results.push(b[bIndex++]);
			
			return results;
		}
		
		/** 
		 * Adds news item to ScrollPane.
		 * @param newsItems An array of NewsItem objects.
		 */
		private function addNewsItems(newsItems: Array): void
		{
			// parent clip to store the NewsItems in a DisplayObject
			var itemHolder: MovieClip = new MovieClip();
			var yPos: Number = PADDING; // stores the yPos for each new news item.
			for (var i: int = 0; i < newsItems.length; i++)
			{
				// add item to itemHolder
				itemHolder.addChild(newsItems[i]);
				newsItems[i].x = LEFT_PADDING;
				newsItems[i].y = yPos;
				
				// calculate new yPos
				yPos += newsItems[i].contentTLF.y + newsItems[i].contentTLF.height + (PADDING);
			}
			
			// add some bottom padding to itemHolder just in case. 
			// Sometimes the elements were getting cut off by a couple pixels.
			var paddingSprite: Sprite = new Sprite();
			paddingSprite.graphics.beginFill(0xFFFFFF);
			paddingSprite.graphics.drawRect(PADDING,yPos,20,20);
			paddingSprite.graphics.endFill();
			paddingSprite.visible = false;
			itemHolder.addChild(paddingSprite);
			
			// set scroll pane source as itemHolder
			this.newsPane.source = itemHolder;
		}
		
		/**
		 * Configure the ScrollPane with a custom skin.
		 */
		private function setPaneStyle(): void
		{
			// set scrollPane scrollbar width
			this.newsPane.setStyle("scrollBarWidth", 8);
			
			// hide arrows
			this.newsPane.setStyle("scrollArrowHeight", 0);
			
			// setup track
			this.newsPane.setStyle("trackUpSkin", ScrollTrack_Invisible);
			this.newsPane.setStyle("trackOverSkin", ScrollTrack_Invisible);
			this.newsPane.setStyle("trackDownSkin", ScrollTrack_Invisible);
			
			// setup thumb
			this.newsPane.setStyle("thumbUpSkin", ScrollThumb_Up_Dark);
			this.newsPane.setStyle("thumbOverSkin", ScrollThumb_Up_Dark);
			this.newsPane.setStyle("thumbDownSkin", ScrollThumb_Up_Dark);
			
			// down arrow
			this.newsPane.setStyle("downArrowUpSkin", ArrowSkin_Invisible); 
			this.newsPane.setStyle("upArrowUpSkin", ArrowSkin_Invisible); 
		}
		
		/**
		 * Compares two dates and returns an integer depending on their relationship.
		 * Returns -1 if d1 is greater than d2.
		 * Returns 1 if d2 is greater than d1.
		 * Returns 0 if both dates are equal.
		 *
		 * @param d1 The date that will be compared to the second date.
		 * @param d2 The date that will be compared to the first date.
		 *
		 * @return An int indicating how the two dates compare.
		 */	
		private function compareDates(d1: Date, d2: Date): int
		{
			var d1ms: Number = d1.getTime();
			var d2ms: Number = d2.getTime();
			
			if (d1ms > d2ms)
				return -1;
			else if (d1ms < d2ms)
				return 1;
			else
				return 0;
		}
		
		public function onTwitterLoadError(evt: IOErrorEvent): void {
			this.main.log(evt.text);
		}
		
	} // class
} // package
