package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// Put the player beside a caster so an adjacent pulse has a real foe.
func placePlayerAdjacentToCaster(t *testing.T, g *Game, caster akara.Entity) {
	t.Helper()

	position, _ := g.stores.Positions.Get(caster)
	level := g.levels[position.LevelID]

	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			x := position.X + dx
			y := position.Y + dy

			if (dx == 0 && dy == 0) || !level.Walkable(x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			return
		}
	}

	t.Fatal("could not put player beside area caster")
}

// A rock wall next to the player gives LRD a fragmentable cell with one
// hostile in the resulting blast. The line from caster to player is clear.
func placePlayerByFragmentableWall(
	t *testing.T,
	g *Game,
	caster akara.Entity,
) {
	t.Helper()

	position, _ := g.stores.Positions.Get(caster)
	level := g.levels[position.LevelID]
	cells := level.Cells()

	for wallY, row := range cells {
		for wallX, feature := range row {
			if feature != terrain.RockWall ||
				max(abs(wallX-position.X), abs(wallY-position.Y)) > 6 {
				continue
			}

			for dy := -1; dy <= 1; dy++ {
				for dx := -1; dx <= 1; dx++ {
					x := wallX + dx
					y := wallY + dy

					if !level.Walkable(x, y) ||
						!level.ClearProjectilePath(
							position.X, position.Y, x, y) {
						continue
					}

					if _, occupied := level.ActorAt(x, y); occupied {
						continue
					}

					if err := level.MoveActor(g.player, x, y); err != nil {
						t.Fatal(err)
					}

					if err := g.refreshVisibility(); err != nil {
						t.Fatal(err)
					}

					return
				}
			}
		}
	}

	t.Fatal("could not put player beside a visible rock wall")
}

// Keep the geometry test local instead of adding a dependency on another
// package's distance helper solely for this fixture search.
func abs(value int) int {
	if value < 0 {
		return -value
	}

	return value
}

// A live Chaos chain must pass through monster spellbook selection, Lua
// planning, actor contact, and saved random streams before restore.
func TestMonsterChainChaosBookCastAndSave(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-chain-chaos")
	placePlayerInSlugLine(t, g, caster)

	energy, _ := g.stores.MonsterEnergy.Get(caster)
	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("resolved intent = %d, want Chain of Chaos spell",
			g.turn.ResolvedIntent)
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("Chain of Chaos state changed on save restore")
	}
}

// Representative cone, targeted blast, and sight-wide spells must reach
// their Lua handlers through an actual monster action, not only direct tests.
func TestMonsterAreaSpellbookShapes(t *testing.T) {
	cases := []struct {
		name string
		path string
	}{
		{
			name: "adjacent pulse",
			path: "testdata/monster-area-irradiate",
		},
		{
			name: "cone",
			path: "testdata/monster-area-glaciate",
		},
		{
			name: "targeted blast",
			path: "testdata/monster-area-fire-storm",
		},
		{
			name: "sight-wide",
			path: "testdata/monster-area-refrigeration",
		},
		{
			name: "fragmentable terrain",
			path: "testdata/monster-area-lrd",
		},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			g, caster, _ := moddedEndoplasmGame(t, testCase.path)
			switch testCase.name {
			case "adjacent pulse":
				placePlayerAdjacentToCaster(t, g, caster)
			case "fragmentable terrain":
				placePlayerByFragmentableWall(t, g, caster)
			default:
				placePlayerInSlugLine(t, g, caster)
			}

			energy, _ := g.stores.MonsterEnergy.Get(caster)
			energy.Points = 80

			if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
				t.Fatal(err)
			}

			if g.turn.ResolvedIntent != ecs.IntentSpell {
				t.Fatalf("resolved intent = %d, want spell",
					g.turn.ResolvedIntent)
			}
		})
	}
}
