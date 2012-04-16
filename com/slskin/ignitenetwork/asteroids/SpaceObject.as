/*
SpaceObject.as
Base class for: SpaceShip, Asteroid, Bullet

handles movement behavior for:
- acceleration
- velocity 
- screen wrapping 

*/

package com.slskin.ignitenetwork.asteroids 
{
	
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.utils.Timer;
	import flash.display.DisplayObjectContainer;
	import flash.display.DisplayObject;
	
	public class SpaceObject extends MovieClip 
	{
		/* Constants */
		public const DRAG:Number = 0;
		
		/* Public Member Fields */
		public var velX:Number = 0;
		public var velY:Number = 0;
		public var deltaRotate:Number = 0;
		public var acceleration:Number = 0;	
		
		/* Private Member Fields */
		private var deathKnell:Timer; // timer that marks scheduled removal
		
		public function SpaceObject() {
			//add event listener for added to stage
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedSpaceObject);
		}
		
		//Marks the spaceObjectect for removal
		public function setLifeSpan(milliseconds:int) 
		{
			//setup timer
			deathKnell = new Timer(milliseconds, 1);
			//add listener
			deathKnell.addEventListener(TimerEvent.TIMER_COMPLETE, onDeathKnellGrimReaper);
			//start timer
			deathKnell.start();
		}
		
		
		private function onDeathKnellGrimReaper(e:Event) 
		{
			//stop timer
			deathKnell.stop();
			
			//maybe the object has already blownup?
			//if not call blowup
			if(this.stage != null)
				this.blowUp();
		}
		
		
		// get rid of it, will likely be overridden
		// by subclasses
		public function blowUp() {
			//remove child 
			parent.removeChild(this);
		}
		
		public function onAddedSpaceObject ( e:Event ) 
		{
			this.addEventListener(Event.ENTER_FRAME, this.onEnterFrameMove);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedSpaceObject);
			
			//you don't need this listener anymore
			this.removeEventListener(Event.ADDED_TO_STAGE, onAddedSpaceObject);
		}
		
		public function onRemovedSpaceObject ( e:Event ) 
		{
			//remove enterFrame Listeners
			this.removeEventListener(Event.ENTER_FRAME, this.onEnterFrameMove);
			this.removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedSpaceObject);
		}
		
		// function createAsteroids - builds asteroids
		//  container - where they should be built, probably called with stage
		//  type - type of SpaceObject to build
		//  num - number to build 
		//  scale - size of asteroids to build
		// 	centerX, centerY - center of rectangle in which they are build
		// 	width, height - size of rectangle
		//  velX, velY - inherited velocity
		//  vRandom - randomness in velocity
		//  rotateRandom - randomness in rotation
		//  lifeSpan - for temporary items, 0 for permanent
		static public function createSpaceObjects( container:DisplayObjectContainer, type:Class , num:int = 4, scale:Number = 1, 
											   	centerX:Number = 0, centerY:Number=0, width:Number = 0, height:Number = 0, 
												vX:Number = 0, vY:Number=0, vRandom:Number = 0, rotateRandom:Number=0, lifeSpan:int = 0  ) {
			//trace( "Created " + num + " Space Object: " + type );
			var spaceObject:SpaceObject;
			for( var i=0;i<num;i++) {
				spaceObject = new type();
				container.addChild( spaceObject );
				spaceObject.x = rand( centerX - width/2, centerX + width/2);
				spaceObject.y = rand( centerY - height/2, centerY + height/2);
				spaceObject.scaleX = spaceObject.scaleY = rand(scale *.5, scale);
				spaceObject.velX = vX + rand(-vRandom/2,vRandom/2);
				spaceObject.velY = vY + rand(-vRandom/2,vRandom/2);
				spaceObject.rotation = rand(0,360);
				spaceObject.deltaRotate = rand(-rotateRandom/2,rotateRandom/2);
				if (lifeSpan > 0 )
					spaceObject.setLifeSpan( lifeSpan );
			}
		}
		
		

		//manage velocity, rotation, check for wrap around
		public function onEnterFrameMove( e:Event ) 
		{
			this.rotation += this.deltaRotate;
			
			//accelerations
			var angleInRadians = rotation * Math.PI / 180;
			var accX = acceleration * Math.cos(angleInRadians);
			var accY = acceleration * Math.sin(angleInRadians);
			
			velX += accX;
			velY += accY;
			
			//velocity
			this.x += velX;
			this.y += velY;
			
			velX *= (1 - this.DRAG);
			velY *= (1 - this.DRAG);
			
			//take care of negative vel
			this.x += stage.stageWidth;
			this.y += stage.stageHeight;
			
			//check if we are off the screen
			this.x %= stage.stageWidth;
			this.y %= stage.stageHeight;
		}
		
	} //class
} //package