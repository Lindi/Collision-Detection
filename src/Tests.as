package
{
	import flash.display.Sprite;
	
	import org.flexunit.internals.TraceListener;
	import org.flexunit.runner.FlexUnitCore;
	import tests.geometry.Suite ;
	import tests.adt.Suite ;
	import tests.util.Suite ;
	
	
	public class Tests extends Sprite
	{
		private var core:FlexUnitCore;
		private var listener:TraceListener ;
		
		public function Tests()
		{
			core = new FlexUnitCore();
			listener = new TraceListener();
			core.addListener( listener );
			core.run( tests.geometry.Suite );
			core.run( tests.adt.Suite );
			core.run( tests.util.Suite );
		}
	}
}