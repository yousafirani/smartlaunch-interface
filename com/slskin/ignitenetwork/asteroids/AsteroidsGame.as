/*
AsteroidsGame.as
Manages initial object creation and collisions.
*/

package com.slskin.ignitenetwork.asteroids 
{
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.display.MovieClip;
	
	public class AsteroidsGame extends Sprite 
	{
		/* Constants */
		public const SHIP_WIDTH:Number = 24;
		public const SHIP_HEIGHT:Number = 18;
		public const NUM_ASTEROIDS:uint = 3;
		
		private var spaceShip:SpaceShip;
		
		public function AsteroidsGame()  {
			this.addEventListener(Event.ADDED_TO_STAGE, onGameAdded);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onGameRemoved);
		}
		
		/*
		startGame
		*/
		private function onGameAdded(evt:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onGameAdded);
			
			//create some asteroids at the start
			this.createStartAsteroids(NUM_ASTEROIDS);
			
			//create space ship
			this.createSpaceShip();
			
			//listen for enterFrame to check collisions
			this.addEventListener(Event.ENTER_FRAME, onEnterFrameCheckCollisions);
			
			//listen for no more asteroids
			stage.addEventListener(Asteroid.NO_ASTEROIDS, onNoAsteroidsMakeMore);
		}
		
		// checks for collisions between all objects
		public function onEnterFrameCheckCollisions( e:Event ) {
			
			var asteroid:Asteroid;
			var bullet:Bullet;
			//loop through all asteroids
			for(var i:uint = 0; i < Asteroid.allAsteroids.length; i++)
			{
				//get current bullet
				asteroid = Asteroid.allAsteroids[i];
				
				//trace(asteroid);
				//check collision with ship
				if(this.spaceShip.stage != null && this.spaceShip.hitTestObject(asteroid))
					this.spaceShip.blowUp();
					
				//loop for bullet and asteroids collision
				for(var j:uint = 0; j < Bullet.allBullets.length; j++)
				{
					bullet = Bullet.allBullets[j];
					
					//check for collision with asteroid and bullet
					if(asteroid.hitTestPoint(bullet.x, bullet.y, true))
					{
						//remove asteroid and bullet
						bullet.blowUp();
						asteroid.blowUp();
					}  	
				} //bullet asteroid collision
				
			} //asteroid ship collision
			
		} // onEnterFrameCheckCollisions
		
		
		/**
		createSpaceShip
		creates a new space ship and adds it the center of the stage
		*/
		private function createSpaceShip()
		{
			this.spaceShip = new SpaceShip();
			
			//set the x and y properties
			this.spaceShip.x = stage.stageWidth/2;
			//offset a bit from center
			this.spaceShip.y = stage.stageHeight/2 + this.spaceShip.height*2;
			
			stage.addChild(this.spaceShip);
			
			//add an event listener when the space ship blows up
			this.spaceShip.addEventListener(SpaceShip.DIE, this.onDeathSpaceShip);
		}
		
		/**
		createStartAsteroids
		create the initial amount of asteroids
		*/
		private function createStartAsteroids(num:uint = 4) {
			SpaceObject.createSpaceObjects(stage, Asteroid, num, 1, 0, 0, stage.stageWidth / 2, stage.stageHeight / 2, 0, 0, 5, 10, 0);
		}
		
		
		// called when the space ship dies 
		public function onDeathSpaceShip( e:Event ) 
		{
			var explodeSound = new ExplodeTwo();
			explodeSound.play();
			
			this.createSpaceShip();
		}
		
		// called when there are no more asteroids
		public function onNoAsteroidsMakeMore( e:Event ) 
		{
			trace("No more Asteroids, creating more...");
			this.createStartAsteroids(NUM_ASTEROIDS);
		}
		
		private function onGameRemoved(evt:Event):void {
			this.destroyAll();
		}
		
		/*
		destroyAll
		Remove all asteroids and ship from stage. Bullets have short
		ttl so they get removed on their own.
		*/
		private function destroyAll():void
		{
			if(stage != null)
			{
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrameCheckCollisions);
				stage.removeEventListener(Asteroid.NO_ASTEROIDS, onNoAsteroidsMakeMore);
				
				var numAsteroids:uint = Asteroid.allAsteroids.length;
				var asteroid:Asteroid;
				for(var i:uint = 0; i < numAsteroids; i++)
				{
					asteroid = Asteroid.allAsteroids[i];
					asteroid.removeEventListener(Event.REMOVED_FROM_STAGE, asteroid.onRemovedAsteroid);
					stage.removeChild(asteroid);
				}
				
				//reset data structures
				Asteroid.allAsteroids = new Array();
				Bullet.allBullets = new Array();
				
				//remove ship
				stage.removeChild(this.spaceShip);
				this.spaceShip = null;
			}
		}
		
	}//package
} //class

