package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// Plant spells need a broad ring of traversable cells for vines and briars.
// Place the caster away from the map edge, then carve the arena and put the
// player four cells away so random Dungeon geometry cannot veto the spell.
func openPlantArena(t *testing.T, game *Game, caster akara.Entity) {
	t.Helper()

	position, _ := game.stores.Positions.Get(caster)
	level := game.levels[position.LevelID]
	centerX := 0
	centerY := 0

	for y := 20; y < len(level.terrain)-20 && centerX == 0; y++ {
		for x := 20; x < level.width-24; x++ {
			_, casterOccupied := level.ActorAt(x, y)
			_, playerOccupied := level.ActorAt(x+4, y)

			if !casterOccupied && !playerOccupied {
				centerX = x
				centerY = y
				break
			}
		}
	}

	if centerX == 0 {
		t.Fatal("no open center for plant spell arena")
	}

	for y := centerY - 12; y <= centerY+12; y++ {
		for x := centerX - 12; x <= centerX+16; x++ {
			if !level.Walkable(x, y) {
				if err := level.SetCell(x, y, terrain.Floor); err != nil {
					t.Fatal(err)
				}
			}
		}
	}

	if err := level.MoveActor(caster, centerX, centerY); err != nil {
		t.Fatal(err)
	}

	if err := level.MoveActor(game.player, centerX+4, centerY); err != nil {
		t.Fatal(err)
	}

	if err := game.refreshVisibility(); err != nil {
		t.Fatal(err)
	}
}

// Put source tree terrain beside the player, leaving the caster's direct
// sight line open. Both forest attacks and vine placement read this grid.
func plantTreeBesidePlayer(t *testing.T, game *Game) {
	t.Helper()

	position, _ := game.stores.Positions.Get(game.player)
	level := game.levels[position.LevelID]

	for _, offset := range []point{
		{
			x: 0,
			y: 1,
		},

		{
			x: 0,
			y: -1,
		},

		{
			x: 1,
			y: 0,
		},

		{
			x: -1,
			y: 0,
		},
	} {
		x := position.X + offset.x
		y := position.Y + offset.y

		if y < 0 ||
			y >= len(level.terrain) ||
			x < 0 ||
			x >= len(level.terrain[y]) ||
			level.terrain[y][x] != terrain.Floor {
			continue
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			continue
		}

		level.terrain[y][x] = terrain.Tree

		if err := game.refreshVisibility(); err != nil {
			t.Fatal(err)
		}

		return
	}

	t.Fatal("no floor cell beside player for tree")
}

// A live spellbook cast must reach the Lua plant resolver and save its
// continuing ECS state, not merely pass an isolated Lua policy test.
func TestMonsterPlantSpellbookCastAndRestore(t *testing.T) {
	cases := []struct {
		name      string
		path      string
		component string
	}{
		{
			name:      "grasping roots",
			path:      "testdata/monster-plant-roots",
			component: "zap.grasping_roots",
		},

		{
			name:      "sporulate",
			path:      "testdata/monster-plant-spore",
			component: "combat.monster_spore",
		},

		{
			name:      "awaken forest",
			path:      "testdata/monster-plant-forest",
			component: "world.monster_awake_forest",
		},

		{
			name:      "awaken vines",
			path:      "testdata/monster-plant-vines",
			component: "world.monster_awake_vines",
		},

		{
			name:      "wall of brambles",
			path:      "testdata/monster-plant-brambles",
			component: "magic.summon",
		},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			game, caster, rules := moddedEndoplasmGame(t,
				testCase.path)
			openPlantArena(t, game, caster)

			if testCase.name == "awaken forest" ||
				testCase.name == "awaken vines" {
				plantTreeBesidePlayer(t, game)
			}

			energy, _ := game.stores.MonsterEnergy.Get(caster)

			energy.Points = 80

			if _, err := game.runAction(caster, ecs.Intent{}, 10,
				"monster"); err != nil {
				t.Fatal(err)
			}

			if game.turn.ResolvedIntent != ecs.IntentSpell {
				casterPosition, _ := game.stores.Positions.Get(caster)
				playerPosition, _ := game.stores.Positions.Get(game.player)
				t.Fatalf("resolved intent = %d, want spell; caster %+v player %+v",
					game.turn.ResolvedIntent, *casterPosition, *playerPosition)
			}

			store := game.scripts.Components()[testCase.component]

			if store == nil || len(store.Entities()) == 0 {
				t.Fatalf("cast did not create %s",
					testCase.component)
			}

			if err := game.scheduler.Spend(caster, ecs.Intent{
				Kind: game.turn.ResolvedIntent,
			}); err != nil {
				t.Fatal(err)
			}

			before := game.Snapshot()
			loaded, err := RestoreWithRules(before, rules,
				RestorePolicy{})

			if err != nil {
				t.Fatal(err)
			}

			defer loaded.Close()

			if !reflect.DeepEqual(before, loaded.Snapshot()) {
				t.Fatal("plant state changed on save restore")
			}

			assertSupportContinuation(t, game, loaded, caster)
		})
	}
}

// A real spore explosion must go beyond HP loss: positive source spore
// damage confuses a living Human through the saved player status owner.
func TestMonsterSporeContactConfusesLivingPlayer(t *testing.T) {
	game, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-plant-spore")
	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	spores := game.scripts.Components()["combat.monster_spore"].Entities()

	if len(spores) != 1 {
		t.Fatalf("Sporulate made %d spores, want one", len(spores))
	}

	position, _ := game.stores.Positions.Get(spores[0])
	level := game.levels[position.LevelID]
	placed := false

	for _, offset := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		x := position.X + offset.x
		y := position.Y + offset.y

		if y < 0 ||
			y >= len(level.terrain) ||
			x < 0 ||
			x >= len(level.terrain[y]) ||
			level.terrain[y][x] != terrain.Floor {
			continue
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			continue
		}

		if err := level.MoveActor(game.player, x, y); err != nil {
			t.Fatal(err)
		}

		placed = true
		break
	}

	if !placed {
		t.Fatal("no open cell adjacent to spore")
	}

	if err := game.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if _, err := game.runAction(spores[0], ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	if !game.scripts.Components()["zap.player_confusion"].Has(game.player) {
		t.Fatal("damaging spore explosion did not confuse Human player")
	}
}
