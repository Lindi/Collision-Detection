package geometry
{
	
	public class Polygon2d
	{
		protected var _edges:Vector<Vector2d>
		protected var _vertices:Vector<Vector2d>
		protected var _normals:Vector<Vector2d>
			
		public function Polygon2d()
		{
		}
		
		public function getVertex( index:int ):Vector2d
		{
			index = ( index + _vertices.length ) % _vertices.length ;
			return _vertices[ index ] ;
		}
		public function getEdge( index:int ):Vector2d
		{
			index = ( index + _edges.length ) % _edges.length ;
			return _edges[ index ] ;
		}
		public function getNormal( index:int ):Vector2d
		{
			index = ( index + _normals.length ) % _normals.length ;
			return _normals[ index ] ;
		}
		public function get numberOfVertices():int
		{
			return _vertices.length ;
		}
		
		protected function addVertex( vertex:Vector2d ):int
		{
			return _vertices.push( vertex ) - 1 ;
		}
	}
}