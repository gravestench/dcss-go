package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// Choose a real saved RNG stream state whose first three one-in-ten draws
// succeed. Player training or conduct may spend one or two religion draws
// earlier in the same action; this keeps the Jiyva check deterministic
// without replacing the production RNG or mocking the periodic policy.
func forceJiyvaSpawnRoll(t *testing.T, g *Game) {
	t.Helper()

	for candidate := uint64(0); candidate < 100000; candidate++ {
		probe := RestoreRNGStreams(g.rng.seed, map[string]uint64{
			"religion": candidate,
		})
		allZero := true

		for draw := 0; draw < 3; draw++ {
			roll, err := probe.Intn("religion", 10)

			if err != nil {
				t.Fatal(err)
			}

			if roll != 0 {
				allZero = false
				break
			}
		}

		if allZero {
			g.rng.states["religion"] = candidate

			return
		}
	}

	t.Fatal("could not find a Jiyva spawn roll")
}

// A live Jiyva endoplasm consumes an ordinary floor stack before the
// monster decision can move or cast. The test uses the production scheduler,
// Lua ruleset, ECS items, and save path rather than a second feeding model.
func TestJiyvaEndoplasmFeedsBeforeOrdinaryAction(t *testing.T) {
	g, endoplasm := newEndoplasmGame(t, false)
	worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("player has no worship state")
	}

	if err := worship.Set("god_id", "GOD_JIYVA"); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(endoplasm)
	health, _ := g.stores.Health.Get(endoplasm)
	before := health.Current
	item, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(item, ecs.Item{
		KindID:   "POT_CURING",
		Quantity: 3,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Positions.Set(item, *position); err != nil {
		t.Fatal(err)
	}

	energy, _ := g.stores.MonsterEnergy.Get(endoplasm)

	energy.Points = 80

	if _, err := g.runAction(endoplasm, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.stores.Items.Has(item) {
		t.Fatal("Jiyva endoplasm left an edible floor stack")
	}

	if health.Current <= before {
		t.Fatal("feeding did not heal the endoplasm")
	}

	after, _ := g.stores.Positions.Get(endoplasm)

	if *after != *position {
		t.Fatal("feeding did not consume the monster action")
	}

	// Direct runAction bypasses the scheduler's energy subtraction. Restore
	// expects the same post-action value the ordinary scheduler would leave.
	energy.Points = 70

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if restored.stores.Items.Has(item) {
		t.Fatal("restored floor resurrected eaten item")
	}

	saved, _ := restored.stores.Health.Get(endoplasm)

	if saved.Current != health.Current {
		t.Fatal("restored endoplasm lost meal HP")
	}
}

// A Polymorph marker remembers the roster species, while Jiyva growth
// records the replacement slime body's own HP roll. Restore must validate
// those two histories against their respective species.
func TestJiyvaPolymorphedSlimeGrowthRestores(t *testing.T) {
	g, monster := newEndoplasmGame(t, false)
	actor, _ := g.stores.Actors.Get(monster)
	health, _ := g.stores.Health.Get(monster)

	actor.KindID = "MONS_JELLY"
	actor.Speed = 10
	health.Current = 16
	health.Max = 16

	if _, err := g.scripts.Components()["magic.monster_polymorph"].Set(
		monster,
		map[string]any{
			"original_kind_id": "MONS_ENDOPLASM",
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["religion.jiyva_growth"].Set(
		monster,
		map[string]any{
			"birth_max":       int64(16),
			"split_count":     int64(0),
			"born_from_split": false,
		},
	); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["religion.jiyva_growth"].Has(monster) {
		t.Fatal("restored polymorphed slime lost its growth history")
	}
}

// The meal budget can stop before a stack is empty. The remaining item and
// fed monster must both survive the production save and restore path.
func TestJiyvaPartialStackAndGrowthRestore(t *testing.T) {
	g, endoplasm := newEndoplasmGame(t, false)
	worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("player has no worship state")
	}

	if err := worship.Set("god_id", "GOD_JIYVA"); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(endoplasm)
	item, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(item, ecs.Item{
		KindID:   "POT_CURING",
		Quantity: 20,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Positions.Set(item, *position); err != nil {
		t.Fatal(err)
	}

	energy, _ := g.stores.MonsterEnergy.Get(endoplasm)

	energy.Points = 80

	if _, err := g.runAction(endoplasm, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	energy.Points = 70

	remaining, found := g.stores.Items.Get(item)

	if !found ||
		remaining.Quantity <= 0 ||
		remaining.Quantity >= 20 {
		t.Fatalf("Jiyva meal left invalid partial stack: %+v", remaining)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	saved, found := restored.stores.Items.Get(item)

	if !found ||
		saved.Quantity != remaining.Quantity ||
		!restored.scripts.Components()["religion.jiyva_growth"].Has(endoplasm) {
		t.Fatal("partial meal or growth history changed on restore")
	}
}

// The source timer survives a real player action and restore. Forcing its
// next due aut to the coming action tests one firing and the following draw
// through the production scheduler without relying on a lucky spawn roll.
func TestJiyvaEcologyTimerContinuesAfterRestore(t *testing.T) {
	g, _ := newEndoplasmGame(t, false)
	worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("player has no worship state")
	}

	if err := worship.Set("god_id", "GOD_JIYVA"); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	clock, found := g.scripts.Components()["religion.jiyva_ecology"].Get(g.player)

	if !found {
		t.Fatal("player action did not schedule the Jiyva timer")
	}

	if err := clock.Set("next_due_aut", int64(g.currentAut+10)); err != nil {
		t.Fatal(err)
	}

	forceJiyvaSpawnRoll(t, g)

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	left, leftErr := g.Step(Command{Kind: CommandWait})
	right, rightErr := restored.Step(Command{Kind: CommandWait})

	if leftErr != nil {
		t.Fatal(leftErr)
	}

	if rightErr != nil {
		t.Fatal(rightErr)
	}

	if !reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("Jiyva timer continued differently after restore")
	}

	if len(g.scripts.Components()["religion.jiyva_spawn"].Entities()) == 0 {
		t.Fatal("due Jiyva effect did not create a jelly")
	}

	spawnedSave, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer spawnedSave.Close()

	clock, found = g.scripts.Components()["religion.jiyva_ecology"].Get(g.player)

	if !found {
		t.Fatal("Jiyva timer disappeared after its effect fired")
	}

	next, err := clock.Get("next_due_aut")

	if err != nil {
		t.Fatal(err)
	}

	if next.(int64) <= int64(g.currentAut) {
		t.Fatalf("Jiyva next timer = %v, current aut = %d", next, g.currentAut)
	}
}
