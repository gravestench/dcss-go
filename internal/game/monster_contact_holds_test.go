package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

// A monster victim uses the same saved direct grip as the player. Moving a
// live catalog actor into an adjacent free cell avoids synthetic save data.
func TestMonsterConstrictedSaveRoundTrip(t *testing.T) {
	g, snake := newBallPythonGame(t)
	snakePosition, _ := g.stores.Positions.Get(snake)
	var victim akara.Entity

	for _, candidate := range g.stores.AI.Entities() {
		position, exists := g.stores.Positions.Get(candidate)

		if candidate != snake && exists &&
			position.LevelID == snakePosition.LevelID {
			victim = candidate
			break
		}
	}

	if victim == 0 {
		t.Fatal("generated Dungeon has no second monster")
	}

	level := g.levels[snakePosition.LevelID]
	placed := false

	for dy := -1; dy <= 1 && !placed; dy++ {
		for dx := -1; dx <= 1 && !placed; dx++ {
			if dx == 0 && dy == 0 {
				continue
			}

			x := snakePosition.X + dx
			y := snakePosition.Y + dy

			if level.Walkable(x, y) {
				if _, occupied := level.ActorAt(x, y); !occupied {
					placed = level.MoveActor(victim, x, y) == nil
				}
			}
		}
	}

	if !placed {
		t.Fatal("python has no free adjacent cell")
	}

	if _, err := g.stores.Constricted.Set(victim, ecs.Constricted{
		By:             snake,
		EscapeAttempts: 2,
		HeldAut:        20,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	grip, found := loaded.stores.Constricted.Get(victim)

	if !found || grip.By != snake || grip.HeldAut != 20 ||
		!reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatalf("monster grip changed across save: %+v", grip)
	}
}

// A player can now be the water-hold victim. Its source remains a live
// adjacent monster across restore, and time spent waiting advances damage.
func TestPlayerWaterHoldSaveAndDrowning(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	holds := g.scripts.Components()["combat.water_hold"]

	if _, err := holds.Set(g.player, map[string]any{
		"by":           rat,
		"elapsed_aut":  10,
		"substance_id": "water",
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["combat.water_hold"].Has(loaded.player) ||
		!reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatalf("player water hold changed across save: present=%v",
			loaded.scripts.Components()["combat.water_hold"].Has(loaded.player))
	}

	grantTestSpell(t, loaded, "SPELL_MAGIC_DART")
	cast, err := loaded.Step(Command{
		Kind:    CommandCast,
		SpellID: "SPELL_MAGIC_DART",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	blocked := false

	for _, event := range cast.Events {
		blocked = blocked || strings.Contains(event.Text,
			"unable to breathe")
	}

	if cast.Spent != 0 || !blocked {
		t.Fatalf("engulfed cast was not rejected without time: %+v",
			cast)
	}

	before, _ := loaded.stores.Health.Get(loaded.player)
	start := before.Current

	if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	after, _ := loaded.stores.Health.Get(loaded.player)

	if after.Current >= start {
		t.Fatalf("engulfed player HP stayed at %d", after.Current)
	}

	hold, found := loaded.scripts.Components()["combat.water_hold"].Get(
		loaded.player)

	if !found {
		t.Fatal("water hold vanished before its source left")
	}

	fields, err := hold.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	if fields["elapsed_aut"].(int64) <= 10 {
		t.Fatalf("player drowning time did not advance: %+v", fields)
	}
}
