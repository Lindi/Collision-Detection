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
	
	import physics.PolygonIntersection;
	
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
			
			//	Resolve the collision (if any)
			//PolygonIntersection.ResolveIntersection( polygons[0], polygons[1], velocity[0], velocity[1], dt );
			
			//	Do collision detection with stage edges
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
				
				//	Get the AABB
				aabb = aabbs[i] ;
				
				
				var offstage:Boolean = ( aabb.xmin <= 0 )
					|| ( aabb.xmax >= stage.stageWidth )
					|| ( aabb.ymin <= 0 )
					|| ( aabb.ymax >= stage.stageHeight );
				
				//if ( offstage )
				{
					//	Get the centroid
					var centroid:Vector2d = polygon.centroid.clone() ;
					
				}
				
				if ( aabb.xmin <= 0 )
				{
					if ( velocity[i].dot( new Vector2d( 1, 0 )) < 0 )
					{
						velocity[i].x = -velocity[i].x ;
						centroid.x -= aabb.xmin ;
					}
				}
				if ( aabb.xmax >= stage.stageWidth )
				{
					if ( velocity[i].dot( new Vector2d( -1, 0 )) < 0 )
					{
						velocity[i].x = -velocity[i].x ;
						centroid.x -= ( aabb.xmax - stage.stageWidth ) ;
					}
				}
				if ( aabb.ymin <= 0 )
				{
					if ( velocity[i].dot( new Vector2d( 0, 1 )) < 0 )
					{
						velocity[i].y = -velocity[i].y ;
						centroid.y -= aabb.ymin ;
					}
				}
				if ( aabb.ymax >= stage.stageHeight )
				{
					if ( velocity[i].dot( new Vector2d( 0, -1 )) < 0 )
					{
						velocity[i].y = -velocity[i].y ;
						centroid.x -= ( aabb.ymax - stage.stageHeight ) ;
					}
				}
				//	Update the vertices
				var vertices:Vector.<Vector2d> = polygon.vertices ;
				for ( var j:int = 0; j < vertices.length; j++ )
				{
					var alpha:Number = 0;
					var vertex:Vector2d = vertices[j] ;	
					vertex.x -= polygon.centroid.x ;
					vertex.y -= polygon.centroid.y ;
					vertex.x += centroid.x ;
					vertex.y += centroid.y ;
				}
				
				polygon.centroid = centroid ;
				polygon.updateLines();
				
			}
			
			//	Do their AABBs intersect?
			var intersect:Boolean = true ;
			intersect &&= !( aabbs[0].xmin > aabbs[1].xmax ) ;
			intersect &&= !( aabbs[1].xmin > aabbs[0].xmax ) ;
			intersect &&= !( aabbs[0].ymin > aabbs[1].ymax ) ;
			intersect &&= !( aabbs[1].ymin > aabbs[0].ymax ) ;
			
			var color:Number = 0 ;
			
			if ( intersect )
			{
				//	If TestIntersection returns true, then we know that the polygons will intersect within
				//	this time interval
				//if ( SeparatingAxes.testIntersection( polygons[0], polygons[1] ))
				{
					//	This is when things get interesting
					var foo:Boolean, bar:Boolean ;
					
					//foo = SeparatingAxes.testIntersection( polygons[0], polygons[1] );
					
					var interval:Object = { tmax: dt, tfirst: 0, tlast: Number.MAX_VALUE };
					bar = PolygonIntersection.TestIntersection( polygons[0], polygons[1], velocity[0], velocity[1], interval );
					
					
					if ( bar )
					{
						color = 0x00ff00 ;
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
				
				//	Rotate the polygons
				vertices = polygon.vertices ;
				for ( j = 0; j < vertices.length; j++ )
				{
					alpha = 0;
					vertex = vertices[j] ;	
					vertex.x -= polygon.centroid.x ;
					vertex.y -= polygon.centroid.y ;
					var x:Number = vertex.x * Math.cos( alpha ) - vertex.y * Math.sin( alpha ) ;
					var y:Number = vertex.x * Math.sin( alpha ) + vertex.y * Math.cos( alpha ) ; 
					vertex.x = x + centroid.x ;
					vertex.y = y + centroid.y ;
				}
				polygon.centroid.x = centroid.x ;
				polygon.centroid.y = centroid.y ;
				
				//	Update their lines
				polygon.updateLines();
			}

			
			//	Draw each polygon
			//var color:Number = 0 ;
			graphics.clear();
			graphics.lineStyle( 3, color );
			for each ( polygon in polygons )
			{
				
				//	Draw the polygon
				for ( i = 0; i < polygon.vertices.length; i++ )
				{
					x = polygon.vertices[i].x ;
					y = polygon.vertices[i].y ;
					vertex = polygon.getVertex( i-1);
					graphics.moveTo( vertex.x, vertex.y);
					graphics.lineTo( x, y ) ;
				}
			}
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