package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// Each source spell must cross the ordinary live book resolver, create its
// saved construct, and continue that actor's action identically after load.
func TestMonsterConstructConjurationsContinueAfterRestore(t *testing.T) {
	cases := []struct {
		name      string
		path      string
		component string
		count     int
	}{
		{
			name:      "ball lightning",
			path:      "testdata/monster-construct-ball",
			component: "magic.summon_construct",
			count:     0,
		},

		{
			name:      "battlesphere",
			path:      "testdata/monster-construct-sphere",
			component: "magic.summon_battlesphere",
			count:     1,
		},

		{
			name:      "spellforged servitor",
			path:      "testdata/monster-construct-servitor",
			component: "magic.summon_servitor",
			count:     1,
		},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			game, caster, rules := moddedEndoplasmGame(t,
				testCase.path)
			placePlayerInSlugLine(t, game, caster)

			energy, _ := game.stores.MonsterEnergy.Get(caster)

			energy.Points = 80

			if _, err := game.runAction(caster, ecs.Intent{}, 10,
				"monster"); err != nil {
				t.Fatal(err)
			}

			if game.turn.ResolvedIntent != ecs.IntentSpell {
				t.Fatalf("resolved intent = %d, want spell",
					game.turn.ResolvedIntent)
			}

			store := game.scripts.Components()[testCase.component]
			actors := store.Entities()

			if testCase.count == 0 &&
				(len(actors) < 1 || len(actors) > 3) {
				t.Fatalf("cast created %d ball-lightning actors, want 1-3",
					len(actors))
			}

			if testCase.count > 0 && len(actors) != testCase.count {
				t.Fatalf("cast created %d %s actors, want %d",
					len(actors), testCase.component, testCase.count)
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
				t.Fatal("construct changed during save restore")
			}

			for _, current := range []*Game{game, loaded} {
				if _, err := current.runAction(actors[0], ecs.Intent{},
					10, "monster"); err != nil {
					t.Fatal(err)
				}
			}

			if !reflect.DeepEqual(game.Snapshot(), loaded.Snapshot()) {
				t.Fatal("construct action diverged after restore")
			}
		})
	}
}

// A later AI-selected Stone Arrow triggers the caster's saved sphere. Its
// first cast is fixed by seed; later casts use ordinary weighted selection.
func TestMonsterBattlesphereMirrorsCasterConjuration(t *testing.T) {
	game, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-construct-sphere")
	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	store := game.scripts.Components()["magic.summon_battlesphere"]
	actors := store.Entities()

	if len(actors) != 1 {
		t.Fatalf("Battlesphere created %d actors, want one",
			len(actors))
	}

	before, _ := store.Get(actors[0])
	chargeBefore, _ := before.Get("charge")
	casterPosition, _ := game.stores.Positions.Get(caster)
	level := game.levels[casterPosition.LevelID]
	clearLane := false

	// The seeded cast occurs in a narrow corridor. Find a small open room
	// where both caster and sphere can see a foe without blocking each other.
	for y, row := range level.Cells() {
		for x := range row {
			if !level.Walkable(x, y) ||
				!level.Walkable(x, y-1) ||
				!level.Walkable(x+3, y) ||
				!level.ClearProjectilePath(x, y, x+3, y) ||
				!level.ClearProjectilePath(x, y-1, x+3, y) {
				continue
			}

			occupied := false

			for _, cell := range []point{
				{
					x: x,
					y: y,
				},

				{
					x: x,
					y: y - 1,
				},

				{
					x: x + 3,
					y: y,
				},
			} {
				if _, found := level.ActorAt(cell.x, cell.y); found {
					occupied = true
				}
			}

			if occupied {
				continue
			}

			if err := level.MoveActor(caster, x, y); err != nil {
				t.Fatal(err)
			}

			if err := level.MoveActor(actors[0], x, y-1); err != nil {
				t.Fatal(err)
			}

			if err := level.MoveActor(game.player, x+3, y); err != nil {
				t.Fatal(err)
			}

			clearLane = true

			break
		}

		if clearLane {
			break
		}
	}

	if !clearLane {
		t.Fatal("level has no joint caster and sphere firing lane")
	}

	if err := game.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	playerHealth, _ := game.stores.Health.Get(game.player)

	playerHealth.Current = 200
	playerHealth.Max = 200

	for attempt := 0; attempt < 6; attempt++ {
		if _, err := game.runAction(caster, ecs.Intent{}, 10,
			"monster"); err != nil {
			t.Fatal(err)
		}

		after, found := store.Get(actors[0])

		if !found {
			t.Fatal("Battlesphere disappeared before a conjuration")
		}

		chargeAfter, _ := after.Get("charge")

		if chargeAfter.(int64) == chargeBefore.(int64)-1 {
			return
		}
	}

	t.Fatal("later monster conjurations did not fire the battlesphere")
}

// The monster servitor's custom book must reach ordinary AI and beam
// execution, not merely survive as a component after the summoning cast.
func TestMonsterServitorCastsInheritedSpell(t *testing.T) {
	game, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-construct-servitor")
	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	servitors := game.scripts.Components()["magic.summon_servitor"].Entities()

	if len(servitors) != 1 {
		t.Fatalf("cast created %d servitors, want one", len(servitors))
	}

	actor := servitors[0]
	casterPosition, _ := game.stores.Positions.Get(caster)
	playerPosition, _ := game.stores.Positions.Get(game.player)
	level := game.levels[casterPosition.LevelID]
	x := casterPosition.X + (playerPosition.X-casterPosition.X)/3
	y := casterPosition.Y + (playerPosition.Y-casterPosition.Y)/3

	if err := level.MoveActor(actor, x, y); err != nil {
		t.Fatal(err)
	}

	if err := game.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	playerHealth, _ := game.stores.Health.Get(game.player)

	playerHealth.Current = 200
	playerHealth.Max = 200

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := game.runAction(actor, ecs.Intent{}, 10,
			"monster"); err != nil {
			t.Fatal(err)
		}

		if game.turn.ResolvedIntent == ecs.IntentSpell {
			return
		}
	}

	t.Fatal("monster servitor never selected its inherited Iron Shot")
}
