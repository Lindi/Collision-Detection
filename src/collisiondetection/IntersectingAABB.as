package collisiondetection
{
	import adt.Set;
	
	import util.Iterator;
	
	
	import geometry.AABB ;

	public class IntersectingAABB
	{
		private var _endpointsX:Vector.<Endpoint> ;
		private var _endpointsY:Vector.<Endpoint> ;
		private var _lookupX:Vector.<int> ;
		private var _lookupY:Vector.<int> ;
		private var _aabb:Vector.<AABB> ;
		private var _intersections:Set = new Set() ;

		public function IntersectingAABB( aabb:Vector.<AABB> )
		{
			_aabb = aabb ;
		}
		
		public function update():void
		{
			//	Update the endpoints
			for ( var i:int = 0; i < _aabb.length; i++ )
			{
				var aabb:AABB = _aabb[i] ;
				var j:int = _lookupX[ 2 * i ] ;
				var endpoint:Endpoint = _endpointsX[j] ;
				endpoint.value = aabb.xmin ;
				
				j = _lookupX[ 2 * i + 1 ] ;
				endpoint = _endpointsX[j] ;
				endpoint.value = aabb.xmax ;
				
				j = _lookupY[ 2 * i ] ;
				endpoint = _endpointsY[j] ;
				endpoint.value = aabb.ymin ;
				
				j = _lookupY[ 2 * i + 1 ] ;
				endpoint = _endpointsY[j] ;
				endpoint.value = aabb.ymax ;
			}
			
			//	Sort the endpoints
			insertionSort( _endpointsX, _lookupX ) ;
			insertionSort( _endpointsY, _lookupY ) ;
		}
		
		public function get intersections():Iterator
		{
			return _intersections.iterator ;
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
			}
		}
		
		/**
		 * Here's where the fun happens.
		 * We're going to pass the collection of x-endpoints and its interval lookup table
		 * We're going to pass the collection of y-endpoints and its interval lookup table 
		 * We peform an insertion sort on the collection of endpoints.
		 * 
		 * Anytime we see that an ending endpoint is less than a beginning endpoint
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
		
		/**
		 * Throws an error if the list of endpoints isn't sorted. 
		 * @param endpoints
		 * 
		 */		
		private function checkEndpoints( endpoints:Vector.<Endpoint> ):void
		{
			for ( var i:int = 1; i < endpoints.length; i++ )
			{
				var a:Endpoint = endpoints[i] ;
				var b:Endpoint = endpoints[i-1] ;
				if ( a.value < b.value )
				{
					throw new Error("Sorting error.");
				}
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
