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
	import physics.PolygonDistance ;
	import physics.lcp.LcpSolver;
	
	
	[SWF(width='600',height='600')]
	public class PolygonClosestPoints extends Sprite
	{
		private var polygons:Vector.<Polygon2d> ;
		private var currentPolygon:int = -1 ;
		private var offset:Vector2d ;
		private var solution:Object ;
		
		public function PolygonClosestPoints()
		{
			super();
			polygons = new Vector.<Polygon2d>(2,true);
			init( );
		}
		private function init( ):void
		{			
			//	Create a polygon 
			var centroid:Vector2d = new Vector2d( stage.stageWidth/2, stage.stageHeight/2 ) ;
			polygons[0] = createPolygon( centroid );
			
			//	Create another polygon, and make sure they don't intersect
			centroid = new Vector2d( centroid.x + 100, centroid.y + 100 ) ;
			polygons[1] = createPolygon( centroid );
			
			//	Enter frame draws everything
			stage.addEventListener( MouseEvent.MOUSE_DOWN, mouseDown ) ;
			stage.addEventListener( MouseEvent.MOUSE_UP, mouseUp );
			
			//	Calculate distance
			calculateDistance();
			
			//	Draw the polygons
			draw( polygons );
			
		}
		
		private function calculateDistance( ):void
		{
			var solution:Object = PolygonDistance.distance( polygons[0], polygons[1] );
			if ( solution.status == LcpSolver.FOUND_SOLUTION )
			{
				this.solution = solution ;
				
			} else
			{
				this.solution = null ;
			}
		}
		
		private function mouseDown( event:Event ):void
		{
			//	Check to see which polygon, if any, the mouse is inside of
			//	This should probably be done on a rollover, but for now we'll
			//	do it this way
			var mouse:Vector2d = new Vector2d( this.mouseX, this.mouseY );
			for ( var i:int = 0; i < polygons.length; i++)
			{
				var polygon:Polygon2d = polygons[i] ;
				var mouseInside:Boolean = true ;
				for ( var j:int = 0; j < polygon.vertices.length; j++)
				{
					if ( polygon.normals[j].dot( mouse.Subtract( polygon.vertices[j] )) > 0 )
					{
						mouseInside = false ;
						break;
					}
				}
				
				if ( mouseInside )
				{
					currentPolygon = i ;
					offset = polygon.centroid.Subtract( mouse );
					addEventListener( Event.ENTER_FRAME, frame );
					break ;
				}
			}
		}
		
		private function mouseUp( event:Event ):void
		{
			currentPolygon = -1 ;
			removeEventListener( Event.ENTER_FRAME, frame );
		}
		
		/**
		 * Enter frame handler 
		 * @param event
		 * 
		 */		
		private function frame( event:Event ):void
		{
			//	Determine which polygon the mouse is inside
			var n:int = polygons[currentPolygon].vertices.length ;
			var mouse:Vector2d = new Vector2d( mouseX, mouseY );
			var centroid:Vector2d = mouse.Add( offset );
			for ( var i:int = 0; i < n; i++ )
			{
				var vertex:Vector2d = polygons[currentPolygon].vertices[i] ;
				vertex.subtract( polygons[currentPolygon].centroid );
				vertex.add( centroid ) ;
			}
			polygons[currentPolygon].centroid = centroid ;
			polygons[currentPolygon].updateLines();
			
			//	Calculate the distance between them
			calculateDistance();
			
			//	Draw them
			draw( polygons );
			
		}
		
		private function draw( polygons:Vector.<Polygon2d> ):void
		{
			graphics.clear();
			graphics.lineStyle( 2, 0x000000 );
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
			
			if ( solution != null )
			{
				graphics.lineStyle( 1, 0x222222 );
				graphics.moveTo( solution.Z[0], solution.Z[1] );
				graphics.lineTo( solution.Z[2], solution.Z[3] );
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