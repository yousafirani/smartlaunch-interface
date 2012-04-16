/*
Asteroid.as
Maintains a list of all asteroids currently on Stage
*/

package com.slskin.ignitenetwork.asteroids 
{
	import flash.events.*; 
	import flash.display.DisplayObjectContainer;  
	
	public class Asteroid extends SpaceObject 
	{
		/* Constants */
		static const NO_ASTEROIDS:String = "No Asteroids";
		static const MINIMUM_SCALE:Number = .3; //when asteroids blow up don't create asteroids smaller than this scale
		
		/* Member fields */
		public static var dispatcher:EventDispatcher = new EventDispatcher();
		static var allAsteroids:Array = new Array(); // a list of all asteroids that are on stage - used for collision testing
		private static var _numPieces = 3;
		
		public function Asteroid( scale:Number = 1) {
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedAsteroid);
		}
		
		// blowUp will create smaller asteroids if they are not too small
		public override function blowUp() 
		{
			//add smaller children to the stage if the asteroid is greater than the scale
			//check scaleX or scaleY which are the same
			if(this.scaleX > Asteroid.MINIMUM_SCALE)
			{
				var newScale:Number = this.scaleX * .5; //reduce the scale at a rate
				
				//is our scale still in bounds?
				if(newScale < Asteroid.MINIMUM_SCALE) newScale = Asteroid.MINIMUM_SCALE;
				
				SpaceObject.createSpaceObjects(stage, Asteroid, _numPieces, newScale, this.x, this.y, this.width / 2, this.width / 2, 0, 0, 5, 10, 0);
			}
				
			
			//remove the bigger asteroid
			stage.removeChild(this);
			
			//play explode sounds
			var explodeSound = new Explode1Sound();
			explodeSound.play();
		}
		
		
		//called when the asteroid is added to stage
		public function onAddedAsteroid( e:Event ) 
		{
			Asteroid.allAsteroids.push(this);
			//see when its removed
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedAsteroid);
		}
				
		// when an asteroid is removed from stage, it should be removed 
		// from the list of asteroids on stage
		public function onRemovedAsteroid( e:Event ) 
		{
			Asteroid.allAsteroids.splice( allAsteroids.indexOf(this), 1);
			
			//check if allAsteroids is empty
			if(Asteroid.allAsteroids.length == 0)
				stage.dispatchEvent(new Event(Asteroid.NO_ASTEROIDS));
		}
				
	} //class
} //package
