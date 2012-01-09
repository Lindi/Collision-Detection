package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import geometry.AABB;
	import geometry.Polygon2d;
	import geometry.Vector2d;
	
	import physics.PolygonDistance;
	import physics.lcp.LcpSolver;
	
	
	[SWF(width='400',height='400')]
	public class PolygonCollisionDetection extends Sprite
	{
		private var polygons:Vector.<Polygon2d> = new Vector.<Polygon2d>(2,true);
		private var aabbs:Vector.<AABB> = new Vector.<AABB>(2,true);
		private var velocity:Vector.<Vector2d> = new Vector.<Vector2d>(2,true);
		private var currentPolygon:int = -1 ;
		private var offset:Vector2d ;
		private var solution:Object ;
		
		public function PolygonCollisionDetection()
		{
			super();
			init( );
		}
		
		private function init( ):void
		{			
			
			//	Create a polygon 
			var random:int = int( Math.random() * 30 );
			var centroid:Vector2d = new Vector2d( stage.stageWidth/4, stage.stageHeight/2 - random ) ;
			polygons[0] = createPolygon( centroid );
			
			//	Create another polygon, and make sure they don't intersect
			random = int( Math.random() * 30 );
			centroid = new Vector2d( 3 * stage.stageWidth/4, stage.stageHeight/2 + random ) ;
			polygons[1] = createPolygon( centroid );
			
			//	Give each polygon a velocity
			var dx:Number, dy:Number ;
			dx = 20 + int( Math.random() * 10 ) * ( 1 - 2 * int( Math.random() * 2 ));
			dy = 20 + int( Math.random() * 10 ) * ( 1 - 2 * int( Math.random() * 2 ));
			velocity[0] = new Vector2d( dx, dy );
			do
			{
				dx = 20 + int( Math.random() * 10 ) * ( 1 - 2 * int( Math.random() * 2 ));
				dy = 20 + int( Math.random() * 10 ) * ( 1 - 2 * int( Math.random() * 2 ));
			} while ( dx == velocity[0].x || dy == velocity[0].y )
			velocity[1] = new Vector2d( dx, dy );

						
			//	Calculate distance
			calculateDistance();
			
			//	Draw the polygons
			draw( polygons );
			
			//	Listen for mouse up
			addEventListener( Event.ENTER_FRAME, frame );
			
		}
		
		private function calculateDistance( ):void
		{
			var solution:Object = PolygonDistance.distance( polygons[0].clone(), polygons[1].clone());
			if ( solution.status == LcpSolver.FOUND_SOLUTION )
			{
				this.solution = solution ;
				
			} else
			{
				this.solution = null ;
			}
		}
		
		private function click( event:Event ):void
		{
			
			//	TODO: Make sure to determine their AABBs intersect
			
			var polygonsIntersect:Boolean = SeparatingAxes.testIntersection( polygons[0], polygons[1] );
			
			//	Calculate the distance
			calculateDistance();
			
			//	Store the two closest points
			var a:Vector2d = new Vector2d( solution.Z[0], solution.Z[1] );
			var b:Vector2d = new Vector2d( solution.Z[2], solution.Z[3] );
			
			//	Calculate the distance between them
			var distance:Number = b.Subtract( a ).length ;
			
			//	Minimum distance threshold
			var threshold:Number = 5.0 ;
			
			//	If the polygons are close enough together ...
			if ( distance < threshold )
			{
				collisionResponse( a, b );
			}
			
			//	Draw the polygons
			draw( polygons, 0xaaaaaa );			
		}
		
		
		/**
		 * Separate the axis-aligned bounding boxes if
		 * the polygons intersect 
		 */		
		private function separateAABBs():void
		{
			//	Separate the AABBs
			var intersection:AABB = new AABB();
			aabbs[0].findIntersection( aabbs[1], intersection );
			var w:Number = intersection.width ;
			var h:Number = intersection.height ;
			var d:Number = Math.sqrt( w * w + h * h ) ;
			
			//	Move each polygon apart by half this distance
			var v:Vector2d = velocity[0].clone();
			v.normalize();
			
			//	Move them both half the distance
			//	Move polygon 0
			var centroid:Vector2d = polygons[0].centroid.Add( v.Negate().ScaleBy( d/2 ));
			updateCentroid( polygons[0], centroid ) ;
			//velocity[0] = v.Negate().ScaleBy( velocity[0].length ) ;
			
			
			//	Move polygon 1
			v = velocity[1].clone();
			v.normalize();
			centroid = polygons[1].centroid.Add( v.Negate().ScaleBy( d/2 ));
			updateCentroid( polygons[1], centroid ) ;
			//velocity[1] = v.Negate().ScaleBy( velocity[1].length ) ;
		}
		
		/**
		 * Enter frame handler 
		 * @param event
		 * 
		 */		
		private function frame( event:Event ):void
		{
			//	Update the velocities of each polygon
			updateCentroid( polygons[0], polygons[0].centroid.Add( velocity[0] ));
			updateCentroid( polygons[1], polygons[1].centroid.Add( velocity[1] ));

			//	Update the axis-aligned bounding boxes
			updateAABBs( ) ;
			
			//	Do collision detection with stage edges
			for ( var i:int = 0; i < polygons.length; i++ )
			{
				//	Grab a polygon
				var polygon:Polygon2d = polygons[i];
				polygon.moved = false ;
				
				//	Get the AABB
				var aabb:AABB = aabbs[i] ;
				var offstage:Boolean = ( aabb.xmin <= 0 )
					|| ( aabb.xmax >= stage.stageWidth )
					|| ( aabb.ymin <= 0 )
					|| ( aabb.ymax >= stage.stageHeight );
				
				//	Get the centroid
				var centroid:Vector2d = polygon.centroid.clone() ;
				
				if ( aabb.xmin <= 0 )
				{
					if ( velocity[i].dot( new Vector2d( 1, 0 )) < 0 )
					{
						velocity[i].x = -velocity[i].x ;
						centroid.x -= aabb.xmin ;
						polygon.moved = true ;
					}
				}
				if ( aabb.xmax >= stage.stageWidth )
				{
					if ( velocity[i].dot( new Vector2d( -1, 0 )) < 0 )
					{
						velocity[i].x = -velocity[i].x ;
						centroid.x -= ( aabb.xmax - stage.stageWidth ) ;
						polygon.moved = true ;
					}
				}
				if ( aabb.ymin <= 0 )
				{
					if ( velocity[i].dot( new Vector2d( 0, 1 )) < 0 )
					{
						velocity[i].y = -velocity[i].y ;
						centroid.y -= aabb.ymin ;
						polygon.moved = true ;
					}
				}
				if ( aabb.ymax >= stage.stageHeight )
				{
					if ( velocity[i].dot( new Vector2d( 0, -1 )) < 0 )
					{
						velocity[i].y = -velocity[i].y ;
						centroid.x -= ( aabb.ymax - stage.stageHeight ) ;
						polygon.moved = true ;
					}
				}
				
				updateCentroid( polygon, centroid );
			}
			
			//	Get the axis-aligned bounding boxes			
			for ( i = 0; i < polygons.length; i++ )
			{
				//	Grab a polygon
				polygon = polygons[i];
				
				//	Get the AABB
				aabbs[i] = getAABB( polygon ) ;
			}
			
			//	Do their AABBs intersect?
			var aabbsIntersect:Boolean = aabbs[0].findIntersection( aabbs[1] ) ; 
			
			var color:Number = ( aabbsIntersect ? 0xff0000 : 0x000000 ) ;
			
			
			//	Do the collision response here ...
			if ( aabbsIntersect )
			{
				
				if ( SeparatingAxes.testIntersection( polygons[0], polygons[1] ))
					separateAABBs();
				
				//	Calculate the distance
				calculateDistance();
				
				//	Store the two closest points
				var a:Vector2d = new Vector2d( solution.Z[0], solution.Z[1] );
				var b:Vector2d = new Vector2d( solution.Z[2], solution.Z[3] );
				
				//	Calculate the distance between them
				var distance:Number = b.Subtract( a ).length ;
				
				//	Minimum distance threshold
				var threshold:Number = 5.0 ;
				
				//	If the polygons are close enough together ...
				if ( distance < threshold )
				{
					collisionResponse( a, b );
					updateCentroid( polygons[0], polygons[0].centroid.Add( velocity[0] ));
					updateCentroid( polygons[1], polygons[1].centroid.Add( velocity[1] ));

				}
			}
			//	Update the axis-aligned bounding boxes
			updateAABBs( ) ;
			//	Draw the polygons
			draw( polygons, color );			
		}
		
		/**
		 * Update the axis-aligned bounding boxes
		 * of the polygons 
		 * 
		 */		
		private function updateAABBs( ):void
		{
			//	Get the axis-aligned bounding boxes			
			for ( var i:int = 0; i < polygons.length; i++ )
			{
				//	Get the AABB
				aabbs[i] = getAABB( polygons[i] ) ;
			}
			
		}
		/**
		 * Respond to the collision of the polygons.  Vectors a and b
		 * are the two closest points between the polygon. 
		 * @param a - The point on polygon a closest to polygon b
		 * @param b - The poing on polygon b closest to polygon a
		 * 
		 */		
		private function collisionResponse( a:Vector2d, b:Vector2d ):void
		{
			//	Move the polygons together
			//	TODO: return a vector of velocities from this function
			//	and translate point a and b by the respective velocities
			movePolygonsTogether( a, b );
//			velocity[0].negate() ;
//			velocity[1].negate() ;
//			//	Update the velocities of each polygon
//			updateCentroid( polygons[0], polygons[0].centroid.Add( velocity[0] ));
//			updateCentroid( polygons[1], polygons[1].centroid.Add( velocity[1] ));
////			a.add( velocity[0] );
////			b.add( velocity[1] );
//			return ;
			
			//	Determine which closest point lies on an edge
			var index:int = -1;
			var edge:Vector2d ;
			var normal:Vector2d ;
			var polygon:Polygon2d ;
			var c:Vector2d, d:Vector2d, v:Vector2d ;
			
			//	If the polygon a's closest point is not a vertex and
			//	polygon b's closest point is a vertext ...
			if ( !isVertex( polygons[0], a ) && isVertex( polygons[1], b ))
			{
				//	Grab the edge normal on polygon a that is closest to point a
				polygon = polygons[0] ;
				index = getClosestEdgeNormalIndex( polygons[0], a );
				normal = polygons[0].getNormal( index );
				
				//	Resolve the collision with polygon1 colliding into polygon0
				v = resolveCollision( polygons[1], velocity[1].Subtract( velocity[0] ), normal );
				if ( v != null )
				{
					v.normalize();
					v.scale( velocity[1].length );
					updateCentroid( polygons[1], polygons[1].centroid.Add( v ));
					velocity[1] = v ;
					
				}

				
				//	Resolve the collision with polygon0 colliding into polygon1
				polygon = polygons[1] ;
				normal = b.Subtract( polygons[1].centroid );
				v = resolveCollision( polygons[0], velocity[0].Subtract( velocity[1] ), normal );
				if ( v != null )
				{
					v.normalize();
					v.scale( velocity[0].length );
					updateCentroid( polygons[0], polygons[0].centroid.Add( v ));
					velocity[0] = v ;
					
				}
				
				
				//	If polygon a's closest point is a vertex and 
				//	polygon b's closest point is not a vertex
			} else if ( isVertex( polygons[0], a ) && !isVertex( polygons[1], b ))
			{
				//	Grab the edge normal closest to point b	
				polygon = polygons[1] ;
				index = getClosestEdgeNormalIndex( polygons[1], b );
				normal = polygons[1].getNormal( index );
				
				//	Resolve the collision with polygon0 colliding into polygon1
				v = resolveCollision( polygons[0], velocity[0].Subtract( velocity[1] ), normal );
				if ( v != null )
				{
					v.normalize();
					v.scale( velocity[0].length );
					updateCentroid( polygons[0], polygons[0].centroid.Add( v ));
					velocity[0] = v ;
					
				}
				
				//	Resolve the collision with polygon1 colliding into polygon0
				polygon = polygons[0] ;
				normal = a.Subtract( polygons[0].centroid );
				v = resolveCollision( polygons[1], velocity[1].Subtract( velocity[0] ), normal );
				if ( v != null )
				{
					v.normalize();
					v.scale( velocity[1].length );
					updateCentroid( polygons[1], polygons[1].centroid.Add( v ));
					velocity[1] = v ;
					
				}
				
			} else if ( isVertex( polygons[0], a ) && isVertex( polygons[1], b ))
			{
				//	Two vertices
				//	Grab the edge normal closest to point b	
				polygon = polygons[1] ;
				normal = b.Subtract( a ) ;
				
				//	Resolve the collision with polygon0 colliding into polygon1
				v = resolveCollision( polygons[0], velocity[0].Subtract( velocity[1] ), normal );
				if ( v != null )
				{
					v.normalize();
					v.scale( velocity[0].length );
					updateCentroid( polygons[0], polygons[0].centroid.Add( v ));
					velocity[0] = v ;
					
				}
				
				//	Grab the edge normal closest to point a
				polygon = polygons[0] ;
				normal.negate();
				
				//	Resolve the collision with polygon1 colliding into polygon0
				v = resolveCollision( polygons[1], velocity[1].Subtract( velocity[0] ), normal );
				if ( v != null )
				{
					v.normalize();
					v.scale( velocity[1].length );
					updateCentroid( polygons[1], polygons[1].centroid.Add( v ));
					velocity[1] = v ;
					
				}
				
			} else if ( !isVertex( polygons[1], b ) && !isVertex( polygons[1], b ))
			{
				//	Two edges	
				//	Resolve the collision with polygon1 colliding into polygon0
				polygon = polygons[0] ;
				normal = a.Subtract( polygons[0].centroid );
				v = resolveCollision( polygons[1], velocity[1].Subtract( velocity[0] ), normal );
				if ( v != null )
				{
					v.normalize();
					v.scale( velocity[1].length );
					updateCentroid( polygons[1], polygons[1].centroid.Add( v ));
					velocity[1] = v ;
					
				}
				
				//	Resolve the collision with polygon0 colliding into polygon1
				polygon = polygons[1] ;
				v = resolveCollision( polygons[0], velocity[0].Subtract( velocity[1] ), normal );
				if ( v != null )
				{
					v.normalize();
					v.scale( velocity[0].length );
					updateCentroid( polygons[0], polygons[0].centroid.Add( v ));
					velocity[0] = v ;
				}
			}
		}
		
		/**
		 * Moves both polygons half of the closest distance between them 
		 * @param a - The point on polygon a that's closest to polygon b
		 * @param b - The point on polygon b that's closest to polygon a
		 * 
		 */		
		private function movePolygonsTogether( a:Vector2d, b:Vector2d ):Vector.<Vector2d>
		{
			//	Create a collection of velocities
			var velocity:Vector.<Vector2d> = new Vector.<Vector2d>(2,true);
			
			//	Initialize some temp variables
			var d:Vector2d ;
			var index:int ;
			var v:Vector2d, m:Vector2d;
			
			//	Calculate the mid-point between a and b
			var x:Number = ( b.x + a.x )/ 2 ;
			var y:Number = ( b.y + a.y )/ 2 ;
			m = new Vector2d( x, y );
			
			//	Get the vector from polygon a's centroit the point
			//	that's closest to polygon b
			d = a.Subtract( polygons[0].centroid );
			
			//	Get the vertex that's closest to the polygon in a given direction
			index = Polygon2d.getExtremeIndex( polygons[1], d );
			velocity[0] = v = polygons[1].getVertex( index ).Subtract( polygons[0].centroid );
			
			//	Move the polygon in the velocity direction such
			//	that it moves half the distance between a and b in the b - a direction
			d = m.Subtract( a );
			v.normalize();
			v.scale( d.length );
			updateCentroid( polygons[0], polygons[0].centroid.Add( v ));
			
			//	Get the second polygon's velocity
			d = b.Subtract( polygons[1].centroid );
			index = Polygon2d.getExtremeIndex( polygons[0], d );
			velocity[1] = v = polygons[0].getVertex( index ).Subtract( polygons[1].centroid );
			
			//	Move the polygon in the velocity direction such
			//	that is moves half the distance between a and b in the b - a direction
			d = m.Subtract( b );
			v.normalize();
			v.scale( d.length );
			updateCentroid( polygons[1], polygons[1].centroid.Add( v ));
			
			//	Return the velocities
			return velocity ;
			
		}
		
		/**
		 * Calculates the velocity of a polygon after collision 
		 * @param polygon - the colliding polygon
		 * @param relativeVelocity - the difference between the velocity of the colliding polygon
		 * and the velocity of the 'collidee'
		 * @param normal - this must be normalized
		 * 
		 */		
		private function resolveCollision( polygon:Polygon2d, relativeVelocity:Vector2d, normal:Vector2d ):Vector2d
		{
			//	normal must be unit-length and outward facing
			normal.normalize();
			
			//	Make sure the dot product between the normal and the relative velocity is negative
			//	The dot product of the relative velocity and the outward facing normal yields
			//	the component of the relative velocity in the normal direction
			var dp:Number = relativeVelocity.dot( normal );
			if ( dp < 0 )
			{
				//	Get the perpendicular to the normal
				var perp:Vector2d = normal.perp() ;
				
				//	The dot product between the relative velocity and the perp to the normal should be positive
				if ( relativeVelocity.dot( perp ) < 0 )
				{
					perp.negate();
				}
				
				//	Subtract the component of the relative velocity in the
				//	normal direction from the normal perpendicular
				var normalComponent:Vector2d = normal.ScaleBy( dp );
				return perp.Subtract( normalComponent );
					
			}
			
			return null ;
		}
		
		public function updateCentroid( polygon:Polygon2d, centroid:Vector2d ):void
		{
			//	Update the vertices
			var vertices:Vector.<Vector2d> = polygon.vertices ;
			for ( var j:int = 0; j < vertices.length; j++ )
			{
				var vertex:Vector2d = vertices[j] ;	
				vertex.x -= polygon.centroid.x ;
				vertex.y -= polygon.centroid.y ;
				vertex.x += centroid.x ;
				vertex.y += centroid.y ;
			}
			
			polygon.centroid = centroid ;
			polygon.updateLines();
			
		}
		/**
		 * Returns true if the closest point 
		 * @param polygon
		 * @param closestPoint
		 * @return 
		 * 
		 */		
		private function isVertex( polygon:Polygon2d, closestPoint:Vector2d ):Boolean
		{
			var vertices:Vector.<Vector2d> = polygon.vertices ;
			for ( var i:int = 0; i < vertices.length; i++ )
			{
				var vertex:Vector2d = vertices[i] ;
				var diff:Vector2d = closestPoint.Subtract( vertex );
				if ( diff.length < .00001 )
				{
					return true ;	
				}
			}
			return false ;
		}
		
		private function getVertexIndex( polygon:Polygon2d, closestPoint:Vector2d ):int
		{
			var vertices:Vector.<Vector2d> = polygon.vertices ;
			for ( var i:int = 0; i < vertices.length; i++ )
			{
				var vertex:Vector2d = vertices[i] ;
				var diff:Vector2d = closestPoint.Subtract( vertex );
				if ( diff.length < .00001 )
				{
					return i ;	
				}
			}
			return -1 ;
		}
		/**
		 * Returns the edge normal that's closest to the given point
		 * @return 
		 * 
		 */		
		private function getClosestEdgeNormal( polygon:Polygon2d, point:Vector2d ):Vector2d
		{
			
			return polygon.getNormal( getClosestEdgeNormalIndex( polygon, point ) ) ;
		}
		
		/**
		 * Returns the edge normal index that's closest to the given point
		 * @return 
		 * 
		 */		
		private function getClosestEdgeNormalIndex( polygon:Polygon2d, point:Vector2d ):int
		{
			var vertices:Vector.<Vector2d> = polygon.vertices ;
			var dist:Number = Number.MAX_VALUE ;
			var index:int ;
			for ( var i:int = 0; i < vertices.length; i++ )
			{
				var b:Vector2d = vertices[(i + 1) % vertices.length];
				var a:Vector2d = vertices[i] ;
				var edge:Vector2d = b.Subtract( a ) ;
				edge.normalize();
				
				var u:Vector2d = point.Subtract( a );
				u.normalize();
				
				var d:Number = Math.abs( edge.dot( u ) - 1.0 );
				if ( d < dist )
				{
					index = i ;
					dist = d;
				}
			}
			return index ;
		}

		
		
		private function isInside( polygon:Polygon2d, point:Vector2d ):Boolean
		{
			for ( var j:int = 0; j < polygon.vertices.length; j++)
			{
				if ( polygon.normals[j].dot( point.Subtract( polygon.vertices[j] )) > 0 )
				{
					return false ;
				}
			}
			return true ;
		}
		
				
		
		/**
		 * Returs the axis-aligned bounding box (AABB) of a given polygon 
		 * @param polygon
		 * @return 
		 * 
		 */		
		private function getAABB( polygon:Polygon2d ):AABB 
		{
			var xmin:Number = Number.MAX_VALUE ;
			var ymin:Number = Number.MAX_VALUE ;
			var xmax:Number = Number.MIN_VALUE ;
			var ymax:Number = Number.MIN_VALUE ;
			for each ( var vertex:Vector2d in polygon.vertices )
			{
				xmin = Math.min( xmin, vertex.x );
				xmax = Math.max( xmax, vertex.x );
				ymin = Math.min( ymin, vertex.y );
				ymax = Math.max( ymax, vertex.y );
			}
			var aabb:AABB = new AABB( xmin, ymin, xmax, ymax );
			return aabb ;
		}
		
		private function draw( polygons:Vector.<Polygon2d>, color:Number = 0x000000 ):void
		{
			graphics.clear();
			if ( solution != null )
			{
				graphics.lineStyle( 2, 0xff0000 );
				graphics.moveTo( solution.Z[0], solution.Z[1] );
				graphics.lineTo( solution.Z[2], solution.Z[3] );
			}
			
			for ( var i:int = 0; i < polygons.length; i++ )
			{	
				var polygon:Polygon2d = polygons[i] ;
				graphics.lineStyle( 2, color );
				for ( var j:int = 0, k:int = -1; j < polygon.vertices.length; k = j++ )
				{
					var a:Vector2d = polygon.getVertex( k ) ;
					var b:Vector2d = polygon.getVertex( j ) ;
					graphics.moveTo( a.x, a.y );
					graphics.lineTo( b.x, b.y );
				}
				
				var aabb:AABB = aabbs[i] ;
				if ( aabb != null )
				{
					graphics.lineStyle( .5, 0x0000ff ) ;
					graphics.drawRect( aabb.xmin, aabb.ymin, aabb.width, aabb.height ) ;
					
				}
			}
		}
		
		
		/**
		 * Creates a polygon with a number of vertices between
		 * 3 and 6 ; 
		 * 
		 */		
		private function createPolygon( centroid:Vector2d ):Polygon2d
		{
			
			//	Create a polygon
			var polygon:Polygon2d = new Polygon2d( );
			
			//	The polygon should have at least 3 and at most six points
			var points:int = 3 + int( Math.random() * 3 );
			
			//	Add points to the polygon
			var angle:Number = ( Math.PI / 180 ) * ( 360 / points ) ;
			var scale:Number = 40 ;
			for ( var i:int = 0; i < points; i++ )
			{
				var alpha:Number = angle * i ;
				var x:Number = Math.cos( alpha ) - Math.sin( alpha ) ;
				var y:Number = Math.sin( alpha ) + Math.cos( alpha ) ; 
				polygon.addVertex( new Vector2d(( x * scale ) + centroid.x, ( y * scale ) + centroid.y ));
			}
			
			//	Order the polygon vertices counter-clockwise
			polygon.orderVertices();
			
			//	Create the collection of polygon edges
			polygon.updateLines();
			
			//	Create a true
			polygon.createTree();
			
			//	Return the polygon
			return polygon ;
			
		}
	}
}