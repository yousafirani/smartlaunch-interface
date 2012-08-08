/**
 * Defines a custom TextInput with a field hint
 * and the ability to display errors.
 */
package com.slskin.ignitenetwork.components
{
	import flash.display.MovieClip;
	import fl.text.TLFTextField;
	import flash.events.FocusEvent;
	import flash.events.Event;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.display.InteractiveObject;
	import flash.events.KeyboardEvent;
	import flashx.textLayout.formats.TLFTypographicCase;
	import com.slskin.ignitenetwork.Language;
	import flash.events.TextEvent;
	import flash.filters.GlowFilter;

	public class TextInput extends MovieClip
	{
		/* Events */
		public static const FIELD_ERROR: String = "FieldError";
		public static const FIELD_VALID: String = "FieldValid";
		public static const VALIDATION_CHANGE: String = "ValidationChange";
		
		/* Consts */
		private const FIELD_WIDTH: Number = 150;
		private const ERRORFIELD_PADDING: uint = 10;
		private const MAX_CHARS: uint = 50;
		private const BORDER_DEFAULT_COLOR: uint = 0x333333;
		private const BORDER_ERROR_COLOR: uint = 0x990000;
		private const DEFAULT_REQUIRED_TEXT: String = "Required";
		
		private var _hint: String; // stores the field hint string
		private var _field: TLFTextField; // stores a reference to the underlying tlf.
		private var _hasError: Boolean; // indicates that there is an error on the field.
		private var _required: Boolean; // indicates if this field is required.
		private var requiredText: String; // Translated string for "Required"
		private var errorField: MovieClip; // holds a reference to the error field
		private var validator: Function; // stores the validator function.
		private var hintTween: Tween; // Tween used to fade in / out hint field.
		private var errorTween: Tween; // Tween used to fade in / out error field.
		
		public function TextInput(hint: String = "Field", v: Function = null) 
		{
			this.hint = hint;
			this.validator = v;
			this.required = false;
			this.requiredText = Language.translate("Required", this.DEFAULT_REQUIRED_TEXT);
		
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/* Setters */
		public function set hint(s: String): void 
		{ 
			this._hint = s;
			if(this.fieldHint != null)
				this.fieldHint.text = s;
		}
		
		/* Correct an issue with how the TLF tabs */
		public override function set tabIndex(index: int): void
		{
			if(field != null)
				InteractiveObject(this.field.getChildAt(1)).tabIndex = index;
		}
		public function set required(b: Boolean): void { this._required = b; }
		public function set field(f: TLFTextField): void { this._field = f; }
		public function set fieldValidator(f: Function): void { this.validator = f; }
		public function set displayAsPassword(bool: Boolean): void { this.field.displayAsPassword = bool; }
		public function set text(s: String): void 
		{ 
			this.field.text = s; 
			this.field.textFlow.flowComposer.updateAllControllers(); 
		}
		
		public function set upperCase(toUpper: Boolean): void 
		{
			if(toUpper)
				this.field.textFlow.typographicCase = TLFTypographicCase.UPPERCASE;
			else
				this.field.textFlow.typographicCase = TLFTypographicCase.DEFAULT;
		}
		
		
		/* Getters */
		public function get field(): TLFTextField 
		{ 
			if(this._field == null)
				return this.tlf;
			else
				return this._field; 
		}
		public function get hint(): String { return this._hint; }
		public function get text(): String { return this.field.text; }
		public function get hasError(): Boolean { return this._hasError; }
		public function get required(): Boolean { return this._required; }
		// override width sometimes the tlf would cause width to be longer than neccessary.
		public override function get width(): Number { return this.FIELD_WIDTH; }
		
		/*
		Event listener for added to stage event.
		*/
		private function onAdded(evt: Event): void
		{
			this.field = this.tlf; // reference the tlf in the TextField mc.
			this.errorField = this.ef; // reference the errorfield obj in the mc.
			this.errorField.tlf.autoSize = "left";
			
			// see if the field is enabled
			if(this.enabled)
				enable();
			else
				disable();
			
			// setup max chars
			if(this.field.maxChars == 0)
				this.field.maxChars = MAX_CHARS;
			
			// hide hint if text is set.
			if(this.text != "")
				this.fieldHint.alpha = 0;
			else
				this.text = "";
			
			// hide the error field
			this.errorField.visible = false; 
			this.errorField.tabChildren = false;
			
			// removing on error field children
			this.fieldHint.text = this.hint;
			InteractiveObject(this.fieldHint.getChildAt(1)).tabEnabled = false;

			// listen for field events
			this.field.addEventListener(FocusEvent.FOCUS_IN, onFieldFocusIn);
			this.field.addEventListener(FocusEvent.FOCUS_OUT, onFieldFocusOut);
			
			// validate on change
			this.field.addEventListener(Event.CHANGE, validate);
		}
		
		/**
		 * Dim the field hint.
		 */
		private function onFieldFocusIn(evt: FocusEvent): void
		{	
			if(this.isEmpty())
				this.hintTween = new Tween(this.fieldHint, "alpha", Regular.easeOut, this.fieldHint.alpha, .4, .2, true);
			
			if(this.hasError)
				this.errorField.visible = true;
				
			// listen for field change events
			this.field.addEventListener(Event.CHANGE, onFieldChange); 
		}
		
		/**
		 * Listens for field change event and updates 
		 * the field state.
		 */
		private function onFieldChange(evt: Event)
		{
			if(!this.isEmpty())
				this.fieldHint.alpha = 0;
			else 
				this.fieldHint.alpha = 1;
			
			// check if we the field is required
			this.checkRequired();
		}
		
		/**
		 * Handles focus out event.
		 */
		private function onFieldFocusOut(evt: FocusEvent): void
		{
			var f: TLFTextField = evt.currentTarget as TLFTextField;
			
			// show hint
			if(f.text.length <= 0)
				this.hintTween = new Tween(this.fieldHint, "alpha", Regular.easeIn, this.fieldHint.alpha, 1, .5, true);
			
			// remove field change event handler
			this.field.removeEventListener(Event.CHANGE, onFieldChange);
			
			// check if we the field is required
			checkRequired();
			this.errorField.visible = false;
		}
		
				
		/**
		 * Transforms the color of the border around the field.
		 */
		private function highlight(color: uint, filterArr: Array = null): void 
		{
			var c: ColorTransform = new ColorTransform();
			c.color = color;
			this.border.transform.colorTransform = c;
			this.border.filters = filterArr;
		}
		
		
		/**
		 * Checks to see if the field is required and updates the
		 * error field if it is required and empty.
		 */
		public function checkRequired(): void
		{
			// isEmpty && required show error
			if(this.required)
			{
				if(this.isEmpty())
					this.showError(this.requiredText);
				else if(this.errorField.tlf.text == this.requiredText)
					this.hideError();
			}
		}
		
		/**
		 * A wrapper to access the interactive object under the tlf and 
		 * add the key down listener.
		 */
		public function addKeyDownListener(callback: Function): void {
			InteractiveObject(this.field.getChildAt(1)).addEventListener(KeyboardEvent.KEY_DOWN, callback);
		}
		
		/** 
		 * validates the field based on the validator. Also used as an event 
		 * handler for Event.CHANGE on the field.
		 */
		public function validate(evt: Event = null): void
		{
			if(this.validator == null) return;
			if(this.isEmpty()) return;
			
			var error: String = null;
			error = validator(this.text);
			
			if(error != null)
				this.showError(error);  
			else
				this.hideError();
		}
		
		/**
		 * Displays the error field.
		 */
		public function showError(error: String): void
		{
			// change the border to red!
			var glowFilter: Array = new Array(new GlowFilter(this.BORDER_ERROR_COLOR,1,2,2,2,5));
			this.highlight(this.BORDER_ERROR_COLOR, glowFilter);
			
			// set error
			this.errorField.tlf.text = error;
			
			// position the field correctly
			this.errorField.x = this.border.width +(ERRORFIELD_PADDING/2);
			
			// if the field is not visible
			if(!errorField.visible)
			{
				this.errorField.alpha = 0;
				this.errorField.visible = true;
				this.errorTween = new Tween(this.errorField, "alpha", Strong.easeIn, this.errorField.alpha, 1, .5, true);
			}
			
			// TO DO:  Create a custom event and pass around hasError
			// as part of the event to avoid using this tmpHasError.
			var tmpHasError: Boolean = this.hasError;
				
			this._hasError = true;
			
			// check to see if we have changed validation
			if(tmpHasError != this.hasError)
				this.dispatchEvent(new Event(TextInput.VALIDATION_CHANGE));
			
			// dispatch field error event
			this.dispatchEvent(new Event(TextInput.FIELD_ERROR));
		}
		
		/**
		 * Hides the error field.
		 */
		public function hideError(): void
		{
			// change the border to the default color
			this.highlight(this.BORDER_DEFAULT_COLOR);
			
			// hide error field
			this.errorField.tlf.text = "";
			this.errorField.x = this.border.width;
			this.errorField.visible = false;
				
			// TO DO:  Create a custom event and pass around hasError
			// as part of the event to avoid using this tmpHasError.
			var tmpHasError: Boolean = this.hasError;
			
			// reset error flag
			this._hasError = false;
			
			// check to see if we have changed validation
			if(tmpHasError != this.hasError)
				this.dispatchEvent(new Event(TextInput.VALIDATION_CHANGE));
			
			// dispatch field valid event
			this.dispatchEvent(new Event(TextInput.FIELD_VALID));
		}
		
		/**
		 * Disable the field. Make the underlying tlf 
		 * unaccessible and the field appear disabled.
		 */
		public function disable(): void
		{
			this.alpha = .2;
			this.enabled = false;
			if(field != null)
			{
				this.field.selectable = false;
				this.field.type = "dynamic";
				InteractiveObject(this.field.getChildAt(1)).tabEnabled = false;
			}
		}
		
		/**
		 * Enable the field. Reverse the affects of
		 * disable().
		 */
		public function enable(): void
		{
			this.alpha = 1;
			this.enabled = true;
			
			if(field != null)
			{
				this.field.selectable = true;
				this.field.type = "input";
				InteractiveObject(this.field.getChildAt(1)).tabEnabled = true;
			}
		}

		/**
		 * clears the text in the field and the error on the field.
		 */
		public function clearField(): void
		{
			stage.focus = null;
			this.field.text = "";
			this.field.textFlow.flowComposer.updateAllControllers();
			this.hideError();
			this.fieldHint.alpha = 1;
		}
		
		/**
		 * Returns true if the field has no text.
		 */
		public function isEmpty(): Boolean {
			return (this.field.text.length == 0);
		}
	}// class
}// package
