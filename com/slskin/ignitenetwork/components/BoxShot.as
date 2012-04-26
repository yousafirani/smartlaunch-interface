package com.slskin.ignitenetwork.components 
{
	import flash.display.MovieClip;
	import com.slskin.ignitenetwork.apps.Application;
	
	public class BoxShot extends MovieClip 
	{
		/* Member fields */
		private var app:Application; //application that this boxshot represents
		
		public function BoxShot(app:Application) 
		{
			this.app = app;
		}
		
	} //class
} //package
