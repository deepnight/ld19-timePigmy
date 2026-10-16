import mt.deepnight.Tweenie;

using mt.deepnight.SuperMovie;

class Discoveries {
	public static var ALL = {
		var h = new Hash();
		h.set("toiletbook",	"Book pages are good to clean up my private parts.");
		h.set("destroypaint","Pixel art is much more beautiful!");
		h.set("rain",		"Rain is wet.");
		h.set("toilettv",	"If I had a TV, I would put in here.");
		//h.set("garagetv",	"Real men should have TV in their garage.");
		h.set("toiletsofa",	"So much comfier than a sofa.");
		h.set("picktoilet",	"I invented the Grenade (kids, don't do that at home)");
		h.set("pickbook",	"Dictionnary is heavy. Good weapon.");
		h.set("inmybed",	"Ok, this is my bed. Gimme love now.");
		h.set("discovery",	"Hey! I can discover things! That's cool!");
		h.set("picksofa",	"Sofa are heavy. And soft.");
		h.set("carcomp",	"I like embedded systems");
		h.set("sofalove",	"Can we do it on the sofa ?");
		h.set("unlock",		"Keys can make things explode : fuuuun");
		h.set("pickcomputer","Oh, mammoths positions are on google map.");
		h.set("unfreeze",	"Breaking the ice is eaaasy");
		h.set("kidnap",		"Cellar is good for storing females.");
		h.set("picklady",	"Urk urk... Dating!");
		h.set("ladyfrozen",	"Ooooh, ice can preserve youth of my beloved.");
		h.set("bedlove",	"Consensual relationship!");
		h.set("cute",		"Rabbits make things cuter.");
		h.set("cardestroy",	"Car is weaker than mammoth.");
		h.set("cosycave",	"A cellar can be cosy, too.");
		//h.set("throw",		"Hey! I can also throw things  !");
		//h.set("pick",		"I can pick things using my hands : so cool !");
		//h.set("transform",	"Turning things into others... Soooo weird.");
		h.set("stair",		"Stairs are so much better than ladder!");
		h.set("trampoline",	"I like to bounce on a settee.. urk urk.");
		h.set("patience",	"Doing nothing is cool too.");
		h.set("altitude",	"Damn, I invented vertigo!");
		h.set("destroy",	"Broken things take less space.");
		h.set("carpet",		"I should consider adding a carpet in my cave.");
		h.set("door",		"Doors can hide all my nasty secrets.");
		h.set("rabbitcook",	"Rabbit don't like microwaves. No no no no.");
		h;
	}
	
	var done		: Hash<Bool>;
	var list		: List<flash.display.Sprite>;
	
	public function new() {
		done = new Hash();
		list = new List();
	}
	
	public function countDone() {
		return Lambda.count(done);
	}
	public function countAll() {
		return Lambda.count(ALL);
	}
	
	public function getRatio() {
		return Lambda.count(done) / Lambda.count(ALL);
	}
	
	public function get(k:String, ?fl_silent=false) {
		k = k.toLowerCase();
		if (!ALL.exists(k))
			throw "unknown discovery "+k;
		if (done.exists(k))
			return;
			
		if ( Game.ME.inRoom("grotte") )
			if (k!="discovery" && k!="rain")
				return;
			
		Game.ME.gainScore(10, fl_silent);
		done.set(k,true);
		
		if (!fl_silent) {
			Game.ME.playSound("Discovery",0.8);
			Game.ME.updateBar(true);
			var mc = new flash.display.Sprite();
			Game.ME.root.addChild(mc);

			var format = new flash.text.TextFormat();
			format.size = 12;
			format.color = 0x95A9D9;
			format.font = "Verdana";
			format.align = flash.text.TextFormatAlign.RIGHT;
			
			var tf = new flash.text.TextField();
			mc.addChild(tf);
			tf.mouseEnabled = false;
			tf.width = Game.WID;
			tf.text = "You discovered something :";
			tf.setTextFormat(format);
			
			format.color = 0xffffff;
			format.size = 18;
			format.bold = true;
			var tf = new flash.text.TextField();
			mc.addChild(tf);
			tf.y = 12;
			tf.mouseEnabled = false;
			tf.width = Game.WID;
			tf.text = ALL.get(k);
			tf.setTextFormat(format);
			
			mc.alpha = 0;
			var tx = Std.int(-Game.ME.bar.x);
			mc.x = tx+200;
			mc.y = Game.ME.bar.y-50;
			mc.filters = [new flash.filters.GlowFilter(0x0,1,2,2,10), new flash.filters.GlowFilter(0x0,0.8, 8,8, 2) ];
			
			var me = this;
			Game.TW.create(mc, "alpha", 1, TEaseIn, 250);
			Game.TW.create(mc, "x", tx, TElasticEnd, 250);
			haxe.Timer.delay( function() {
				Game.TW.create(mc, "alpha", 0,TEaseOut, 1500).onEnd = function() {
					me.list.remove(mc);
					mc.parent.removeChild(mc);
				}
			}, 4000);

			for (mc in list)
				mc.y-=35;
			list.add(mc);
		}
	}
}
