/*
SpaceShip.as
Defines the behavior of the SpaceShip object linked in the
library.
*/
package com.slskin.ignitenetwork.asteroids 
{
	
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.utils.Timer;
	
	public class SpaceShip extends SpaceObject {
		
		static const ACCELERATE:Number = .08;  // pixels per frame
		static const ROTATERATE:Number = 8;   // degrees per frame
		static const DIE:String = "Die";
		
		public function SpaceShip ()  {
			this.addEventListener(Event.ADDED_TO_STAGE, this.onAddedSpaceShip);
			this.addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedSpaceShip);
		}

		
		public override function blowUp() 
		{
			//dispatch a DIE event
			this.dispatchEvent(new Event(DIE));
			
			//remove listeners
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDownSpaceShip);
			stage.removeEventListener(KeyboardEvent.KEY_UP, this.onKeyUpSpaceShip);
			
			parent.removeChild(this);
		}
		
		public function onAddedSpaceShip(e:Event) 
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDownSpaceShip);
			stage.addEventListener(KeyboardEvent.KEY_UP, this.onKeyUpSpaceShip);
		}
		
		public function onRemovedSpaceShip(e:Event) 
		{
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDownSpaceShip);
			stage.removeEventListener(KeyboardEvent.KEY_UP, this.onKeyUpSpaceShip);
		}

		
		public function onKeyDownSpaceShip(e: KeyboardEvent)
		{
			
				
			//which key did we press
			switch(e.keyCode)
			{
				//thrust
				case 38:
					this.acceleration = SpaceShip.ACCELERATE;
					thrust.gotoAndPlay(2);
					break;
				//turn left
				case 37:
					this.deltaRotate = -SpaceShip.ROTATERATE;
					break;
				//turn right
				case 39:
					this.deltaRotate = SpaceShip.ROTATERATE;
					break;
				//shoot
				case 32:
					//this.fireBullet();
					break;
			}
		}
		
		public function onKeyUpSpaceShip( e: KeyboardEvent ) {
			//stop the ship from moving on keyup
			switch(e.keyCode)
			{
				//thrust
				case 38:
					this.acceleration = 0;
					break;
				//turn left or right
				case 37:
				case 39:
					this.deltaRotate = 0;
					break;
				//shoot
				case 32:
					this.fireBullet();
					break;
			}
		} 
		
		public function fireBullet() 
		{
			var fireSound = new FireSound();
			fireSound.play();
			
			//create bullet
			var bullet:Bullet = new Bullet();
			var angleInRadians = this.rotation * Math.PI / 180;
			var fireX = Bullet.FIRE_VELOCITY * Math.cos (angleInRadians);
			var fireY = Bullet.FIRE_VELOCITY * Math.sin (angleInRadians);
			
			//add the velocity of the spaceShip to bullet space ship
			bullet.velX = this.velX + fireX;
			bullet.velY = this.velY + fireY;
			
			//set x and y
			bullet.x = this.x + 2*fireX;
			bullet.y = this.y + 2*fireY;
			
			//set life space
			bullet.setLifeSpan( Bullet.LIFESPAN );
			stage.addChild(bullet);
		}
		
					
	} // class
} // package
