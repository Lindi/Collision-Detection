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
			
			//	Calculate distance
			calculateDistance();
			
			//	Draw the polygons
			draw( polygons );
			
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
		
		private function mouseDown( event:Event ):void
		{
			//	Check to see which polygon, if any, the mouse is inside of
			//	This should probably be done on a rollover, but for now we'll
			//	do it this way
			var mouse:Vector2d = new Vector2d( this.mouseX, this.mouseY );
			for ( var i:int = 0; i < polygons.length; i++)
			{
				var polygon:Polygon2d = polygons[i] ;
				var mouseInside:Boolean = isInside( polygon, mouse );
				if ( mouseInside )
				{
					currentPolygon = i ;
					offset = polygon.centroid.Subtract( mouse );
					addEventListener( Event.ENTER_FRAME, frame );
					stage.addEventListener( MouseEvent.MOUSE_UP, mouseUp );
					stage.removeEventListener( MouseEvent.MOUSE_DOWN, mouseDown );
					break ;
				}
			}
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
		
		
		private function mouseUp( event:Event ):void
		{
			currentPolygon = -1 ;
			removeEventListener( Event.ENTER_FRAME, frame );
			stage.addEventListener( MouseEvent.MOUSE_DOWN, mouseDown ) ;
			stage.removeEventListener( MouseEvent.MOUSE_UP, mouseUp );
		}
		
		/**
		 * Enter frame handler 
		 * @param event
		 * 
		 */		
		private function frame( event:Event ):void
		{
			//	Mouse location
			var mouse:Vector2d = new Vector2d( mouseX, mouseY );
			
			//	Determine which polygon the mouse is inside
			var n:int = polygons[currentPolygon].vertices.length ;
			
			//	Constrain the centroid so that the polygon doesn't
			//	go into a negative quadrant of the stage
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
			
			//	Calculate the distance between them
			calculateDistance();
			
			//	Draw them
			draw( polygons );
			
		}
		
		private function draw( polygons:Vector.<Polygon2d> ):void
		{
			graphics.clear();
			if ( solution != null )
			{
				graphics.lineStyle( 2, 0xff0000 );
				graphics.moveTo( solution.Z[0], solution.Z[1] );
				graphics.lineTo( solution.Z[2], solution.Z[3] );
			}
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