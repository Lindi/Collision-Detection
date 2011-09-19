package geometry
{
	public class Vector2d 
	{
	
		private var _data:Vector.<Number> = new Vector.<Number>(2,true);
		
		public function Vector2d( x:Number = 0, y:Number = 0)
		{
			_data[0] = x ;
			_data[1] = y ;
		}
		
		public function dotProduct( vector:Vector2d ):Number
		{
			return _data[0] * vector.x + _data[1] * vector.y ;
		}
		
		public function clone() : Vector2d
		{
			return new Vector2d( _data[0], _data[1] );
		}
		
		public function perpendicular():void
		{
			var tmp:Number = _data[0] ;
			_data[0] = _data[1] ;
			_data[1] = -tmp ;
		}
		
		public function perp(  ):Vector2d
		{
			return new Vector2d( _data[1], -_data[0] );
		}
		
		public function unitPerp():Vector2d
		{
			var perp:Vector2d = new Vector2d( _data[1], -_data[0] );
			perp.normalize();
			return perp ;
		}
		
		public function normalize():void
		{
			var magnitude:Number = Math.sqrt( _data[0] * _data[0] + _data[1] * _data[1] );
			_data[0] /= magnitude ;
			_data[1] /= magnitude ;
		}
		public function get x():Number
		{
			return _data[0] ;
		}
		
		public function set x( x:Number ):void
		{
			_data[0] = x ;
		}

		public function get y():Number
		{
			return _data[1] ;
		}

		public function set y( y:Number ):void
		{
			_data[1] = y ;
		}
	}
}