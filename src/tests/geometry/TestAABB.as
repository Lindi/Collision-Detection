package tests.geometry
{
	public class TestAABB
	{
		import geometry.AABB;
		import org.flexunit.Assert;
		
		public function TestAABB()
		{
		}

		[Test]  
		public function hasXOverlap():void 
		{ 
			var a:AABB = new AABB( -50, 0, 50, 0 );
			var b:AABB = new AABB( -40, 0, 100, 0 );
			Assert.assertTrue( a.hasXOverlap( b ));
			Assert.assertTrue( b.hasXOverlap( a ));
			
			b.xmin = 60 ;
			Assert.assertFalse( a.hasXOverlap( b ));
			Assert.assertFalse( b.hasXOverlap( a ));
		}
		
		[Test]  
		public function hasYOverlap():void 
		{ 
			var a:AABB = new AABB( 0, -50, 0, 50 );
			var b:AABB = new AABB( 0, -40, 0, 400 );
			Assert.assertTrue( a.hasYOverlap( b ));
			Assert.assertTrue( b.hasYOverlap( a ));
			
			b.ymin = 60 ;
			Assert.assertFalse( a.hasYOverlap( b ));
			Assert.assertFalse( b.hasYOverlap( a ));
		}
		
		[Test]  
		public function testIntersection():void 
		{ 
			var a:AABB = new AABB( 0, 0, 50, 50 );
			var b:AABB = new AABB( 10, 10, 100, 100 );
			Assert.assertTrue( a.testIntersection( b ));
			Assert.assertTrue( b.testIntersection( a ));
			
			b.xmin = 60 ;
			b.ymin = 60 ;
			Assert.assertFalse( a.testIntersection( b ));
			Assert.assertFalse( b.testIntersection( a ));
		}
	}
}