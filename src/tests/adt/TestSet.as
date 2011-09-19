package tests.adt
{

	import util.Iterator ;
	import adt.Set;
	import org.flexunit.Assert;
	
	public class TestSet
	{
		
		public function TestSet()
		{
		}
		
		[Test]  
		public function add():void 
		{ 
			var set:Set = new Set();
			Assert.assertTrue( set.add( [1,2] ));
			Assert.assertFalse( set.add( [1,2] ));
			
			set = new Set();
			Assert.assertTrue( set.add( 1 ));
			Assert.assertFalse( set.add( 1 ));
			
			
		}
		
		[Test]  
		public function remove():void 
		{ 
			var set:Set = new Set();
			set.add( [1,2] );
			Assert.assertTrue( set.remove( [1,2] ));
			
			set = new Set();
			set.add( 1 );
			Assert.assertTrue( set.remove( 1 ));
		}
		
		[Test]  
		public function contains():void 
		{ 
			var set:Set = new Set();
			set.add( [1,2] );
			Assert.assertTrue( set.contains( [1,2] ));
			set.remove( [1,2] );
			Assert.assertFalse( set.contains( [1,2] ));
			
			set = new Set();
			set.add( 1 );
			Assert.assertTrue( set.contains( 1 ));
			set.remove( 1 );
			Assert.assertFalse( set.contains( 1 ));
		}
		
		[Test]
		public function iterator():void
		{
			var set:Set = new Set();
			set.add( [1,2] );
			set.add( [3,4] );
			set.add( [5,6] );
			var iterator:Iterator = set.iterator ;
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertFalse( iterator.hasNext());
		}
	}
}