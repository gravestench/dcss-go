package game

import "testing"

// A pursuer adjacent to an accepted Dungeon stair follows both directions
// as the same ECS entity. Its temporary mark must be gone before save and
// its original roster identity must remain valid across restore.
func TestPursuerFollowsLinkedStairsAcrossRestore(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	weapon := giveTestMonsterWeapon(t, g, rat)

	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(rat, 6, 3); err != nil {
		t.Fatal(err)
	}

	ai, found := g.stores.AI.Get(rat)

	if !found {
		t.Fatal("pursuer has no AI")
	}

	ai.Behavior = "seek"
	ai.TargetX = 7
	ai.TargetY = 3

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(rat)

	if !found || position.LevelID != 2 {
		t.Fatalf("pursuer did not descend: %+v", position)
	}

	if g.scripts.Components()["world.stair_follower"].Has(rat) {
		t.Fatal("stair mark survived the completed action")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	carrier, found := restored.stores.CarriedBy.Get(weapon)

	if !found || carrier.Holder != rat {
		t.Fatalf("follower lost carried weapon: %+v", carrier)
	}

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, found = restored.stores.Positions.Get(rat)

	if !found || position.LevelID != 1 {
		t.Fatalf("same pursuer did not ascend: %+v", position)
	}
}

// A follower mark belongs to one action only. A save carrying it would
// suppress the monster's next decision after reload, so reject that state.
func TestRestoreRejectsStaleStairFollowerMark(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if _, err := g.scripts.Components()["world.stair_follower"].Set(
		rat,
		map[string]any{
			"taking_stairs": true,
			"order":         int64(1),
		},
	); err != nil {
		t.Fatal(err)
	}

	if restored, err := Restore(g.Snapshot()); err == nil {
		restored.Close()
		t.Fatal("restored a stale one-action stair mark")
	}
}
