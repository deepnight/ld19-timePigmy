// TODO : remplacer Sprite par Element partout (sauf anims)

import mt.deepnight.Types;
import mt.deepnight.Tweenie;
import flash.ui.Keyboard;
import Entity;
import World;

using mt.deepnight.SuperMovie;

class Game {//}
	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	public static var WORLD : World;
	public static var ME : Game;
	public static var TW : Tweenie;
	public static var UPSCALE = 3;
	public static var BASE_TIME = 60*4;
	public static var DEFAULT_VOLUME = 0.3;
	public static var MAIN_VOLUME = DEFAULT_VOLUME;
	public static var SFX_LIB = new Hash();
	
	var world				: World;
	var hero				: Entity;
	public var root			: MC;
	
	public var buffer		: flash.display.Bitmap;
	public var scene		: flash.display.Sprite;
	var bg					: flash.display.Sprite;
	public var discoveries	: Discoveries;
	var ui					: mt.deepnight.Interface;
	
	public var picked		: Null<Entity>;
	
	var counters		: Hash<Int>;
	var chatCD			: Int;
	var chat			: fx.Chat;
	var lockedKeys		: IntHash<Bool>;
	var timer			: interf.Timer;
	var endTimer		: Int;
	public var bar		: flash.display.Sprite;
	var portal			: Null<Entity>;
	var portal2			: Null<Entity>;
	var suspendStandAnim: Int;
	
	var high			: Int;
	var score			: Int;
	public var lastScore: Null<Int>;
	
	public var fl_lock	: Bool;
	
	//var history		: Array< Array<
	
	#if debug
	var debug		: flash.text.TextField;
	#end
		
	public function new(r,ui) {
		this.ui = ui;
		haxe.Log.setColor(0xffffff);
		ME = this;
		root = r;
		TW = new Tweenie();
		Gfx.init();
		Key.init();
		lockedKeys = new IntHash();
		discoveries = new Discoveries();
		counters = new Hash();
		chatCD = 20;
		fl_lock = false;
		score = 0;
		high = mt.deepnight.Lib.getCookie("ludum", "high", 0);
		
		mt.deepnight.Interface.CANCEL_NOTICE_KEY = Keyboard.SPACE;
		mt.deepnight.Interface.COLOR = 0x883C17;
		ui.addShortcut(Keyboard.NUMPAD_ADD, function() { MAIN_VOLUME+=0.1; if (MAIN_VOLUME>1) MAIN_VOLUME=1; } );
		ui.addShortcut(Keyboard.NUMPAD_SUBTRACT, function() { MAIN_VOLUME-=0.1; if (MAIN_VOLUME<0) MAIN_VOLUME=0; } );
		ui.addShortcut("M".charCodeAt(0), function() { MAIN_VOLUME=if(MAIN_VOLUME==0) DEFAULT_VOLUME else 0;} );
		ui.addShortcut("H".charCodeAt(0), showHelp );
		ui.addShortcut("R".charCodeAt(0), resetGame);
		
		var g = root.graphics;
		g.beginFill(0x0,1);
		g.drawRect(0,0,WID,HEI);
		g.endFill();
		
		world = new World();
		
		scene = new flash.display.Sprite();
		if(UPSCALE==1)
			root.addChild(scene);
		
		hero = new Entity(world, "hero", 6,0);
		hero.sprite.visible = false;
		scene.addChild(hero.sprite);
		hero.sprite.snapPix = true;
		hero.fl_gravity = true;
		hero.sprite.setAnim(Gfx.tiles.getAnim("hero_stand"));
		hero.sprite.filters = [
			//new flash.filters.GlowFilter(0x832D10,1,2,2,10),
			new flash.filters.DropShadowFilter(3,0, 0x0,0.3, 0,0,1),
		];
		
		#if debug
		debug = new flash.text.TextField();
		root.addChild(debug);
		debug.width = 200;
		debug.multiline = true;
		debug.wordWrap = true;
		debug.x = WID-debug.width;
		debug.textColor = 0xffff00;
		debug.text = "debug";
		debug.mouseEnabled = false;
		#end
		
		buffer = new flash.display.Bitmap();
		buffer.scaleX = UPSCALE;
		buffer.scaleY = UPSCALE;
		root.addChild(buffer);
		//render.filters = [
			//new flash.filters.DropShadowFilter(8,90, 0x0,0.2,0,0),
		//];
		
		world.gotoRoom("grotte", 0);
		teleportHero(9,1);
		//world.gotoRoom("bedroom2", 0); teleportHero(Std.int(world.current.width*0.5), 0);
		
		timer = new interf.Timer();
		root.addChild(timer);
		timer.field.text = "00:00";
		timer.x = Std.int(WID*0.5)+10;
		timer.y = HEI-120;
		//timer.filters = [ new flash.filters.GlowFilter(0xffffff, 0.2, 16,10,3, 2) ];
		endTimer = BASE_TIME+1;
		
		var t = new haxe.Timer(1000);
		t.run = onTick;
		onTick();
		
		updateBar(false);
		
		root.addEventListener( flash.events.Event.ENTER_FRAME, main );
		showHelp();
	}
	
	function showHelp() {
		if(!ui.hasNotice())
			notify("Use ARROW keys to move around.\n\nSPACE\tAct.\nH\t\t\tShow help\nM\t\t\tMute sounds\n+\t\t\tVolume up\n-\t\t\tVolume down\nR\t\t\tAbandon (go back to cave)");
	}
	
	public function incCounter(k, ?n=1) {
		if ( !counters.exists(k) )
			counters.set(k,n);
		else
			counters.set(k, counters.get(k)+n);
		return getCounter(k);
	}
	
	public inline function getCounter(k) {
		return
			if ( !counters.exists(k) )
				0;
			else
				counters.get(k);
	}
	
	public function setCounter(k, n) {
		counters.set(k, n);
	}
	
	public function teleportHero(x,y) {
		hero.x = x;
		hero.y = y;
		hero.fl_stable = true;
		hero.dx = 0;
		hero.dy = 0;
		hero.xr = 0.5;
		hero.yr = 0.5;
	}
	
	public function playSound(skey:String, ?vol=1.0) {
		if ( !SFX_LIB.exists(skey) )
			SFX_LIB.set( skey, Type.createEmptyInstance(Type.resolveClass("sfx."+skey)) );
		var chan = SFX_LIB.get(skey).play();
		chan.soundTransform = new flash.media.SoundTransform(vol*MAIN_VOLUME);
	}
	
	public function redraw(?transition=-1) {
		if (bg!=null)
			bg.parent.removeChild(bg);
		bg = world.render();
		scene.addChildAt(bg, 0);
		refreshBuffer(true, transition);
		main(null);
	}
	
	function refreshBuffer(?fl_dispose=false, ?transition=-1) {
		if (UPSCALE==1)
			return;
			
		if ( fl_dispose ) {
			if (buffer.bitmapData!=null)
				if (transition<0)
					buffer.bitmapData.dispose();
				else {
					hero.sprite.visible = false;
					if(picked!=null) picked.sprite.visible = false;
					fl_lock = true;
					//refreshBuffer();
					var tmp = new flash.display.Bitmap(buffer.bitmapData);
					root.addChild(tmp);
					tmp.x = buffer.x;
					tmp.y = buffer.y;
					tmp.width = buffer.width;
					tmp.height = buffer.height;
					var a = switch(transition) {
						case 0	: TW.create(tmp, "alpha", 0, TEaseOut);
						case 1	:
							TW.create(tmp, "alpha", 0, TEaseOut);
							TW.create(tmp, "y", tmp.y+200);
						case 2	:
							TW.create(tmp, "alpha", 0, TEaseOut);
							TW.create(tmp, "y", tmp.y-200);
						case 3	:
							buffer.alpha = 0;
							var b = TW.create(tmp, "alpha", 0, TEaseOut, 2500);
							b.onUpdateT = function(t) {
								var ct = new flash.geom.ColorTransform();
								var f = Math.min(1,t/0.5);
								ct.redOffset = f*255;
								ct.greenOffset = f*255;
								ct.blueOffset = f*255;
								tmp.filters = [ new flash.filters.BlurFilter(t*32,t*32) ];
								if (t>=0.5)
									ct.alphaMultiplier = 1-(t-0.5)/0.5;
								tmp.transform.colorTransform = ct;
								if (t>=0.5 && !TW.exists(ME.buffer, "alpha"))
									TW.create(ME.buffer, "alpha", 1, 500);
							}
							b;
							
					}
					//if(transition!=4) {
						//TW.create(tmp, "scaleX", UPSCALE+0.2, 900);
						//TW.create(tmp, "scaleY", UPSCALE+0.2, 900);
					//}
					a.onEnd = function() {
						tmp.bitmapData.dispose();
						tmp.parent.removeChild(tmp);
						ME.fl_lock = false;
						ME.hero.sprite.visible = true;
						if(ME.picked!=null) ME.picked.sprite.visible = true;
						if (transition==3 && ME.inRoom("cave"))
							ME.notify("You time travelled to 1981, in the basement of a house!\n\nUse SPACE to interact with items : to earn knowledge, simply experiment (like destroying things or throwing objects in certain places).");
					}
				}
			buffer.bitmapData = new flash.display.BitmapData(world.current.width*16, world.current.height*16, true, 0x0);
			if(transition>=0 && transition!=3) {
				buffer.alpha = 0;
				TW.create(buffer, "alpha", 1);
			}
		}
		
		//var matrix = new flash.geom.Matrix();
		//matrix.scale(UPSCALE, UPSCALE);
		buffer.bitmapData.fillRect(buffer.bitmapData.rect, 0x0);
		buffer.bitmapData.draw(scene);
		
		buffer.x = Std.int( WID*0.5 - UPSCALE*world.current.width*16*0.5 );
		buffer.y = Std.int( HEI-90-UPSCALE*world.current.height*16 );
	}
	
	inline function isDownWithLock(k:Int) {
		if ( !Key.isDown(k) && lockedKeys.exists(k) )
			lockedKeys.remove(k);
		return if (Key.isDown(k) && !lockedKeys.exists(k) ) {
			lockedKeys.set(k,true);
			true;
		}
		else false;
	}
	
	public function onDestroy(e:Entity) {
		playSound("Explode",0.5);
		gainScore(1);
		TW.create(root, "x", root.x+2, TShakeBoth);
		explosion(e,30);
		playSound("Explode",0.7);
		discoveries.get("destroy");
		if (e.key=="car")
			discoveries.get("cardestroy");
		if (e.key=="painting")
			discoveries.get("destroypaint");
	}
	
	public function explosion(e:Entity, n:Int, ?forcedCol:Int) {
		if (forcedCol!=null)
			comment();
		for (i in 0...n) {
			var fx = new pix.Part();
			fx.setPos(e.sprite.x, e.sprite.y);
			fx.setGround( (world.current.height-1)*16, 0.8, 0.5 );
			fx.timer = 40+Std.random(70);
			fx.fadeType = 1;
			fx.setPos(e.sprite.x+e.sprite.width*0.5, e.sprite.y+e.sprite.height*0.5);
			if (e.fl_flip)
				fx.xx-=e.sprite.width;
			fx.xx+=Std.random( Std.int( (Std.random(2)*2-1)*e.sprite.width*0.4 ) );
			fx.yy+=Std.random( Std.int( (Std.random(2)*2-1)*e.sprite.height*0.4 ) );
			if (e.key=="portal") {
				fx.xx+=16;
				fx.yy+=16;
			}
			var col =
				if (forcedCol!=null)
					mt.deepnight.Color.offsetColorInt(forcedCol, Std.random(100))
				else
					buffer.bitmapData.getPixel32(Std.int(fx.xx), Std.int(fx.yy));
			fx.vx = (Std.random(150)/100) * (Std.random(2)*2-1);
			fx.vy = -(Std.random(300)/100);
			fx.weight = 0.25;
			var g = fx.graphics;
			g.beginFill(col,1);
			//if(forcedCol!=null)
				//g.drawRect(-1,-3,3,3);
			//else
			var w = Std.random(2)+1;
				g.drawRect(-1,-2, w,w);
			g.endFill();
			scene.addChild(fx);
		}
	}
	
	public inline function heroKey(k:String) {
		return if (picked!=null) "i"+k else k;
	}
	
	public function onHit(e:Entity) {
		if (e.life>0)
			playSound("Hit",0.3);
	}
	
	public inline function inRoom(k:String) {
		return world.current.id.toLowerCase().indexOf(k.toLowerCase())>=0;
	}
	
	public function onEnter(e:Entity) {
		if( e.key=="hero" && e.fl_stable ) {
			if( inRoom("kitchen") && e.x<=2 && e.y==1 )
				discoveries.get("altitude");
			if( inRoom("living") && e.y==world.current.height-2 && incCounter("walk")>=20 )
				discoveries.get("carpet");
			if (inRoom("grotte") && e.x>=2 && e.x<=3 && e.y>=5 && e.y<=6)
				discoveries.get("rain");
			if (inRoom("grotte") && portal!=null && e.x<=2 && e.y>=1 && e.y<=2) {
				onStartGame();
				world.gotoRoom("cave", 3);
				teleportHero(3,1);
			}
		}

		if (e.pickItem==Rabbit && inRoom("kitchen") && e.x==8 && e.y==4) {
			world.destroyItem(e);
			explosion(e, 20, 0xDD0000);
			discoveries.get("rabbitcook");
		}
		if (e.pickItem==LadyGlagla && world.current.id=="kitchen" && e.x==8 && e.y==4) {
			world.transformItem(e, Lady);
			discoveries.get("unfreeze");
		}
		if (e.pickItem==Computer && world.current.id=="cave2" && e.x>=1 && e.x<=4 && e.y>=4)
			discoveries.get("carcomp");
			
		if (e.pickItem==Toilet && inRoom("living") && e.x<=9)
			discoveries.get("toiletsofa");
			
		//if (e.pickItem==Tv && inRoom("cave2"))
			//discoveries.get("garagetv");
		if (e.pickItem==Tv && inRoom("shower"))
			discoveries.get("toilettv");
			
		if (e.pickItem==Sofa && world.current.id.indexOf("cave")>=0)
			discoveries.get("cosycave");
		if (e.pickItem==Lady && world.current.id=="kitchen" && e.x==2 && e.y==5) {
			discoveries.get("ladyfrozen");
			world.transformItem(e, LadyGlagla);
		}
		if (e.pickItem==Lady && world.current.id.indexOf("cave")>=0)
			discoveries.get("kidnap");
		if (e.pickItem==LadyGlagla)
			e.xr = if (e.xr<0.4) 0.4 else if(e.xr>0.6) 0.6 else e.xr;
		
	}
	
	public function onLand(e:Entity) {
		playSound("Land",0.2);
		if (e.key=="hero") {
			if ( world.current.id=="living" && e.x>=3 && e.x<=4 && e.y==2 && incCounter("sofa_bounce")>=3)
				discoveries.get("trampoline");
			//discoveries.get("timetravel");
		}
		if (e.pickItem==Lady) {
			if( inRoom("ladyroom") && e.x>=6)
				discoveries.get("bedlove");
			if( world.current.id=="bedroom2" && e.x<=2)
				discoveries.get("inmybed");
			if( world.current.id=="living" && e.x>=3 && e.x<=4 && e.y==2)
				discoveries.get("sofalove");
		}
		
		if (e.pickItem==Book && inRoom("shower") )
			discoveries.get("toiletbook");
		
		if (e.pickItem==Rabbit && world.current.id=="ladyroom" && e.x>=6)
			discoveries.get("cute");
	}
	
	public function onHitSideWall(e:Entity, c:Case, x,y) {
		if (e.pickItem==GoldKey) {
			for (e2 in world.getEntitiesAt(new flash.geom.Point(x*16,y*16)))
				if (e2.key=="wall_door") {
					comment();
					discoveries.get("unlock");
					explosion(e,20);
					playSound("Explode",0.7);
					explosion(e2,20);
					world.destroyItem(e2);
					world.destroyItem(e);
					world.clearCollide(e2.x, e2.y, Math.round(e2.sprite.width/16), Math.round(e2.sprite.height/16));
				}
		}
	}
	
	public function comment() {
		var e = hero;
		var txtSet = if (inRoom("grotte")) Text.GROTTE_CHATS else Text.CHATS;
		if (chat!=null && chat.parent!=null)
			return;
		chat = new fx.Chat();
		root.addChild(chat);
		TW.create(chat.field, "x", chat.field.x+3, TShakeBoth, 500);
		TW.create(chat.field, "y", chat.field.y-10, TEaseOut, 750);
		
		chat.field.text =
			if(!inRoom("grotte") && incCounter("chat")<=1)
				txtSet[0];
			else
				if (inRoom("grotte") && incCounter("gchat")<=1 && lastScore==null)
						Text.INTRO;
				else
					txtSet[Std.random(txtSet.length)];
		chat.filters = [ new flash.filters.GlowFilter(0x0,0.7, 2,2,10), new flash.filters.GlowFilter(0x0,0.7,6,6,1) ];
		chatCD = 9999;
		haxe.Timer.delay( function() {
			TW.create(ME.chat, "alpha", 0, TEaseIn, 1500).onEnd = function() {
				ME.chat.parent.removeChild(ME.chat);
				ME.chat = null;
				ME.chatCD = Std.random(32*8)+32*4;
		}}, 1000);
	}
	
	function pickup(item:Entity) {
		picked = item;
		picked.sprite.filters = [];
		playSound("Pick",0.3);
		//discoveries.get("pick");
		if (item.pickItem!=null) {
			var k = "pick"+Std.string(item.pickItem).toLowerCase();
			if (Discoveries.ALL.exists(k))
				discoveries.get(k);
		}
	}
	
	function throwPicked() {
		//discoveries.get("throw");
		comment();
		var spd = switch(picked.pickItem) {
			case GoldKey : 0.3;
			case Sofa : 0.03;
			case LadyGlagla : 0;
			case Book : 0.2;
			default : 0.1;
		}
		picked.yr=0.1;
		picked.move(spd * if (hero.fl_flip) -1 else 1, -0.17);
		picked.fl_gravity = true;
		picked= null;
	}

	function action() {
		var pt = new flash.geom.Point(hero.sprite.x + if (hero.fl_flip) -12 else 12, hero.sprite.y+8);
		
		var actions = new Array();
		
		// jeter l'objet pickup
		if (picked!=null)
			actions.push( { k:"throw", cb:throwPicked } );
		
		for (e in world.getEntitiesAt(pt)) {
			if (e==picked)
				continue;
			// ramasse un item
			if ( picked==null && e.pickItem!=null && e.fl_stable )
				actions.push( { k:"pick", cb: callback(pickup,e) } );
			// passage de porte
			if (e.key=="door")
				actions.push( { k:"door", cb: callback(world.crossGate, e) } );
			// escaliers
			if (e.key=="stairway_up" && hero.x>=12)
				actions.push( { k:"stair", cb: callback(world.crossGate, e) } );
			if (e.key=="stairway_down")
				actions.push( { k:"stair", cb: callback(world.crossGate, e) } );
			// attaque
			if (e.life>0 && e.fl_fragile)
				actions.push( { k:"hit", cb: callback(e.hit, 1)} );
		}
		
		actions.sort(function(a,b) {
			if (a.k=="pick") return 1;
			if (b.k=="pick") return -1;
			if (a.k=="door") return 1;
			if (b.k=="door") return -1;
			if (a.k=="stair") return 1;
			if (b.k=="stair") return -1;
			if (a.k=="throw") return 1;
			if (b.k=="throw") return -1;
			return 0;
		});
		
		if (actions.length>0) {
			var a = actions.pop();
			a.cb();
			if (a.k=="throw" || a.k=="hit")
				slash(pt.x,pt.y);
		}
		else
			slash(pt.x,pt.y);
	}
	
	function slash(x,y) {
		hero.sprite.setAnim(Gfx.tiles.getAnim("hero_slash_char"), false);
		suspendStandAnim = 8;
		
		var fx = new pix.Part();
		scene.addChild(fx);
		fx.timer = 5;
		fx.setPos(x, y);
		if (hero.fl_flip)
			fx.scaleX = -1;
		fx.setAnim(Gfx.tiles.getAnim("hero_slash"), false);
		fx.blendMode = flash.display.BlendMode.SCREEN;
		fx.filters = [new flash.filters.GlowFilter(0xFFFF80,0.5,4,4,1)];
	}
	
	public function gainScore(n, ?fl_silent=false) {
		score+=n;
		if(!fl_silent)
			updateBar(false);
	}
	
	function onStartGame() {
		updateBar(false);
		playSound("Teleport");
		picked = null;
		chatCD = 1;
	}
	
	function resetGame() {
		if (inRoom("grotte"))
			return;
		playSound("Teleport");
		fl_lock = true;
		//world.gotoRoom("grotte", 3);
		//for (s in pix.Sprite.all.copy())
			//s.kill();
		picked = null;
		
		if (score>=high)
			high = score;
		mt.deepnight.Lib.setCookie("ludum", "high", high);
		lastScore = score;
		score = 0;
		discoveries = new Discoveries();
		discoveries.get("rain", true);
		discoveries.get("discovery", true);

		counters = new Hash();
		portal = null;
		portal2 = null;
		
		endTimer = BASE_TIME+1;
		world = new World();
		hero.setWorld(world);
		world.gotoRoom("grotte",3);
		openPortal();
		teleportHero(3,2);
		hero.move(0.5, -0.2);
	}
	
	function onTick() {
		if (inRoom("grotte")) {
			timer.visible = false;
			return;
		}
		if (fl_lock)
			return;
		timer.visible = true;
		if (endTimer<=0) {
			resetGame();
			return;
		}
		endTimer--;
		if (endTimer<0)
			endTimer = 0;
		var d = Date.fromTime(endTimer*1000);
		timer.field.text = DateTools.format(d,"%M:%S").substr(1);
	}
	
	public function notify(msg) {
		fl_lock = true;
		ui.notify(msg+"\n\n"+"[ Click or press SPACE to continue ]", function() { ME.fl_lock = false; ME.hero.sprite.visible = true; } );
	}
	
	public function updateBar(fl_animLast:Bool) {
		if (bar!=null && bar.parent!=null)
			bar.parent.removeChild(bar);
			
		var all = discoveries.countAll();
		var done = discoveries.countDone();
		
		bar = new flash.display.Sprite();
		root.addChild(bar);
		bar.x = Std.int( WID*0.5 - all*16*0.5 );
		bar.y = HEI-60;
		var x = 0;
		var y = 0;
		for (i in 0...all) {
			var spr = new pix.Sprite();
			var on = i<done;
			bar.addChild(spr);
			spr.drawFrame( Gfx.tiles.get((on?1:0),"idea") );
			spr.alpha = (on?1:0.5);
			spr.x = x*(spr.width+1);
			spr.y = y*(spr.height+1);
			if (on)
				spr.filters = [ new flash.filters.GlowFilter(0xFFAC00,0.5, 16,16,2) ];
			if (i==done && fl_animLast) {
				for(j in 0...15) {
					var fx = new pix.Part();
					root.addChild(fx);
					fx.timer = Std.random(62)+16;
					fx.fadeType = 1;
					fx.setPos(bar.x-16+spr.x+Std.random(80)/10*(Std.random(2)*2-1), bar.y+spr.y-8+Std.random(40)/10*(Std.random(2)*2-1));
					//fx.setPos(100,100);
					var g = fx.graphics;
					g.beginFill( mt.deepnight.Color.interpolateInt(0xFFBF00, 0xF9FF00, Std.random(100)/100), 0.5+Std.random(50)/100 );
					g.drawRect(-1,-1,3,3);
					g.endFill();
					fx.vy = -(Std.random(80)/100+0.2);
				}
			}
			x++;
			if (x>=999) {
				x = 0;
				y++;
			}
		}
		
		var mc = new interf.Score();
		bar.addChild(mc);
		mc.x = -8;
		mc.y = 7;
		mc.field.text = "Score : "+score;
		mc.field.textColor = 0xEDBB52;
		
		var mc = new interf.Score();
		bar.addChild(mc);
		mc.field.text = "Highscore : "+high;
		mc.field.textColor = 0x6B6B6B;
		mc.x = bar.width-mc.field.textWidth-8;
		mc.y = 7;
	}
	
	
	function openPortal() {
		portal = world.createItem("portal", 2,2);
		portal.sprite.setAlign(0.5,0.5);
		portal.sprite.drawFrame(Gfx.tiles.get("portal"));
		portal.sprite.blendMode = flash.display.BlendMode.SCREEN;
		portal.sprite.filters = [
			new flash.filters.GlowFilter(0xffffff,1,2,2,10),
			new flash.filters.GlowFilter(0x94D9EF,1,16,16,1),
			new flash.filters.GlowFilter(0x22AEDD,0.5,32,32,2),
		];
		explosion(portal, 30, 0x94D9EF);

		portal2 = world.createItem("portal", 2,2);
		portal2.sprite.setAlign(0.5,0.5);
		portal2.sprite.drawFrame(Gfx.tiles.get("portal"));
		portal2.sprite.alpha = 0.8;
		portal2.sprite.blendMode = flash.display.BlendMode.SCREEN;
		portal2.sprite.filters = [
			new flash.filters.GlowFilter(0xffffff,1,2,2,10),
			new flash.filters.GlowFilter(0x94D9EF,1,16,16,1),
			new flash.filters.GlowFilter(0x22AEDD,0.5,32,32,2),
		];

		redraw();
	}
	
	
	function main(_) {
		TW.update();
		world.update();
		
		for (s in pix.Sprite.all.copy())
			s.update();
			
		// bugfix
		root.stage.focus = root.stage;

			
		// anim stand
		if ( !Key.isDown(Keyboard.LEFT) && !Key.isDown(Keyboard.RIGHT) && suspendStandAnim<=0 ) {
			hero.sprite.swapAnim(Gfx.tiles.getAnim(heroKey("hero_stand")));
			if(!fl_lock && !inRoom("grotte")) incCounter("wait");
		}
		else setCounter("wait",0);
		suspendStandAnim--;
		
		if(!fl_lock) {
			// saut
			if ( isDownWithLock(Keyboard.UP) && hero.fl_stable ) {
				hero.move(0,-0.36);
				playSound("Jump",0.3);
			}
			
			// attaque
			if ( isDownWithLock(Keyboard.SPACE) )
				action();
			
			if ( getCounter("wait")>=256 )
				discoveries.get("patience");
				
			// bas
			if ( Key.isDown(Keyboard.DOWN) && hero.fl_stable )
				if( world.current.get(hero.x,hero.y+1).fl_platform || world.hasItemAt(LadyGlagla, hero.x, hero.y+1) )
					hero.yr+=0.5;
				
			// gauche
			if ( Key.isDown(Keyboard.LEFT) ) {
				hero.xr-=0.105;
				hero.setFlip(true);
				hero.sprite.continueAnim(Gfx.tiles.getAnim(heroKey("hero_run")));
			}
				
			// droite
			if ( Key.isDown(Keyboard.RIGHT) ) {
				hero.xr+=0.105;
				hero.setFlip(false);
				hero.sprite.continueAnim(Gfx.tiles.getAnim(heroKey("hero_run")));
			}
			
			// dans le vide
			if (!hero.fl_stable) {
				hero.sprite.setAnim(null);
				if(hero.dy<0)
					hero.sprite.drawFrame(Gfx.tiles.get(6,heroKey("hero")));
				else
					hero.sprite.drawFrame(Gfx.tiles.get(4,heroKey("hero")));
			}
			
			hero.update();
		}
			
		if (picked!=null) {
			picked.fl_gravity = false;
			picked.xr = hero.xr;
			picked.yr = hero.yr;
			picked.x = hero.x;
			picked.y = hero.y;
			picked.sprite.x = hero.sprite.x + if(hero.fl_flip) -16 else 0;
			picked.sprite.y = hero.sprite.y-10;
			picked.sprite.pxx();
			if (picked.fl_flip)
				picked.sprite.x += picked.sprite.width;
		}
		
		if ( inRoom("grotte") && discoveries.countDone()>=1 ) {
			var c = incCounter("start");
			if(c==32*3 && discoveries.countDone()==1)
				discoveries.get("discovery");
			if (c==32*7 && portal==null) {
				notify("What the... ??\n\nA mysterious and impromptu time portal has opened in your cave!\n\nHey! This could be a perfect opportunity to discover more things!");
				openPortal();
			}
		}
		
		// anim portal
		if (inRoom("grotte") && portal!=null) {
			portal.sprite.rotation+=5;
			portal2.sprite.rotation-=3;
			var fx = new pix.Part();
			scene.addChild(fx);
			fx.setPos(portal.sprite.x-16+Std.random(44), portal.sprite.y+18);
			fx.vy = -Std.random(100)/100;
			var g = fx.graphics;
			g.beginFill(0xffffff,1);
			var w = Std.random(2)+1;
			g.drawRect(-1,-2, w,w);
			fx.alpha = Std.random(50)/100 + 0.5;
			fx.fadeType = 1;
			fx.timer = Std.random(32)+8;
		}

		// render bitmap
		refreshBuffer();
		#if debug
		debug.text = world.current.id+"@"+hero.x+","+hero.y;
		#end

		if(!fl_lock) {
			chatCD--;
			if ( chatCD<=0 )
				comment();
			if ( chat!=null && chat.parent!=null ) {
				chat.x = Std.int(buffer.x + (hero.x+hero.xr)*16*UPSCALE);
				chat.y = Std.int(buffer.y + hero.sprite.y*UPSCALE);
			}
		}
	}
}
