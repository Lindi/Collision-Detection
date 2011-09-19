package tests.util
{
	
	public class TestIterator
	{
		import org.flexunit.Assert;
		
		import util.Iterator;
		
		
		public function TestIterator()
		{
		}
		
		[Test]
		public function next():void
		{
			var object:Object = { "1" : 1, "2": 2, "3" : 3, "4": 4 }
			var iterator:Iterator = new Iterator( object );
			Assert.assertEquals( iterator.next(), 1 );
			Assert.assertEquals( iterator.next(), 2 );
			Assert.assertEquals( iterator.next(), 3 );
			Assert.assertEquals( iterator.next(), 4 );
			
			iterator = new Iterator( [1,2,3,4] );
			Assert.assertEquals( iterator.next(), 1 );
			Assert.assertEquals( iterator.next(), 2 );
			Assert.assertEquals( iterator.next(), 3 );
			Assert.assertEquals( iterator.next(), 4 );
			
		}
		[Test]
		public function hasNext():void
		{
			var object:Object = { "1" : 1, "2": 2, "3" : 3, "4": 4 }
			var iterator:Iterator = new Iterator( object );
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertFalse( iterator.hasNext());
			
			
			iterator = new Iterator( [1,2,3,4] );
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertFalse( iterator.hasNext());
		}
		[Test]
		public function reset():void
		{
			var object:Object = { "1" : 1, "2": 2, "3" : 3, "4": 4 }
			var iterator:Iterator = new Iterator( object );
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
			Assert.assertFalse( iterator.hasNext());
			iterator.reset();
			Assert.assertTrue( iterator.hasNext());
			iterator.next();
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