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
		private var polygons:Vector.<Polygon2d> ;
		private var currentPolygon:int = -1 ;
		private var offset:Vector2d ;
		private var solution:Object ;
		
		public function PolygonCollisionDetection()
		{
			super();
			polygons = new Vector.<Polygon2d>(2,true);
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
						
			//	Calculate distance
			calculateDistance();
			
			//	Draw the polygons
			draw( polygons );
			
			//	Listen for mouse up
			stage.addEventListener( MouseEvent.CLICK, click );
			
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
				//	Move the polygons together
				//	TODO: return a vector of velocities from this function
				//	and translate point a and b by the respective velocities
				var velocity:Vector.<Vector2d> = movePolygonsTogether( a, b );
				a.add( velocity[0] );
				b.add( velocity[1] );

				//	Determine which closest point lies on an edge
				var index:int = -1;
				var edge:Vector2d ;
				var normal:Vector2d ;
				var polygon:Polygon2d ;
				var c:Vector2d, d:Vector2d ;
				
				if ( !isVertex( polygons[0], a ) && isVertex( polygons[1], b ))
				{
					//	Grab the edge normal closest to point a
					polygon = polygons[0] ;
					index = getClosestEdgeNormalIndex( polygons[0], a );
					normal = polygons[0].getNormal( index );
					
					//	Resolve the collision with polygon1 colliding into polygon0
					resolveCollision( polygon[1], velocity[1].Subtract( velocity[0] ), normal );
					
					//	Resolve the collision with polygon0 colliding into polygon1
					polygon = polygons[1] ;
					normal = b.Subtract( polygons[1].centroid );
					resolveCollision( polygon[0], velocity[0].Subtract( velocity[1] ), normal );
					
				} else if ( isVertex( polygons[0], a ) && !isVertex( polygons[1], b ))
				{
					//	Grab the edge normal closest to point b	
					polygon = polygons[1] ;
					index = getClosestEdgeNormalIndex( polygons[1], b );
					normal = polygons[1].getNormal( index );
					
					//	Resolve the collision with polygon1 colliding into polygon0
					resolveCollision( polygon[0], velocity[0].Subtract( velocity[1] ), normal );
					
					//	Resolve the collision with polygon0 colliding into polygon1
					polygon = polygons[0] ;
					normal = a.Subtract( polygons[0].centroid );
					resolveCollision( polygon[1], velocity[1].Subtract( velocity[0] ), normal );

				} else if ( isVertex( polygons[0], a ) && isVertex( polygons[1], b ))
				{
					//	Two vertices
					//	Grab the edge normal closest to point b	
					polygon = polygons[1] ;
					index = getClosestEdgeNormalIndex( polygons[1], b );
					normal = polygons[1].getNormal( index );
					
					//	Resolve the collision with polygon1 colliding into polygon0
					resolveCollision( polygon[0], velocity[0].Subtract( velocity[1] ), normal );
					
					//	Grab the edge normal closest to point a
					polygon = polygons[0] ;
					index = getClosestEdgeNormalIndex( polygons[0], a );
					normal = polygons[0].getNormal( index );
					
					//	Resolve the collision with polygon1 colliding into polygon0
					resolveCollision( polygon[1], velocity[1].Subtract( velocity[0] ), normal );

				} else if ( !isVertex( polygons[1], b ) && !isVertex( polygons[1], b ))
				{
					//	Two edges	
					//	Resolve the collision with polygon0 colliding into polygon1
					polygon = polygons[0] ;
					normal = a.Subtract( polygons[0].centroid );
					resolveCollision( polygon[1], velocity[1].Subtract( velocity[0] ), normal );
					
					//	Resolve the collision with polygon0 colliding into polygon1
					polygon = polygons[1] ;
					normal = b.Subtract( polygons[1].centroid );
					resolveCollision( polygon[0], velocity[0].Subtract( velocity[1] ), normal );

				}
				
			}
			
			//	Draw the polygons
			draw( polygons, 0xaaaaaa );			
		}
		
		/**
		 * Moves both polygons half of the closest distance between them 
		 * @param a
		 * @param b
		 * 
		 */		
		private function movePolygonsTogether( a:Vector2d, b:Vector2d ):Vector.<Vector2d>
		{
			//	Create a collection of velocities
			var velocity:Vector.<Vector2d> = new Vector.<Vector2d>(2,true);
			
			//	Initialize some temp variables
			var d:Vector2d ;
			var index:int ;
			
			//	Get the first polygon's velocity
			var v:Vector2d, m:Vector2d;
			
			var x:Number = ( b.x + a.x )/ 2 ;
			var y:Number = ( b.y + a.y )/ 2 ;
			m = new Vector2d( x, y );
			
			//	Get the first polygon's velocity
			d = a.Subtract( polygons[0].centroid );
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
			//	Make sure the dot product between the normal and the relative velocity is negative
			var dp:Number = relativeVelocity.dot( normal );
			if ( dp < 0 )
			{
				//	Get the perpendicular to the normal
				var perp:Vector2d = normal.perp() ;
				
				//	The dot product between the relative velocity and the perp to the normal should be positive
				if ( relativeVelocity.dot( normal ) < 0 )
				{
					perp.negate();
				}
				
				//	Get the component of the relative velocity in the normal direction
				
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
		 * Enter frame handler 
		 * @param event
		 * 
		 */		
		private function frame( event:Event ):void
		{
			//	Mouse location
			//	TODO: Remove mouse check
			var mouse:Vector2d = new Vector2d( mouseX, mouseY );
			
			//	Determine which polygon the mouse is inside
			//	TODO: Remove mouse check
			var n:int = polygons[currentPolygon].vertices.length ;
			
			//	Constrain the centroid so that the polygon doesn't
			//	go into a negative quadrant of the stage
			//	TODO: Iterate over both polygons and constrain each

			var min:Vector2d = new Vector2d( Number.MAX_VALUE, Number.MAX_VALUE );
			var max:Vector2d = new Vector2d( );
			for ( var i:int = 0; i < n; i++ )
			{
				var vertex:Vector2d = polygons[currentPolygon].vertices[i].Subtract( polygons[currentPolygon].centroid ) ;
				min.x = Math.min( vertex.x, min.x );
				min.y = Math.min( vertex.y, min.y );
				max.x = Math.max( vertex.x, max.x );
				max.y = Math.max( vertex.y, max.y );
			}
			//	TODO: Add each polygon's velocity to each polygon's centroid
			var centroid:Vector2d = mouse.Add( offset );
			centroid.x = Math.max( centroid.x, Math.abs(min.x-2));
			centroid.y = Math.max( centroid.y, Math.abs(min.y-2));
			centroid.x = Math.min( centroid.x, stage.stageWidth - ( max.x + 2));
			centroid.y = Math.min( centroid.y, stage.stageHeight - ( max.y + 2));
			for ( i = 0; i < n; i++ )
			{
				vertex = polygons[currentPolygon].vertices[i] ;
				vertex.subtract( polygons[currentPolygon].centroid );
				vertex.add( centroid ) ;
			}
			
			polygons[currentPolygon].centroid = centroid ;
			polygons[currentPolygon].orderVertices();			
			polygons[currentPolygon].updateLines();
			
			//	TODO: Check for AABB intersection and/or polygon intersection
			//	TODO: Move the code from the click handler to here
			//	TODO: Remove the click handler
		}
		
		private function draw( polygons:Vector.<Polygon2d>, color:Number = 0x000000 ):void
		{
			//graphics.clear();
			if ( solution != null )
			{
				graphics.lineStyle( 2, 0xff0000 );
				graphics.moveTo( solution.Z[0], solution.Z[1] );
				graphics.lineTo( solution.Z[2], solution.Z[3] );
			}
			graphics.lineStyle( 2, color );
			for ( var i:int = 0; i < polygons.length; i++ )
			{	
				var polygon:Polygon2d = polygons[i] ;
				for ( var j:int = 0, k:int = -1; j < polygon.vertices.length; k = j++ )
				{
					var a:Vector2d = polygon.getVertex( k ) ;
					var b:Vector2d = polygon.getVertex( j ) ;
					graphics.moveTo( a.x, a.y );
					graphics.lineTo( b.x, b.y );
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