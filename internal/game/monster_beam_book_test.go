package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"

	"github.com/gravestench/akara"
)

// Cloud targeting rejects a shot whose potential field touches an ally.
// Find an empty area, place the caster and player five cells apart, and
// open their ray. This keeps the test independent of random Dungeon shape
// while retaining the real targeting, cloud placement, and save path.
func placePlayerInCloudLine(t *testing.T, g *Game, caster akara.Entity) {
	t.Helper()

	position, _ := g.stores.Positions.Get(caster)
	level := g.levels[position.LevelID]

	for y := 8; y < len(level.terrain)-8; y++ {
		for x := 8; x < level.width-13; x++ {
			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if _, occupied := level.ActorAt(x+5, y); occupied {
				continue
			}

			isolated := true

			for nearbyY := y - 6; nearbyY <= y+6 && isolated; nearbyY++ {
				for nearbyX := x - 6; nearbyX <= x+11; nearbyX++ {
					actor, occupied := level.ActorAt(nearbyX, nearbyY)

					if occupied && actor != caster && actor != g.player {
						isolated = false
						break
					}
				}
			}

			if !isolated {
				continue
			}

			for distance := 0; distance <= 5; distance++ {
				if !level.Walkable(x+distance, y) {
					if err := level.SetCell(x+distance, y, terrain.Floor); err != nil {
						t.Fatal(err)
					}
				}
			}

			// Cloud planning expands whole walkable shells. Open space around
			// the impact point so a narrow corridor cannot grow back to caster.
			for cloudY := y - 3; cloudY <= y+3; cloudY++ {
				for cloudX := x + 2; cloudX <= x+8; cloudX++ {
					if !level.Walkable(cloudX, cloudY) {
						if err := level.SetCell(cloudX, cloudY,
							terrain.Floor); err != nil {
							t.Fatal(err)
						}
					}
				}
			}

			if err := level.MoveActor(caster, x, y); err != nil {
				t.Fatal(err)
			}

			if err := level.MoveActor(g.player, x+5, y); err != nil {
				t.Fatal(err)
			}

			if !level.ClearProjectilePath(x, y, x+5, y) {
				t.Fatal("prepared cloud arena has no clear ray")
			}

			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			return
		}
	}

	t.Fatal("could not prepare an isolated cloud arena")
}

// A source-shaped beam must pass through the real monster decision, beam
// contact, and saved turn state before replay continues.
func assertMonsterBeamBookCastAndSave(
	t *testing.T,
	overlay string,
	contactText string,
	expectedCloud string,
) {
	t.Helper()

	g, caster, rules := moddedEndoplasmGame(t, overlay)

	if expectedCloud == "" {
		placePlayerInSlugLine(t, g, caster)
	} else {
		placePlayerInCloudLine(t, g, caster)
	}

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	events, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("monster beam resolved intent %d, want spell",
			g.turn.ResolvedIntent)
	}

	contact := false

	for _, event := range events {
		if strings.Contains(event.Text, contactText) {
			contact = true
		}
	}

	if !contact {
		t.Fatalf("monster beam produced no %q contact: %+v",
			contactText, events)
	}

	if expectedCloud != "" {
		store := g.scripts.Components()["world.cloud"]
		foundCloud := false

		for _, entity := range store.Entities() {
			cloud, _ := store.Get(entity)
			kind, _ := cloud.Get("kind_id")

			if kind == expectedCloud {
				foundCloud = true
				break
			}
		}

		if !foundCloud {
			t.Fatalf("monster beam left no %s cloud", expectedCloud)
		}
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
		t.Fatal("monster beam changed on save restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}

// Natural Fire Breath and magical Metal Splinters use the same intent and
// save path while their Lua profiles choose different contact policies.
func TestMonsterFireBreathBookCastAndSave(t *testing.T) {
	assertMonsterBeamBookCastAndSave(t,
		"testdata/monster-elemental-breaths", "blast of flame", "")
}

func TestMonsterMetalSplintersBookCastAndSave(t *testing.T) {
	assertMonsterBeamBookCastAndSave(t,
		"testdata/monster-fragment-rays", "spray of metal splinters", "")
}

// Flaming Cloud must produce a saved fire field through a live monster cast.
func TestMonsterFlamingCloudBookCastAndSave(t *testing.T) {
	assertMonsterBeamBookCastAndSave(t,
		"testdata/monster-cloud-casts", "blast of flame", "CLOUD_FIRE")
}
