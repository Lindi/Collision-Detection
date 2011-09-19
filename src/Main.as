package
{
	import adt.Set;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import geometry.AABB ; 
	
	import geometry.Vector2d;
	
	import util.Iterator;
	
	
	[SWF(width='400',height='400',backgroundColor='#ffffff')]
	public class Main extends Sprite
	{
		private var _endpointsX:Vector.<Endpoint> ;
		private var _endpointsY:Vector.<Endpoint> ;
		private var _lookupX:Vector.<int> ;
		private var _lookupY:Vector.<int> ;
		private var _aabb:Vector.<AABB> ;
		
		private var _velocities:Vector.<Vector2d> ;
		
		private var _intersections:Set = new Set() ;
		
		public function Main()
		{
			//	The area in which to create AABBs
			var w:int = stage.stageWidth - 40 ;
			var h:int = stage.stageHeight - 40 ;
			
			//	Don't scale the stage
			stage.scaleMode = StageScaleMode.NO_SCALE ;
			stage.align = StageAlign.TOP_LEFT ;
			

			//	Create some axis-aligned bounding boxes
			var n:int = int( Math.random() * 20 ) + 10 ;

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
			
			//	initialize the endpoints and the lookup tables
			initialize();
			
			//	Create a collection of velocity vectors that we'll use
			//	to move the AABBs around the stage
			_velocities = new Vector.<Vector2d>( n ) ;
			for ( i = 0; i < n; i++ ) 
			{
				var vx:Number = -2 + int( Math.random() * 4 ) ;
				var vy:Number = -2 + int( Math.random() * 4 ) ;
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
				aabb.xmin = Math.max( 0, aabb.xmin + v.x );
				aabb.ymin = Math.max( 0, aabb.ymin + v.y );
				aabb.xmax = Math.min( stage.stageWidth, aabb.xmax + v.x );
				aabb.ymax = Math.min( stage.stageHeight, aabb.ymax + v.y );
				if ( aabb.xmin == 0 
					|| aabb.ymin == 0 
					|| aabb.xmax == stage.stageWidth
					|| aabb.ymax == stage.stageHeight )
				{
					v.perpendicular();
				}
				
				//	Draw the aabb
				graphics.lineStyle( 1, 0x888888 );
				graphics.drawRect( aabb.xmin, aabb.ymin, ( aabb.xmax - aabb.xmin ), ( aabb.ymax - aabb.ymin ));
				

				//	Update the endpoints
				var j:int = _lookupX[ 2 * i ] ;
				var endpoint:Endpoint = _endpointsX[j] ;
				endpoint.value = aabb.xmin ;
				
				j = _lookupX[ 2 * i + 1 ] ;
				endpoint = _endpointsX[j] ;
				endpoint.value = aabb.xmax ;
				
				j = _lookupY[ 2 * i ] ;
				endpoint = _endpointsY[j] ;
				endpoint.value = aabb.ymin ;
				
				j = _lookupY[ 2 * i + 1] ;
				endpoint = _endpointsY[j] ;
				endpoint.value = aabb.ymax ;
			}
			
			//	Sort the endpoints
			insertionSort( _endpointsX, _lookupX ) ;
			insertionSort( _endpointsY, _lookupY ) ;
			
			//	Now the set of intersections should be updated
			var iterator:Iterator = _intersections.iterator ;
			var intersection:AABB = new AABB ;
			while ( iterator.hasNext())
			{
				var array:Array = ( iterator.next() as Array ) ;
				i = array[0] ;
				j = array[1] ;
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
		
		/**
		 * Returns 1 if endpoint a is greater than endpoint b
		 * Returns -1 if endpoint a is less than endpoint b 
		 * @param a
		 * @param b
		 * @return 
		 * 
		 */		
		private function sort( a:Endpoint, b:Endpoint ):int
		{
			if ( a.lessThan(b))
				return -1 ;
			else if ( !a.lessThan(b))
				return 1 ;
			return 0 ;
		}
		
		/**
		 * Create the endpoint arrays and the interval lookup
		 * that we're going to use during sorting 
		 * 
		 */		
		public function initialize():void
		{
			//	There are going to be twice as many endpoints
			//	as aabbs in each dimension
			var m:int = 2 * _aabb.length ;
			
			//	Initialize the array of x-endpoints
			_endpointsX = new Vector.<Endpoint>( m );
			
			//	Initialize the array of y-endpoints
			_endpointsY = new Vector.<Endpoint>( m );
			
			//	Go through all of the abbs and store their horizontal endpoints
			//	in the array of horizontal end points, and store their vertical
			//	endpoints in the array of vertical endpoints
			var i:int, j:int ;
			for ( i=0, j=0 ; i < _aabb.length; i++ )
			{
				_endpointsX[j] = new Endpoint();
				_endpointsX[j].value = _aabb[i].xmin ;
				_endpointsX[j].type = 0 ;
				_endpointsX[j].index = i ;
				_endpointsY[j] = new Endpoint();
				_endpointsY[j].value = _aabb[i].ymin ;
				_endpointsY[j].type = 0 ;
				_endpointsY[j].index = i ;
				j++ ;
				
				_endpointsX[j] = new Endpoint();
				_endpointsX[j].value = _aabb[i].xmax ;
				_endpointsX[j].type = 1 ;
				_endpointsX[j].index = i ;
				_endpointsY[j] = new Endpoint();
				_endpointsY[j].value = _aabb[i].ymax ;
				_endpointsY[j].type = 1 ;
				_endpointsY[j].index = i ;
				j++ ;
			}

			_endpointsX.sort( sort );
			_endpointsY.sort( sort ) ;
			
			//	Initialize the interval lookup collections
			_lookupX = new Vector.<int>(m);
			_lookupY = new Vector.<int>(m);
			for ( j = 0; j < m; j++ )
			{
				_lookupX[ 2 * _endpointsX[j].index + _endpointsX[j].type ] = j ;
				_lookupY[ 2 * _endpointsY[j].index + _endpointsY[j].type ] = j ;
			}
			
			//	Create a set of active rectangles to be used within the loop
			var active:Set = new Set();
			
			//	Iterate over the x-endpoints
			for ( j = 0; j < m; j++ )
			{
				var endpoint:Endpoint = _endpointsX[j] ;
				var index:int = endpoint.index ;
				if ( endpoint.type == 0 )
				{
					var iterator:Iterator = active.iterator ;
					while ( iterator.hasNext())
					{
						i = iterator.next() as int ;
						var a:AABB = _aabb[ index ] ;
						var b:AABB = _aabb[ i ] ;
						
						//	N.B.  We only have to test for y-overlap here because we haven't
						//	yet encountered the interval's endpoint.  If an endpoint index is
						//	still in the set of active indices, it means we have encountered the
						//	beginning of an interval, but we haven't yet encountered
						//	the end of an interval.  Therefore, all active intervals
						//	intersect in the horizontal dimension.  
						if ( a.hasYOverlap( b ))
						{
							//	If the aabbs also intersect in the y-dimension, then we should
							//	add the intersecting pair to the intersection set
							if ( index < i )
								_intersections.add( [ index, i ] );
							else _intersections.add( [ i, index ] );
						}
						
					}
					
					//	Add the new index to mark the beginning of an interval
					active.add( index ) ;
					
				} else {
					
					//	Remove the index from the set to mark the end of an interval
					//	and to ensure that no further intersection tests will be peformed
					//	on this aabb
					active.remove( index ) ;
				}
				
				return ;
			}
		}
		
		/**
		 * Here's where the fun happens.
		 * We're going to pass the collection of x-endpoints and its interval lookup table
		 * We're going to pass the collection of y-endpoints and its interval lookup table 
		 * We peform an insertion sort on the collection of endpoints.
		 * 
		 * Anytime we see that a ending endpoint is less than a beginning endpoint
		 * we check to see if their rectangles are in the set of intersections and we remove them
		 * 
		 * Anytime we see that a ending endpoint is greater than a beginning endpoint
		 * we add the pair of AABB indices into the intersection array.  If the pair isn't removed
		 * after sweeps in both the x and y directions, we know there's an intersection
		 * 
		 * @param endpoints
		 * @param lookup
		 * 
		 */		
		public function insertionSort( endpoints:Vector.<Endpoint>, lookup:Vector.<int> ):void
		{
			var m:int = endpoints.length ;
			var j:int ;
			for ( var i:int = 1; i < m; i++ )
			{
				//	Grab the endpoint
				var endpoint:Endpoint = endpoints[ i ] ;
				j = i - 1 ;
				while ( j >= 0 && endpoint.lessThan( endpoints[ j ] ))
				{
					var a:Endpoint = endpoints[ j ] ;
					var b:Endpoint = endpoints[ j + 1 ] ;
					
					if ( a.type == 0 )
					{
						if ( b.type == 1 )
						{
							//	In this case, the interval ending point b is less than
							//	the interval beginning point a, so these two intervals cannot
							//	overlap any longer
							if ( a.index < b.index )
								_intersections.remove( [ a.index, b.index ] );
							else _intersections.remove( [ b.index, a.index ] );
						}
					} else
					{
						if ( b.type == 0 )
						{
							//	In this case, the interval beginning end point is less than
							//	the interval ending end point, so these two intervals could
							//	be intersecting
							if ( a.index < b.index )
								_intersections.add( [ a.index, b.index ] );
							else _intersections.add( [ b.index, a.index ] );
							
						}
					}
					
					//	Switch the endpoints
					endpoints[ j ] = b ;
					endpoints[ j+1 ] = a ;
					lookup[ 2 * b.index + b.type ] = j ;
					lookup[ 2 * a.index + a.type ] = j+1 ;
					j-- ;
					
				}
				
				//	Finally, swap the endpoint into its place
				endpoints[ j+1 ] = endpoint ;
				lookup[ 2 * endpoint.index + endpoint.type ] = j+1 ;
			}
		}
	}
}

class Endpoint
{
	public var value:Number ;
	public var index:int ;
	public var type:int ;
	
	public function lessThan( endpoint:Endpoint ):Boolean
	{
		if ( value < endpoint.value )
			return true ;
		if ( value > endpoint.value )
			return false ;
		return ( type < endpoint.type ) ;
	}
}


