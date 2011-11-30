package
{
	//import SeparatingAxes ;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import geometry.AABB;
	import geometry.Polygon2d;
	import geometry.Vector2d;
	
	import physics.PolygonDistance;
	import physics.PolygonIntersection;
	import physics.lcp.LcpSolver;
	
	[SWF(width='400',height='400')]
	public class CollisionResponse extends Sprite
	{
		private var polygons:Vector.<Polygon2d> = new Vector.<Polygon2d>(2,true);
		private var aabbs:Vector.<AABB> = new Vector.<AABB>(2,true);
		private var velocity:Vector.<Vector2d> = new Vector.<Vector2d>(2,true);
		private var t:Number ;
		private var timer:Timer ;

		public function CollisionResponse()
		{
			super();
			init( );
		}
		
		private function init( ):void
		{
			//	Velocity components
			var dx:Number, dy:Number ;
			
			//	Create a polygon 
			var centroid:Vector2d = new Vector2d( stage.stageWidth/2, stage.stageHeight/2 ) ;
			polygons[0] = createPolygon( centroid );
			dx = 80 + int( Math.random() * 10 ) * ( 1 - 2 * int( Math.random() * 2 ));
			dy = 80 + int( Math.random() * 10 ) * ( 1 - 2 * int( Math.random() * 2 ));
			velocity[0] = new Vector2d( dx, dy );
			
			//	Create another polygon, and make sure they don't intersect
			centroid = new Vector2d( centroid.x + 100, centroid.y + 100 ) ;
			polygons[1] = createPolygon( centroid );
			
			do
			{
				dx = 80 + int( Math.random() * 10 ) * ( 1 - 2 * int( Math.random() * 2 ));
			} while ( dx == velocity[0].x )
			
			do
			{
				dy = 80 + int( Math.random() * 10 ) * ( 1 - 2 * int( Math.random() * 2 ));
			} while ( dy == velocity[0].y )
			
			velocity[1] = new Vector2d( dx, dy );
			
			//	Mark the time
			t = getTimer() ;
			
			//	Enter frame draws everything
			addEventListener( Event.ENTER_FRAME, frame );
			//draw( 0x000000 ) ;
		}
		
		/**
		 * Frame event handler 
		 * @param event
		 * 
		 */		
		private function frame( event:Event ):void
		{
			
			//	Get the time since the last frame
			var t:Number = getTimer();
			var dt:Number = ( t - this.t )/1000 ;
			this.t = t ;
			
			//	Get the axis-aligned bounding boxes			
			for ( var i:int = 0; i < polygons.length; i++ )
			{
				//	Grab a polygon
				var polygon:Polygon2d = polygons[i];
				
				//	Get the AABB
				var aabb:AABB = aabbs[i] = getAABB( polygon ) ;
			}
			
			//	Do collision detection with stage edges
			for ( i = 0; i < polygons.length; i++ )
			{
				//	Grab a polygon
				polygon = polygons[i];
				polygon.moved = false ;
				
				//	Get the AABB
				aabb = aabbs[i] ;
				
				
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
				aabb = aabbs[i] = getAABB( polygon ) ;
			}

			//	Do their AABBs intersect?
			var aabbsIntersect:Boolean = true ;
			aabbsIntersect &&= !( aabbs[0].xmin > aabbs[1].xmax ) ;
			aabbsIntersect &&= !( aabbs[1].xmin > aabbs[0].xmax ) ;
			aabbsIntersect &&= !( aabbs[0].ymin > aabbs[1].ymax ) ;
			aabbsIntersect &&= !( aabbs[1].ymin > aabbs[0].ymax ) ;
			
			var color:Number = 0x000000 ;
			
			
			//	Do the collision response here ...
			if ( aabbsIntersect )
			{
				
				var polygonsIntersect:Boolean = SeparatingAxes.testIntersection( polygons[0], polygons[1] );
				var distance:Number, minDistance:Number ;
				if ( polygonsIntersect )
				{
					//	Separate the AABBs
					var intersection:AABB = new AABB();
					aabbs[0].findIntersection( aabbs[1], intersection );
					var w:Number = intersection.width ;
					var h:Number = intersection.height ;
					var d:Number = Math.sqrt( w * w + h * h ) ;
					//var d:Number = Math.min( intersection.width, intersection.height ) ;
					
					//	Normalize the vector between the centroids and
					//	move the polygons by this distance
					var v:Vector2d = polygons[1].centroid.Subtract( polygons[0].centroid );
//					v.normalize();
//					if ( polygons[0].moved && !polygons[1].moved )
//					{
//						//	Move polygon 1
//						centroid = polygons[1].centroid.Add( v.ScaleBy( d ));
//						updateCentroid( polygons[1], centroid ) ;
//						polygons[1].moved = true ;
//						
//					} else if ( !polygons[0].moved && polygons[1].moved )
//					{
//						//	Move polygon 0
//						centroid = polygons[0].centroid.Add( v.Negate().ScaleBy( d ));
//						updateCentroid( polygons[0], centroid ) ;
//						polygons[0].moved = true ;
//						
//					} else 
					{
						//	Move them both half the distance
						//	Move polygon 0
						centroid = polygons[0].centroid.Add( v.Negate().ScaleBy( d/2 ));
						updateCentroid( polygons[0], centroid ) ;
						polygons[0].moved = true ;
						
						
						//	Move polygon 1
						centroid = polygons[1].centroid.Add( v.ScaleBy( d/2 ));
						updateCentroid( polygons[1], centroid ) ;
						polygons[1].moved = true ;
						
					}
				}
				
				polygonsIntersect = SeparatingAxes.testIntersection( polygons[0], polygons[1] );
				if ( polygonsIntersect )
				{
					throw new Error("Polygons should not be intersecting after we've moved their AABBs apart.");
				}
				
				var solution:Object = PolygonDistance.distance( polygons[0], polygons[1] );
				if ( solution.status == LcpSolver.FOUND_SOLUTION )
				{ 
					var a:Vector2d = new Vector2d( solution.Z[0], solution.Z[1] );
					var b:Vector2d = new Vector2d( solution.Z[2], solution.Z[3] );
					distance = b.Subtract( a ).length ;
					minDistance = .4 ;
					
					if ( distance < minDistance )
					{
//						var u:Vector2d ;
//						u = collisionResponse( polygons[0], polygons[1], velocity[0], velocity[1], a, distance );
//						v = collisionResponse( polygons[1], polygons[0], velocity[1], velocity[0], b, distance );
//						if ( u != null )
//						{
//							velocity[0] = u.ScaleBy( velocity[0].length ) ; 
//						}
//						if ( v != null )
//						{
//							velocity[1] = v.ScaleBy( velocity[1].length ) ; 
//						}
						
						//	Move b half the distance
						var relativePosition:Vector2d = polygons[0].centroid.Subtract( polygons[1].centroid );
						relativePosition.normalize();

						centroid = polygons[0].centroid.clone();
						centroid.Add( relativePosition..Negate().ScaleBy( distance/2 ));
						updateCentroid( polygons[0], centroid ) ;
						
						//	Move a half the distance
						centroid = polygons[1].centroid.clone();
						centroid.Add( relativePosition.ScaleBy( distance/2 ));
						updateCentroid( polygons[1], centroid ) ;

						var normal:Vector2d = getNormal( polygons[0], a );
						normal.normalize();
						var relativeVelocity:Vector2d = velocity[1].Subtract( velocity[0] );
						
						if ( normal.dot( relativeVelocity ) < 0 )
						{
							//	We know we're colliding, so calculate the change in velocity
							//	and update accordingly
							var perp:Vector2d = normal.perp();
							if ( relativeVelocity.dot( perp ) < 0 )
							{
								perp.negate();
							}
							var newVelocity:Vector2d = perp.Subtract( normal.ScaleBy(normal.dot( relativeVelocity )));
							//newVelocity.normalize();
							v = newVelocity.clone() ; //velocity[1].Add( newVelocity.ScaleBy( velocity[1].length ));
							v.scale( velocity[1].length );
							
							//	We know we're colliding, so calculate the change in velocity
							//	and update accordingly
							relativeVelocity = velocity[0].Subtract( velocity[1] );
							normal = getNormal( polygons[1], b );
							perp = normal.perp();
							if ( relativeVelocity.dot( perp ) < 0 )
							{
								perp.negate();
							}
							newVelocity = perp.Subtract( normal.ScaleBy(normal.dot( relativeVelocity )));
							newVelocity.scale( velocity[0].length );
							//newVelocity.normalize();
							velocity[0].x = newVelocity.x ; //velocity[0].Add( newVelocity.ScaleBy( velocity[0].length ));
							velocity[0].y = newVelocity.y ;
							velocity[1].x = v.x ;
							velocity[1].y = v.y ;
							trace( "velocity[0]", velocity[0], "velocity[1]", velocity[1] );
							
							
							
						}
						
						
					}
				}
			}

			//	Move and rotate polygons
			for ( i = 0; i < polygons.length; i++)
			{
				//	
				polygon = polygons[i] ;
				
				centroid = polygon.centroid.clone() ;
				
				//	Move the polygons
				centroid.x += ( velocity[i].x * dt ) ;
				centroid.y += ( velocity[i].y * dt ) ;
				
				updateCentroid( polygon, centroid ) ;
				
//				//	Rotate the polygons
//				var vertices:Vector.<Vector2d> = polygon.vertices ;
//				for ( var j:int = 0; j < vertices.length; j++ )
//				{
//					alpha = 0;
//					var vertex:Vector2d = vertices[j] ;	
//					vertex.x -= polygon.centroid.x ;
//					vertex.y -= polygon.centroid.y ;
//					var x:Number = vertex.x * Math.cos( alpha ) - vertex.y * Math.sin( alpha ) ;
//					var y:Number = vertex.x * Math.sin( alpha ) + vertex.y * Math.cos( alpha ) ; 
//					vertex.x = x + centroid.x ;
//					vertex.y = y + centroid.y ;
//				}
//				polygon.centroid.x = centroid.x ;
//				polygon.centroid.y = centroid.y ;
				
				//	Update their lines
				//polygon.updateLines();
			}
			
			
			draw( 0x000000 );
		}
		
		private function draw( color:Number ):void
		{
			//	Draw each polygon
			//var color:Number = 0 ;
			graphics.clear();
			for ( var i:int = 0; i < polygons.length; i++ )
			{
				var polygon:Polygon2d = polygons[i];
				
				//	Draw the polygon
				graphics.lineStyle( 3, color );
				for ( var j:int = 0; j < polygon.vertices.length; j++ )
				{
					var x:Number = polygon.vertices[j].x ;
					var y:Number = polygon.vertices[j].y ;
					var vertex:Vector2d = polygon.getVertex( j-1);
					graphics.moveTo( vertex.x, vertex.y);
					graphics.lineTo( x, y ) ;
				}
				
//				//	Draw the aabb
//				var aabb:AABB = aabbs[i] ;
//				graphics.lineStyle( 1, 0xff0000 );
//				graphics.moveTo( aabb.xmin, aabb.ymin );
//				graphics.lineTo( aabb.xmax, aabb.ymin );
//				graphics.lineTo( aabb.xmax, aabb.ymax );
//				graphics.lineTo( aabb.xmin, aabb.ymax );
//				graphics.lineTo( aabb.xmin, aabb.ymin );
			}
			
		}
		/**
		 * Returns a vector that is the new velocity of the polygon after collision 
		 * @param a
		 * @param b
		 * @return 
		 * 
		 */		
		private function collisionResponse( a:Polygon2d, b:Polygon2d, u:Vector2d, v:Vector2d, closestPoint:Vector2d, distance:Number ):Vector2d
		{
			
			var relativePosition:Vector2d = a.centroid.Subtract( b.centroid );
			relativePosition.normalize();
			var centroid:Vector2d ;
			
//			//	Move the polygons together
//			if ( a.moved && !b.moved )
//			{
//				//	Move b the full distance
//				centroid = b.centroid.clone();
//				centroid.Add( relativePosition.ScaleBy( distance ));
//				b.centroid = centroid ;
//				b.updateLines();
//				
//			} else if ( b.moved && !a.moved )
//			{
//				//	Move a the full distance
//				centroid = a.centroid.clone();
//				centroid.Add( relativePosition.Negate().ScaleBy( distance ));
//				a.centroid = centroid ;
//				a.updateLines();
//				
//			} else
//			{
//				//	Move b half the distance
//				centroid = b.centroid.clone();
//				centroid.Add( relativePosition.ScaleBy( distance/2 ));
//				b.centroid = centroid ;
//				b.updateLines();
//				
//				//	Move a half the distance
//				centroid = a.centroid.clone();
//				centroid.Add( relativePosition.Negate().ScaleBy( distance/2 ));
//				a.centroid = centroid ;
//				a.updateLines();
//			}
			
			
//			var edge:Vector2d = getClosestEdge( a.vertices, closestPoint );
//			var normal:Vector2d = edge.perp();
//			var relativeVelocity:Vector2d = velocity[0].Subtract( velocity[1] );
//			if ( normal.dot( relativeVelocity ) >= 0 )
//			{
//				//	They're separating, don't do anything
//				//	Return the null vector so we know not to change the
//				//	the velocity of either polygon
//				return null ; 
//			} else
//			{
//				//	We know we're colliding, so calculate the change in velocity
//				//	and update accordingly
//				var perp:Vector2d = normal.perp();
//				var newVelocity:Vector2d = perp.Subtract( normal.ScaleBy(normal.dot( relativeVelocity )));
//				newVelocity.normalize();
//				return newVelocity ;
//				
//			}
			
			
			
			
			return null ;
		}
		
		/**
		 * Returns the edge that's closest to the given point
		 * @return 
		 * 
		 */		
		private function getNormal( polygon:Polygon2d, point:Vector2d ):Vector2d
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
			return polygon.getNormal( index ) ;
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