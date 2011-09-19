package util
{
	public class Iterator
	{
		private var _array:Array ;
		private var _index:int = -1 ;
		
		public function Iterator( collection:* )
		{
			if ( collection is Array )
				_array = collection ;
			else
			{
				_array = new Array();
				
				for ( var prop:String in collection )
					_array.push( collection[prop] );
			}
		}
		
		public function next():*
		{
			return _array[ ++_index] ;
		}
		
		public function hasNext():Boolean
		{
			return _index < _array.length - 1 ;
		}
		
		public function reset():void
		{
			_index = -1 ;
		}
	}
}