/* Utility class for strings */
package com.slskin.ignitenetwork.util
{
	public class Strings
	{
		public function Strings(){}
		
		/**
		 Removes all whitespace characters from the beginning and end
		 of the specified string.
		 
		 @param str The String whose whitespace should be trimmed. 
		 
		 @return Updated String where whitespace was removed from the 
		 beginning and end. 
		 */
		public static function trim(str:String):String
		{
			var startIndex:int = 0;
			while (isWhitespace(str.charAt(startIndex)))
				++startIndex;
	
			var endIndex:int = str.length - 1;
			while (isWhitespace(str.charAt(endIndex)))
				--endIndex;
	
			if (endIndex >= startIndex)
				return str.slice(startIndex, endIndex + 1);
			else
				return "";
		}
    
		/**
		 Removes all whitespace characters from the beginning and end
		 of each element in an Array, where the Array is stored as a String. 
		 
		 @param value The String whose whitespace should be trimmed. 
		 
		 @param separator The String that delimits each Array element in the string.
		 
		 @return Updated String where whitespace was removed from the 
		 beginning and end of each element. 
		 */
		public static function trimArrayElements(value:String, delimiter:String):String
		{
			if (value != "" && value != null)
			{
				var items:Array = value.split(delimiter);
				
				var len:int = items.length;
				for (var i:int = 0; i < len; i++)
				{
					items[i] = Strings.trim(items[i]);
				}
				
				if (len > 0)
				{
					value = items.join(delimiter);
				}
			}
			
			return value;
		}

		/**
		 Returns <code>true</code> if the specified string is
		 a single space, tab, carriage return, newline, or formfeed character.
		 
		 @param str The String that is is being queried. 
		 
		 @return <code>true</code> if the specified string is
		 a single space, tab, carriage return, newline, or formfeed character.
		 */
		public static function isWhitespace(character:String):Boolean
		{
			switch (character)
			{
				case " ":
				case "\t":
				case "\r":
				case "\n":
				case "\f":
					return true;
	
				default:
					return false;
			}
		}
			
		/*
		substitue
		Substitutes "{n}" tokens within the specified string 
		with the respective arguments passed in.
		
		@param String - The string to make substitutions in. This string can contain special tokens of the form {n}, 
		where n is a zero based index, that will be replaced with the additional parameters found at that index if specified.
		
		 @param ... rest — Additional parameters that can be substituted in the str parameter at each {n} location, 
		where n is an integer (zero based) index value into the array of values specified. 
		If the first parameter is an array this array will be used as a parameter list. 
		This allows reuse of this routine in other methods that want to use the ... rest signature. For example
		*/
		public static function substitute(str:String, ... rest):String
		{
			// Replace all of the parameters in the msg string.
			var len:uint = rest.length;
			var args:Array;
			if (len == 1 && rest[0] is Array)
			{
				args = rest[0] as Array;
				len = args.length;
			}
			else
			{
				args = rest;
			}

			for (var i:int = 0; i < len; i++)
			{
				str = str.replace(new RegExp("\\{" + i + "\\}","g"), args[i]);
			}

			return str;
		}
		
		/*
		correctCase
		Returns the input string with all but the first character
		in lowercase.
		*/
		public static function correctCase(str:String):String
		{
			if(str == null) return "";
			return str.charAt(0).toUpperCase() + str.substr(1, str.length-1).toLowerCase();
		}

	}//class
}//package