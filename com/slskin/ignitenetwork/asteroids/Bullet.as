/*
Bullet.as
Disappears after LIFESPAN milliseconds
*/

package com.slskin.ignitenetwork.asteroids 
{
	import flash.events.*;
	import flash.utils.Timer;
	
	public class Bullet extends SpaceObject 
	{
		// list of all Bullets
		static var allBullets:Array = new Array();
		
		// speed of bullets
		static const FIRE_VELOCITY:Number = 10;
		
		// lifespan of bullets in milliseconds
		static const LIFESPAN:Number = 3000;
		
		public function Bullet() {
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedBullet);
		}
		
		public function onDeathKnellGrimReaper( e:Event ) {}

		
		public override function blowUp() {
			//remove the bullet
			stage.removeChild(this);
		}
		
		
		public function onAddedBullet( e:Event ) {
			Bullet.allBullets.push(this);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedBullet);
		}
		
		public function onRemovedBullet( e:Event ) {
			Bullet.allBullets.splice(allBullets.indexOf(this), 1);
		}
			
	} //class
} //package