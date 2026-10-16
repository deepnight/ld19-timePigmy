import mt.deepnight.Tweenie;

enum PickItem {
	GoldKey;
	Rabbit;
	Sofa;
	Lady;
	Lady2;
	Lady3;
	LadyGlagla;
	Computer;
	Book;
	Toilet;
	Tv;
}


class Entity {
	public static var GRAVITY = 0.03;
	public var key			: String;
	
	public var x			: Int;
	public var y			: Int;
	public var xr			: Float;
	public var yr			: Float;
	
	public var dx			: Float;
	public var dy			: Float;
	public var fl_stable	: Bool;
	
	public var life			: Int;
	
	public var sprite		: pix.Sprite;
	public var fl_gravity	: Bool;
	public var fl_flip		: Bool;
	public var fl_fragile	: Bool;
	public var pickItem		: Null<PickItem>;
	var world				: World;
	
	public function new(w, k, x,y) {
		key = k;
		world = w;
		sprite = new pix.Sprite();
		sprite.setAlign(0,0);
		sprite.drawFrame( Gfx.tiles.get(key) );
		fl_gravity = false;
		fl_stable = true;
		fl_flip = false;
		fl_fragile = true;
		this.x = x;
		this.y = y;
		xr = 0.5;
		yr = 0.5;
		dx = 0;
		dy = 0;
		life = 5;
	}
	
	public function setWorld(w) { world = w; }
	
	public function toString() { return key+"@"+x+","+y; }
	
	public function hit(dmg) {
		if (life<=0 || !fl_fragile)
			return;
		var o = {f:1.0};
		var a = Game.TW.create(o,"f",0,TEaseOut, 500);
		var me = this;
		a.onUpdate = function() {
			me.sprite.filters = [ new flash.filters.GlowFilter(0xffffff,o.f,2,2,10) ];
		}
		a.onEnd = function() {
			me.sprite.filters = [];
		}
		life-=1;
		Game.ME.explosion(this, Std.random(5)+2);
		Game.ME.onHit(this);
		dy=-0.1;
		if (life<=0) {
			//sprite.transform.colorTransform = mt.deepnight.Color.getSimpleCT(0xffffff,1.0);
			//sprite.blendMode = flash.display.BlendMode.OVERLAY;
			//sprite.alpha = 0.3;
			sprite.visible = false;
			Game.ME.onDestroy(this);
			world.clearCollide(x,y, Math.round(sprite.width/16), Math.round(sprite.height/16));
		}
	}
	
	public function move(ddx, ddy) {
		dx = ddx;
		dy = ddy;
		fl_stable = fl_stable && ddy==0;
	}
	
	public function setFlip(b) {
		fl_flip = b;
		sprite.scaleX = if (fl_flip) -1 else 1;
	}
	
	public function update() {
		var lastPos = new flash.geom.Point(x,y);
		if (fl_gravity) {
			// chute
			var tempPlatform = world.hasItemAt(LadyGlagla, x,y+1);
			var next = world.current.get(x,y+1);
			if ( !tempPlatform && !next.collidesDown() || yr<0.5 || dy!=0 ) {
				fl_stable = false;
				dy+=GRAVITY;
			}
			yr+=dy;
			// atterrissage
			if ( (tempPlatform || next.collidesDown()) && yr>0.5 && dy>0) {
				yr = 0.5;
				dy = 0;
				fl_stable = true;
				Game.ME.onLand(this);
				lastPos.x = -99; // pour forcer l'appel à onEnter
			}
			// collision plafond
			var next = world.current.get(x,y-1);
			if (dy<0 && next.collidesAll() && yr<0.15) {
				yr = 0.15;
				dy = 0;
			}
		}

		// résolution mouvement vertical
		while (yr<0) { y--; yr+=1; }
		while (yr>=1) { y++; yr-=1; }

		// collisions latérales
		xr+=dx;
		if (fl_stable)
			dx*=0.9;
		var next = world.current.get(x+1,y);
		if (next.collidesAll() && xr>0.85) {
			dx = 0;
			xr = 0.85;
			Game.ME.onHitSideWall(this, next,x+1,y);
		}
		var next = world.current.get(x-1,y);
		if (next.collidesAll() && xr<0.15) {
			dx = 0;
			xr = 0.15;
			Game.ME.onHitSideWall(this, next,x-1,y);
		}
		
		// résolution mouvement horizontal
		while (xr<0) { x--; xr+=1; }
		while (xr>=1) { x++; xr-=1; }

		sprite.x = x*16 + 16*xr -8 + if (fl_flip) sprite.width else 0;
		sprite.y = y*16 + 16*yr -8;
		sprite.pxx();
		//xr = Math.round(xr*100)/100;
		//yr = Math.round(yr*100)/100;
		if( lastPos.x!=x || lastPos.y!=y )
			Game.ME.onEnter(this);
	}
}
