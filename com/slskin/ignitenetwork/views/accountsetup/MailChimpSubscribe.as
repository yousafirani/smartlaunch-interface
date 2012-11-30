/**
 * MailChimpSubscribe.as
 * A simple wrapper class for the mailchimp API v1.3. 
 * Makes an XMP-RPC call to listSubscribe method using the given
 * api key, data center, and list ID.
 * 
 * Additionally, the following MERGE tags are possible: 
 * FNAME, LNAME, BDAY, and SLUSERNAME.
 *
 * MC API URL:  http: // <dc>.api.mailchimp.com/1.3/?method=SOME-METHOD&[other parameters]
 * 
 * The method this class uses is listSubsribe which is defined as: 
 * 
 * listSubscribe(string apikey, string id, string email_address, array merge_vars, string email_type,
 * bool double_optin, bool update_existing, bool replace_interests, bool send_welcome)
 * 
 * More Info Here:  http: // apidocs.mailchimp.com/api/1.3/
 */
package com.slskin.ignitenetwork.views.accountsetup  
{
	import com.slskin.ignitenetwork.util.Strings;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.events.Event;
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.EventDispatcher;
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.DateTimeStyle;
	import flash.globalization.LocaleID;
	import flash.net.URLLoader;
	
	public class MailChimpSubscribe extends EventDispatcher
	{
		/* Constants */
		private const BASE_URL: String = "http://{0}.api.mailchimp.com/1.3/?output=xml&method=listSubscribe";
		private const DEFAULT_DATACENTER: String = "us1";
		
		private var _apiKey: String; // takes the form [key]-[dc]
		private var _listID: String; // the id of the mailing list
		private var _dataCenter: String; // determined based on apikey
		private var _doubleOptin: Boolean; // email verification of opt-in
		private var apiurl: String; // stores the url used to make the request

		public function MailChimpSubscribe(key: String, listID: String, doubleOptin: Boolean = false) 
		{
			this._apiKey = key;
			this._listID = listID;
			this._doubleOptin = doubleOptin;
			
			// split the datacenter out of the api key
			var keySplit: Array = key.split("-");
			if (keySplit.length != 2)
			{
				trace("WARNING:  Your MailChimp API key is missing datacenter information. Are you sure you have the correct api key?");
				this._dataCenter = this.DEFAULT_DATACENTER;
			}
			else
				this._dataCenter = keySplit[1];
			
			this.apiurl = Strings.substitute(this.BASE_URL, _dataCenter);
		}
		
		/**
		 * Sends a request to the mailchimp server to add a new subscription.
		 * email: String - The email address of the new subscription.
		 * fname: String - optional FNAME merge var.
		 * lname: String - option LNAME merge var.
		 * bday: Date - optional birthday merge var.
		 * slusername: String - option slusername merge var.
		 */
		public function subscribe(email: String, fname: String = "", lname: String = "", bday: Date = null, slusername: String = "")
		{
			var vars: String = Strings.substitute("apikey={0}&id={1}", this._apiKey, this._listID);
			vars = vars.concat("&email_address=" + (email == null ? "" :  email));
			vars = vars.concat("&double_optin=" + this._doubleOptin);
			vars = vars.concat("&merge_vars[FNAME]=" + (fname == null ? "" :  fname));
			vars = vars.concat("&merge_vars[LNAME]=" + (lname == null ? "" :  lname));
			vars = vars.concat("&merge_vars[SLACCOUNT]=" + (slusername == null ? "" :  slusername));
			if (bday != null)
			{
				var df: DateTimeFormatter = new DateTimeFormatter(LocaleID.DEFAULT);
				df.setDateTimePattern("MM/dd");
				vars = vars.concat("&merge_vars[BDAY]=" + df.format(bday));
			}
			
			var urlVars: URLVariables = new URLVariables(vars);
			var req: URLRequest = new URLRequest(this.apiurl);
			req.data = urlVars;
			req.method = URLRequestMethod.POST;
			
			// trace(this.apiurl, urlVars.toString());
			var loader: URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onRequestComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onRequestError);
			loader.load(req);
		}
		
		/**
		 * Check the status of the subscribe and dispatch an event accordingly.
		 */
		private function onRequestComplete(evt: Event): void 
		{
			var resp: XML = XML(evt.target.data);
			if (resp.@type == "array")
			{
				var errorEvt: ErrorEvent = new ErrorEvent(ErrorEvent.ERROR, false, false, resp.error);
				this.dispatchEvent(errorEvt);
			}
			else if (resp.@type == "boolean") {
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		private function onRequestError(evt: IOErrorEvent): void {
			this.dispatchEvent(evt);
		}
	} // class
} // package
