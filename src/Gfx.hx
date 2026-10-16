class GfxTiles extends flash.display.BitmapData { }

import pix.Store;

class Gfx {
	public static var tiles = new Store(new GfxTiles(0,0));
	public static function init() {
		tiles.addIndex("bg");
		tiles.slice(0,0,16,16, 10);
		
		tiles.addIndex("ground");
		tiles.slice(0,16,16,16, 10);
		
		tiles.addIndex("kitchen_block");
		tiles.slice(112,32,32,32, 1);
		tiles.addIndex("microwave");
		tiles.slice(144,32,16,32, 1);
		tiles.addIndex("etagere");
		tiles.slice(160,32,32,32, 1);
		tiles.addIndex("top_shelf");
		tiles.slice(192,32,32,32, 1);
		tiles.addIndex("fridge");
		tiles.slice(224,32, 16,32, 1);
		tiles.addIndex("car");
		tiles.slice(240,32, 4*16,32, 1);

		tiles.addIndex("painting");
		tiles.slice(96,64,16,16, 2);

		tiles.addIndex("sofa");
		tiles.slice(48,48,32,16, 1);
		tiles.addIndex("sofa_small");
		tiles.slice(80,48,16,16, 1);

		tiles.addIndex("wall_left");
		tiles.slice(0,64,16,16, 1);
		tiles.slice(32,64,16,16, 1);
		tiles.addIndex("wall_right");
		tiles.slice(16,64,16,16, 1);
		tiles.slice(48,64,16,16, 1);
		
		tiles.addIndex("wall_door");
		tiles.slice(0,32, 16,32);
		
		tiles.addIndex("door");
		tiles.slice(0,144,16,32, 2);
		
		tiles.addIndex("table");
		tiles.slice(16,32,48,16, 1);
		
		tiles.addIndex("portal");
		tiles.slice(0,224,32,32, 1);

		tiles.addIndex("window");
		tiles.slice(0,176, 16,32, 2);

		tiles.addIndex("stairway_up");
		tiles.slice(0,80, 80,64);
		tiles.addIndex("stairway_down");
		tiles.slice(80,80, 48,32);
		
		tiles.addIndex("bed");
		tiles.slice(128,80, 32,32);
		tiles.addIndex("commode");
		tiles.slice(160,96, 32,16);
		
		tiles.addIndex("rain");
		tiles.slice(80,112, 32,32, 7);
		tiles.addAnim("rain", [0,1,2,3,4,5], [2]);
		
		tiles.addIndex("pickitem");
		tiles.slice(0,352, 16,16, 15);
		tiles.addAnim("lady", [3,4,5,4,5, 3,4,3,5, 3], [5,20,20,20,20, 5,30,2,20, 15]);
		
		tiles.addIndex("idea");
		tiles.slice(0,352+16, 16,16, 2);

		// hero
		tiles.addIndex("hero");
		tiles.slice(0,288,16,16, 4);
		tiles.addAnim("hero_stand", [0,1,0,1,0,1,2,1,3,1], [40,32,40,32,15,3,35,2,40,25]);
		tiles.addIndex("hero_moves");
		tiles.slice(64,288,16,16, 5);
		tiles.addAnim("hero_run", [0,1,2,1,3,4], [2,2,3,3,2,2]);
		tiles.slice(144,288,16,16, 4);
		tiles.addAnim("hero_slash", [5,6,7,8], [2,1,1,2]);
		tiles.slice(208,288,16,16, 4);
		tiles.addAnim("hero_slash_char", [9,10,11,12], [1,2,2,4]);
		// hero with item
		tiles.addIndex("ihero");
		tiles.slice(0,320,16,16, 4);
		tiles.addAnim("ihero_stand", [0,1,0,1,0,1,2,1,3,1], [40,32,40,32,15,3,35,2,40,25]);
		tiles.addIndex("ihero_moves");
		tiles.slice(64,320,16,16, 5);
		tiles.addAnim("ihero_run", [0,1,2,1,3,4], [2,2,3,3,2,2]);
		tiles.slice(144,320,16,16, 3);
	}
}

