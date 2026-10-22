package game

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
)

// Run two real player actions beside the same terrain cell. Worship is the
// only difference, so the scheduler must grant and then revoke Jiyva's
// zero-star wall immunity without a copied passive flag. Restore checks
// the grid and health that the Lua policy actually changed.
func TestJiyvaSlimeWallImmunityAndDamageRestore(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	if err := level.SetCell(2, 1, terrain.SlimyWall); err != nil {
		t.Fatal(err)
	}

	worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("player has no worship state")
	}

	if err := worship.Set("god_id", "GOD_JIYVA"); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)
	initialHP := health.Current

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	health, _ = g.stores.Health.Get(g.player)

	if health.Current != initialHP {
		t.Fatalf("Jiyva worshipper lost HP beside slime wall: %d -> %d",
			initialHP, health.Current)
	}

	if err := worship.Set("god_id", "GOD_NO_GOD"); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	health, _ = g.stores.Health.Get(g.player)
	splashes := 0

	for _, event := range result.Events {
		if strings.Contains(event.Text, "splashed with acid") {
			splashes++
		}
	}

	if splashes != 1 {
		t.Fatalf("one player action caused %d wall exposures", splashes)
	}

	if health.Current >= initialHP {
		t.Fatalf("unprotected player ignored slime wall: HP %d", health.Current)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	savedHealth, _ := restored.stores.Health.Get(restored.player)

	if savedHealth.Current != health.Current {
		t.Fatalf("restored wall damage = %d, want %d",
			savedHealth.Current, health.Current)
	}

	if restored.levels[1].terrain[1][2] != terrain.SlimyWall {
		t.Fatal("restored level lost the slimy wall")
	}

	if worshipGod(t, restored) != "GOD_NO_GOD" {
		t.Fatal("restored worship changed wall immunity")
	}
}

// Monsters use two independent four-sided wall rolls per action. Their
// dedicated saved stream makes a duplicate scheduler registration visible
// even if the first exposure kills the monster before the second can hit.
func TestJiyvaSlimeWallMonsterActsOnce(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	position, _ := g.stores.Positions.Get(rat)
	level := g.levels[position.LevelID]

	if err := level.SetCell(position.X, position.Y+1,
		terrain.SlimyWall); err != nil {
		t.Fatal(err)
	}

	g.rng.states["slime_wall"] = 17
	probe := RestoreRNGStreams(g.rng.seed, map[string]uint64{
		"slime_wall": 17,
	})

	for range 2 {
		if _, err := probe.Intn("slime_wall", 4); err != nil {
			t.Fatal(err)
		}
	}

	events, err := g.runAction(rat, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	burned := false

	for _, event := range events {
		if strings.Contains(event.Text, "wall burns") {
			burned = true
		}
	}

	if !burned {
		t.Fatal("visible monster wall damage lacked a source-style message")
	}

	if g.rng.states["slime_wall"] != probe.states["slime_wall"] {
		t.Fatal("monster wall exposure did not consume exactly two dice")
	}
}
