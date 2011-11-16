package
{
	import adt.Set;
	
	import collisiondetection.IntersectingAABB;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import geometry.AABB;
	import geometry.Vector2d;
	
	import util.Iterator;
	
	
	[SWF(width='400',height='400',backgroundColor='#ffffff')]
	public class Main extends Sprite
	{
		
		private var _velocities:Vector.<Vector2d> ;
		private var _aabb:Vector.<AABB> ;
		private var _intersectingAABB:IntersectingAABB ;
		
		
		public function Main()
		{
			//	The area in which to create AABBs
			var w:int = stage.stageWidth - 40 ;
			var h:int = stage.stageHeight - 40 ;
			
			//	Don't scale the stage
			stage.scaleMode = StageScaleMode.NO_SCALE ;
			stage.align = StageAlign.TOP_LEFT ;
			
			//	Create some axis-aligned bounding boxes
			var n:int = int( Math.random() * 100 ) + 50 ;

			//	Create a collection of AABBs
			_aabb = new Vector.<AABB>(n);
			for ( var i:int  = 0; i < n; i++ )
			{
				var aabb:AABB = new AABB();
				aabb.xmin = int( Math.random() * w );
				aabb.ymin = int( Math.random() * w );
				aabb.xmax = aabb.xmin + 20 + int( Math.random() * 20 );
				aabb.ymax = aabb.ymin + 20 + int( Math.random() * 20 );
				_aabb[i] = aabb ;
				
			}
			//	Create an instance of our intersecting AABB collision detection algorithm implementation
			_intersectingAABB = new IntersectingAABB( _aabb ) ;
			
			//	initialize the endpoints and the lookup tables
			_intersectingAABB.initialize();
			
			//	Create a collection of velocity vectors that we'll use
			//	to move the AABBs around the stage
			_velocities = new Vector.<Vector2d>( n ) ;
			for ( i = 0; i < n; i++ ) 
			{
				var vx:Number = -2 + int( Math.random() * 4 ) + 1 ;
				var vy:Number = -2 + int( Math.random() * 4 ) + 1 ;
				_velocities[ i ] = new Vector2d( vx, vy ) ;
			}
			
			//	Listen for the frame event
			addEventListener( Event.ENTER_FRAME, enterFrame ) ;
			
		}
		
		/**
		 * Animation loop 
		 * @param event
		 * 
		 */		
		private function enterFrame( event:Event ):void
		{
			//	Clear the stage of graphics
			graphics.clear();

			//	Update each AABB with its velocity
			for ( var i:int = 0; i < _aabb.length; i++ )
			{
				var v:Vector2d = _velocities[ i ] ;
				var aabb:AABB = _aabb[i] ;
				var bounce:Boolean = false ;
				if ( aabb.xmin < 0 )
				{
					bounce = true ;
				}
				if ( aabb.ymin < 0 )
				{
					bounce = true ;
				}
				if ( aabb.xmax > stage.stageWidth )
				{
					bounce = true ;
				}
				if ( aabb.ymax > stage.stageHeight )
				{
					bounce = true ;
				}
				if ( bounce )
				{
					v.perpendicular();
				}
				aabb.xmin += v.x ;				
				aabb.ymin += v.y ;				
				aabb.xmax += v.x ;				
				aabb.ymax += v.y ;				
			}

			//	Perform the collision detection
			_intersectingAABB.update() ;
			
			//	Draw the aabbs
			for ( i = 0; i < _aabb.length; i++ )
			{
				//	Grab a reference to the aabb
				aabb = _aabb[i] ;
				
				//	Draw the aabb
				graphics.lineStyle( 1, 0x888888 );
				graphics.drawRect( aabb.xmin, aabb.ymin, ( aabb.xmax - aabb.xmin ), ( aabb.ymax - aabb.ymin ));
			}
			
			//	Now the set of intersections should be updated
			var iterator:Iterator = _intersectingAABB.intersections ;
			var intersection:AABB = new AABB ;
			while ( iterator.hasNext())
			{
				var array:Array = ( iterator.next() as Array ) ;
				i = array[0] as int ;
				var j:int = array[1] as int ;
				var a:AABB = _aabb[ i] ;
				var b:AABB = _aabb[ j] ;
				
				if ( a.findIntersection( b, intersection ))
				{
					graphics.lineStyle( 1, 0xff0000 );
					graphics.beginFill( 0xff0000, .45 );
					graphics.drawRect( intersection.xmin, intersection.ymin, ( intersection.xmax - intersection.xmin ), ( intersection.ymax - intersection.ymin ));
					graphics.endFill() ;
				}
			}
		}
	}
}



