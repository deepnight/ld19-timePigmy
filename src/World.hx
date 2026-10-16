import mt.deepnight.Types;
import Entity;

class Case implements haxe.Public {
	var bg			: Null<pix.Frame>;
	var bgKey		: Null<String>;
	var bgFrame		: Null<Int>;
	var fl_collide	: Bool;
	var fl_platform	: Bool;
	
	public function new(coll:Bool, k:String, n:Int) {
		fl_collide = coll;
		fl_platform = false;
		setFrame(k,n);
	}
	
	public function setFrame(k:String, n:Int) {
		bgKey = k;
		bgFrame = n;
		if (bgKey!=null)
			bg = Gfx.tiles.get(bgFrame, bgKey);
	}
	
	public inline function collidesAll() {
		return fl_collide;
	}
	public inline function collidesDown() {
		return fl_collide || fl_platform;
	}
	
	public function toString() { return bgKey+"@"+bgFrame; }
}

class Room implements haxe.Public {
	var name		: String;
	var id			: String;
	var width		: Int;
	var height		: Int;
	var grid		: Array<Case>;
	var items		: Array<Entity>;
	var doors		: List<{e:Entity, to:String, transit:Int}>;
	
	public function new(id, w,h) {
		this.id = id;
		grid = new Array();
		items = new Array();
		doors = new List();
		width = w;
		height = h;
		for(y in 0...h)
			for (x in 0...w) {
				var f = "bg";
				var n = 0;
				if (y==h-1) {
					f = "ground";
					if (id.indexOf("cave")>=0) n = 1;
					if (id=="kitchen") n = 2;
					if (id=="shower") n = 2;
				}
				if (x==0 && y==h-1) {
					f = "wall_left";
					n = 1;
				}
				if (x==w-1 && y==h-1) {
					f = "wall_right";
					n = 1;
				}
				if (x==0)
					f ="wall_left";
				if (x==w-1)
					f ="wall_right";
				if (id.indexOf("cave")>=0 && f=="bg")		n = 2;
				if (id.indexOf("corridor")>=0 && f=="bg")	n = 3;
				if (id.indexOf("ladyroom")>=0 && f=="bg")	n = 5;
				if (id.indexOf("grotte")>=0 && f=="bg")		n = 6;
				if (id.indexOf("bedroom")>=0 && f=="bg")	n = 8;
				if (id.indexOf("grotte")>=0 && f!="bg") {
					f = "ground";
					n = 4+Std.random(3);
				}
				var c = new Case(false, f,  n);
				set(x,y, c);
				c.fl_collide = f!="bg";
			}
		name = "untitled";
	}
	
	public inline function set(x,y, c:Case) {
		grid[y*width+x] = c;
	}
	public inline function get(x,y) {
		if (x<0 || x>=width || y<0 || y>=height)
			return new Case(true,"painting",0);
		else
			return grid[y*width+x];
	}
}

class World {
	var rooms			: Hash<Room>;
	public var current	: Room;
	var loopChan		: flash.media.SoundChannel;
	//public var elements	: List<pix.Element>;
	
	public function new() {
		Game.WORLD = this;
		rooms = new Hash();
		//elements = new List();
		create();
	}
	
	public function getEntitiesAt(pt:flash.geom.Point) {
		return Lambda.filter(current.items, function(e) {
			var spr = e.sprite;
			return (!e.fl_flip && pt.x>=spr.x && pt.x<spr.x+spr.width && pt.y>=spr.y && pt.y<spr.y+spr.height) ||
				 (e.fl_flip && pt.x>=spr.x-spr.width && pt.x<spr.x && pt.y>=spr.y && pt.y<spr.y+spr.height);
		});
	}
	public function hasItemAt(pi:PickItem, x,y) {
		for (e in getEntitiesAt(new flash.geom.Point(x*16+8, y*16+8)))
			if (e.pickItem==pi)
				return true;
		return false;
	}
	
	function create() {
		// SaM
		current = new Room("living", 15,5);
		rooms.set(current.id, current);
		for (x in 1...current.width-1)
			current.set(x,current.height-2, new Case(false, "bg",1)); // bas de mur
		createItem("window",2,1).fl_fragile = false;
		createItem("window",6,1).fl_fragile = false;
		createItem("etagere",4,0);
		makePlatform(4,1, 2);
		//createItem("table",10,3);
		//makePlatform(10,3, 3);
		createItem("commode",1,3);
		makeCollide(1,3, 2);
		createItem("sofa",3,3);
		makePlatform(3,3, 2);
		//createItem("sofa_small",6,3).pickItem;
		//createItem("sofa_small",1,3).setFlip(true);
		createItem("painting", 5,2);
		var e = createItem("stairway_up", 9,0);
		e.fl_fragile = false;
		current.doors.add( { e:e, to:"corridor", transit:1 } );
		var e = createItem("door", 8,2);
		current.doors.add( { e:e, to:"kitchen", transit:0 } );
		var e = createItem("door", 10,2);
		current.doors.add( { e:e, to:"cave", transit:2 } );
		dropItem(Sofa, 6,3);
		//dropItem(Sofa, 1,3).setFlip(true);
		dropItem(Tv, 1,2);
		
		// cuisine
		current = new Room("kitchen", 10,7);
		rooms.set(current.id, current);
		createItem(1,"window",3,3).fl_fragile = false;
		createItem(0,"window",6,3).fl_fragile = false;
		createItem(0,"window",7,3).fl_fragile = false;
		createItem(0,"window",8,3).fl_fragile = false;
		//current.set(3,current.height-4, new Case(false, "window",0));
		//current.set(3,current.height-3, new Case(false, "window",1));
		//current.set(7,current.height-4, new Case(false, "window",0));
		//current.set(7,current.height-3, new Case(false, "window",1));
		createItem("kitchen_block", 6,4);
		createItem("microwave", 8,4).fl_fragile = false;
		makeCollide(6,5, 3);
		createItem("fridge", 1,4).fl_fragile = false;
		makeCollide(1,4,1,2);
		createItem("top_shelf", 1,1);
		makeCollide(1,2, 2);
		createItem("etagere", 4,2);
		makePlatform(4,3, 2);
		var e = createItem("door", 4,4);
		current.doors.add( { e:e, to:"living", transit:0 } );
		
		// cave
		current = new Room("cave", 9,7);
		rooms.set(current.id, current);
		var e = createItem("door", 1,1);
		current.doors.add( { e:e, to:"living", transit:1 } );
		var e = createItem("door", 7,4);
		e.sprite.drawFrame(Gfx.tiles.get(1,"door"));
		current.doors.add( { e:e, to:"cave2", transit:0 } );
		for(x in 1...3) current.set(x,3, new Case(true, "ground",3));
		current.set(3,4, new Case(true, "ground",3));
		current.set(4,5, new Case(true, "ground",3));
		createItem("top_shelf", 5,0).fl_fragile = false;
		makeCollide(5,1, 2);
		dropItem(GoldKey,6,0);
		
		// cave 2
		current = new Room("cave2",18,8);
		rooms.set(current.id, current);
		for (x in 1...8) current.set(x,0, new Case(true, "ground",3));
		for (x in 1...11) current.set(x,3, new Case(true, "ground",3));
		for (x in 13...current.width-1) current.set(x,3, new Case(true, "ground",3));
		current.set(12,4, new Case(true, "ground",3));
		current.set(11,5, new Case(true, "ground",3));
		current.set(10,6, new Case(true, "ground",3));
		var e = createItem("door", 1,1);
		e.sprite.drawFrame(Gfx.tiles.get(1,"door"));
		current.doors.add( { e:e, to:"cave", transit:0 } );
		createItem("etagere", 14,0);
		makePlatform(14,1, 2);
		createItem("table", 6,6);
		makePlatform(6,6, 3);
		createItem("car", 1,5).life=20;
		makePlatform(2,5);
		makePlatform(1,6,4);
		var e = createItem("wall_door", 6,1);
		e.life = 100;
		makeCollide(6,1, 1,2);
		dropItem(Rabbit, 2,3);
		
		// corridor
		current = new Room("corridor",14,4);
		rooms.set(current.id, current);
		for (x in 1...current.width-1)
			current.set(x,current.height-2, new Case(false, "bg",4));
		var e = createItem("stairway_down", 10,1);
		e.fl_fragile = false;
		current.doors.add( { e:e, to:"living", transit:2 } );
		createItem("painting", 8,1);
		var e = createItem("door", 7,1);
		current.doors.add( { e:e, to:"ladyroom", transit:0 } );
		var e = createItem("door", 5,1);
		current.doors.add( { e:e, to:"bedroom2", transit:0 } );
		var e = createItem("door", 1,1);
		current.doors.add( { e:e, to:"shower", transit:0 } );
		
		// chambre fille
		current = new Room("ladyroom",9,6);
		rooms.set(current.id, current);
		var e = createItem("door", 4,3);
		current.doors.add( { e:e, to:"corridor", transit:0 } );
		createItem("top_shelf",2,0).life=5;
		makePlatform(2,1, 2);
		createItem("commode",1,4);
		makePlatform(1,4, 2);
		var e = createItem("bed",6,3);
		e.setFlip(true);
		e.fl_fragile = false;
		makePlatform(6,4, 2);
		dropItem(Lady, 3,0);
		dropItem(Computer, 1,3);
		
		// chambre 2
		current = new Room("bedroom2",9,6);
		rooms.set(current.id, current);
		var e = createItem("door", 4,3);
		current.doors.add( { e:e, to:"corridor", transit:0 } );
		createItem("bed",1,3).fl_fragile = false;
		makePlatform(1,4, 2);
		createItem("commode",6,4);
		makePlatform(6,4, 2);
		createItem(1,"painting",2,2);
		createItem(0,"painting",6,1);
		dropItem(Book, 6,3);
		
		// sdb
		current = new Room("shower",6,4);
		rooms.set(current.id, current);
		var e = createItem("door",2,1);
		current.doors.add( { e:e, to:"corridor", transit:0 } );
		dropItem(Toilet, current.width-2,current.height-2);
		
		// grotte
		current = new Room("grotte",12,8);
		rooms.set(current.id, current);
		var e = createItem("rain",2,5);
		e.sprite.setAnim(Gfx.tiles.getAnim("rain"), true);
		e.fl_fragile = false;
		for (x in 1...7) current.set(x,6, new Case(false, "bg", 7));
		for (x in 5...8) current.set(x,3, new Case(true, "ground", 7));
		for (x in 1...4) current.set(x,3, new Case(true, "ground", 7));
		for (x in 9...11) current.set(x,2, new Case(true, "ground", 7));
		for (x in 7...11) current.set(x,6, new Case(true, "ground", 7));
		for (x in 8...10) current.set(x,6, new Case(true, "ground", 6));
		for (x in 1...7) current.set(x,7, new Case(true, "ground", 7));
		for (x in 8...10) current.set(x,5, new Case(true, "ground", 7));
		var ls = Game.ME.lastScore;
		if ( ls>=50) {
			createItem(0,"painting", 5,5);
			createItem(1,"painting", 9,3);
		}
		if ( ls>=100)	{
			createItem("commode", 1,6);
			makePlatform(1,6, 2);
		}
		if( ls>=150)	dropItem(Computer, 10,5);
		if( ls>=200)	dropItem(Toilet, 10,1);
		if ( ls>=300)	dropItem(Lady, 9,1);
		if ( ls>=30)	dropItem(Sofa, 4,6);
		if ( ls>=100) 	dropItem(Tv, 1,5).setFlip(true);
	}
	
	
	public function makeCollide(x,y, ?xw=1, ?yw=1) {
		for(ix in 0...xw)
			for (iy in 0...yw)
				current.get(x+ix, y+iy).fl_collide = true;
	}
	public function makePlatform(x,y, ?xw=1, ?yw=1) {
		for(ix in 0...xw)
			for (iy in 0...yw)
				current.get(x+ix, y+iy).fl_platform = true;
	}
	
	public function clearCollide(x,y, ?xw=1, ?yw=1) {
		for(ix in 0...xw)
			for (iy in 0...yw) {
				current.get(x+ix, y+iy).fl_collide = false;
				current.get(x+ix, y+iy).fl_platform = false;
			}
		Game.ME.redraw();
	}
	
	public function destroyItem(e:Entity) {
		current.items.remove(e);
		Game.ME.redraw();
	}
	
	public function transformItem(e:Entity, pi:PickItem) {
		current.items.remove(e);
		dropItem(pi, e.x, e.y);
		//Game.ME.discoveries.get("transform");
		Game.ME.redraw();
		Game.ME.explosion(e,20);
		Game.ME.comment();
	}
	
	public function dropItem(pi:PickItem, x,y) {
		var e = new Entity(this, "pickitem", x,y);
		e.sprite.drawFrame( Gfx.tiles.get(Type.enumIndex(pi),"pickitem") );
		e.pickItem = pi;
		e.fl_fragile = false;
		if(pi==GoldKey)
			e.sprite.filters = [ new flash.filters.GlowFilter(0xFFC02D,1, 6,6,1) ];
		if (pi==Lady)
			e.sprite.setAnim( Gfx.tiles.getAnim("lady") );
		current.items.push(e);
		e.fl_gravity = true;
		return e;
	}
	
	public function gotoRoom(id, transition:Int) {
		var from = current;
		if (!rooms.exists(id))
			throw "goto failed : "+id;
			
		current = rooms.get(id);
		if ( Game.ME.picked!=null ) {
			// emmène l'item pickup
			from.items.remove(Game.ME.picked);
			current.items.push(Game.ME.picked);
		}
		for (door in current.doors)
			if (door.to==from.id) {
				var dx =  if (door.e.key=="stairway_up") 4 else 0;
				Game.ME.teleportHero(door.e.x+dx, door.e.y+1);
			}
		
		if (id=="grotte") {
			loopChan = new sfx.Rain().play(0,99);
			loopChan.soundTransform = new flash.media.SoundTransform(0.05*Game.MAIN_VOLUME);
		}
		else loopChan.stop();
			
			
		Game.ME.redraw(transition);
	}
	
	public function crossGate(e:Entity) {
		for (d in current.doors)
			if (e==d.e) {
				gotoRoom(d.to, d.transit);
				if (d.e.key=="door") {
					if(!Game.ME.inRoom("cave"))
						Game.ME.playSound("Door",0.2);
					Game.ME.discoveries.get("door");
				}
				if (d.e.key.indexOf("stair")>=0)
					Game.ME.discoveries.get("stair");
			}
	}
	
	public function createItem(?frame:Int, key:String, x,y) {
		var e = new Entity(this, key, x,y);
		if (frame!=null && frame>0)
			e.sprite.drawFrame(Gfx.tiles.get(frame, key));
		switch(key) {
			case "door", "painting", "window" :
			default : e.sprite.filters = [ new flash.filters.DropShadowFilter(3,-45,0x0,0.25,0,0) ];
		}
		current.items.push(e);
		return e;
	}
	
	public function update() {
		for (e in current.items)
			e.update();
	}
	
	public function render() {
		var scene = new mt.deepnight.SPR();
		for (y in 0...current.height)
			for (x in 0...current.width) {
				if (current.get(x,y)==null)
					continue;
				var c = current.get(x,y);
				if (c.bg==null)
					continue;
				var s = new pix.Element();
				s.setAlign(0,0);
				s.drawFrame(c.bg);
				s.x = x*16;
				s.y = y*16;
				if(c.bgKey=="ground") {
					if (c.fl_collide && !current.get(x,y-1).fl_collide)
						s.filters = [ new flash.filters.DropShadowFilter(2,-90,0x0,0.7, 0,16) ];
					if (!c.fl_collide && current.get(x,y-1).fl_collide)
						s.filters = [ new flash.filters.DropShadowFilter(2,90,0x0,0.5, 0,8, 1,1,true) ];
				}
				scene.addChild(s);
			}
			
		if ( current.id.indexOf("cave")>=0 )
			scene.filters = [
				new flash.filters.DropShadowFilter(10,0, 0x0, 0.6, 0,32,1.5, 1,true),
			];
		if ( current.id=="grotte" )
			scene.filters = [
				new flash.filters.DropShadowFilter(70,185, 0x0,0.3, 64,64,2, 1,true),
				new flash.filters.DropShadowFilter(5,0, 0x0, 1, 0,32,1.5, 1,true),
			];
		for (e in current.items)
		for (e in current.items)
			scene.addChild(e.sprite);
		return scene;
	}
}
