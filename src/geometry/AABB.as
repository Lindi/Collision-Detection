package geometry
{
	public class AABB
	{
		private var _min:Vector.<Number> = new Vector.<Number>(2);
		private var _max:Vector.<Number> = new Vector.<Number>(2);
		
		public function AABB( xmin:Number = 0, ymin:Number = 0, xmax:Number = 0, ymax:Number = 0)
		{
			_min[0] = xmin ;
			_min[1] = ymin ;
			_max[0] = xmax ;
			_max[1] = ymax ;
		}
		
		public function get xmin():Number
		{
			return _min[0];	
		}
		public function set xmin( xmin:Number ):void
		{
			_min[0] = xmin ;
		}
		public function get ymin():Number
		{
			return _min[1];	
		}
		public function set ymin( ymin:Number ):void
		{
			_min[1] = ymin ;
		}
		public function get xmax():Number
		{
			return _max[0];	
		}
		public function set xmax( xmax:Number ):void
		{
			_max[0] = xmax ;
		}
		public function get ymax():Number
		{
			return _max[1];	
		}
		public function set ymax( ymax:Number ):void
		{
			_max[1] = ymax ;
		}
		
		public function get min():Vector.<Number>
		{
			return _min ;
		}
		
		public function get max():Vector.<Number>
		{
			return _max ;
		}
		
		public function hasXOverlap( aabb:AABB ):Boolean
		{
			return ( _min[0] <= aabb.xmax && _max[0] >= aabb.xmin );
		}
		
		public function hasYOverlap( aabb:AABB ):Boolean
		{
			return ( _min[1] <= aabb.ymax && _max[1] >= aabb.ymin );
		}

		public function testIntersection( aabb:AABB ):Boolean
		{
			if ( _max[0] < aabb.xmin || _min[0] > aabb.xmax )
				return false ;
			if ( _max[1] < aabb.ymin || _min[1] > aabb.ymax )
				return false ;
			return true ;
		}
		
		
		public function findIntersection( aabb:AABB, intersection:AABB ):Boolean
		{
			for ( var i:int = 0; i < 2; i++ )
			{
				if ( _min[i] > aabb.max[i] || _max[i] < aabb.min[i] )
					return false ;
			}
			
			for (i = 0; i < 2; i++)
			{
				//	Use the lesser of the maximum intersection value
				//	in either dimension
				if ( _max[i] <= aabb.max[i] )
					intersection.max[i] = _max[i];
				else
					intersection.max[i] = aabb.max[i];
				
				
				//	Use the greater of the minimum intersection value
				//	in either dimension
				if ( _min[i] <= aabb.min[i] )
					intersection.min[i] = aabb.min[i];
				else
					intersection.min[i] = _min[i];
			}
			return true;
		}
	}
}