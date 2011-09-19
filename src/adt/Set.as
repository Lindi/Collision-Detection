package adt
{
	import util.Iterator;
	
	public class Set
	{
		private var _hash:Object = new Object( );
		
		public function Set()
		{
		}
		
		/**
		 * Adds an element to the set.  No more than one of any element may exist in a set.
		 * @param object - The element to be added to the set.
		 * @return boolean - Returns true if the element was successfully added to the set, false if not.
		 * 
		 */		
		public function add( object:Object ):Boolean
		{
			if ( _hash[ String( object.valueOf())] != null )
				return false;
			_hash[ String( object.valueOf())] = object ;
			return true ;
		}
		
		/**
		 * Removes an element from the set 
		 * @param object - The object to be removed from the set.
		 * @return boolean - Returns true if the object has been removed from the set, false if not.
		 * 
		 */		
		public function remove( object:Object ):Boolean
		{
			if ( _hash[ String( object.valueOf())] == null )
				return false;
			return delete _hash[ String( object.valueOf())]  ;
		}
		
		/**
		 * Returns true if the set contains an element, false otherwise.
		 * @param object - the element to be searched for in the set
		 * @return - true if the set contains the element, false otherwise
		 * 
		 */		
 		public function contains( object:Object ):Boolean
		{
			return ( _hash[ String( object.valueOf())] != null );
		}
		
		/**
		 * Empties the set of all elements 
		 * 
		 */		
		public function empty():void
		{
			for each ( var prop:String in _hash )
				delete _hash[prop] ;
		}
		
		/**
		 * Returns a new iterator that can be used to
		 * iterate over the set 
		 * @return 
		 * 
		 */		
		public function get iterator():Iterator
		{
			return new Iterator( _hash );
		}
	}
}