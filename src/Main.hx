class Main
{//}
	
	static function main() {
		//haxe.Firebug.redirectTraces();
		var root = flash.Lib.current;
		var gmc = new flash.display.MovieClip();
		root.addChild(gmc);
		var uimc = new flash.display.MovieClip();
		root.addChild(uimc);
		
		var logo = new interf.Logo();
		logo.y = 1;
		root.addChild(logo);
		
		var ui = new mt.deepnight.Interface(uimc, Game.WID, Game.HEI);
		var m = new Game(gmc,ui);
	}
	
}
