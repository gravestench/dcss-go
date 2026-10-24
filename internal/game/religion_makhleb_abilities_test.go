package game

import (
	"testing"
)

// The real command bridge invokes Makhleb's Lua registry and saves its
// resulting ECS summons without a Go patron branch.
func TestMakhlebServantsSurviveRestore(t *testing.T) {
	g, err := NewDungeonGame(1, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_MAKHLEB",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	for _, id := range []string{
		"ABIL_MAKHLEB_LESSER_SERVANT_OF_MAKHLEB",
		"ABIL_MAKHLEB_GREATER_SERVANT_OF_MAKHLEB",
	} {
		result, stepErr := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: id,
		})

		if stepErr != nil || result.Spent != 10 {
			t.Fatalf("%s spent %d: %v", id, result.Spent, stepErr)
		}

		// Keep the source-derived maximum while supplying HP for the next
		// fixed-cost ability; restore validation checks that maximum.
		health, found := g.stores.Health.Get(g.player)
		if !found {
			t.Fatal("Makhleb player has no health")
		}
		health.Current = health.Max
		if _, err := g.stores.Health.Set(g.player, *health); err != nil {
			t.Fatal(err)
		}
	}

	found := false
	for _, entity := range g.scripts.Components()["magic.summon"].Entities() {
		state, exists := g.scripts.Components()["magic.summon"].Get(entity)

		if !exists {
			continue
		}

		source, sourceErr := state.Get("source_id")
		if sourceErr == nil && source == "GOD_MAKHLEB" {
			found = true
		}
	}

	if !found {
		t.Fatal("Makhleb created no saved servant")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
}

// Both aimed powers use the ordinary ability command and spend one turn
// after a valid direction; an empty direction remains a free cancellation.
func TestMakhlebDestructionCommands(t *testing.T) {
	g, err := NewDungeonGame(2, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_MAKHLEB",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no grid position")
	}

	level := g.levels[position.LevelID]
	var aim point
	for _, candidate := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		if level.Walkable(position.X+candidate.x,
			position.Y+candidate.y) {
			aim = candidate
			break
		}
	}

	if aim == (point{}) {
		t.Fatal("player has no open adjacent aim")
	}

	for _, id := range []string{
		"ABIL_MAKHLEB_MINOR_DESTRUCTION",
		"ABIL_MAKHLEB_MAJOR_DESTRUCTION",
	} {
		cancel, cancelErr := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: id,
		})

		if cancelErr != nil || cancel.Spent != 0 {
			t.Fatalf("%s cancellation spent %d: %v",
				id, cancel.Spent, cancelErr)
		}

		result, stepErr := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: id,
			DX:        aim.x,
			DY:        aim.y,
		})

		if stepErr != nil || result.Spent != 10 {
			t.Fatalf("%s spent %d: %v", id, result.Spent, stepErr)
		}
	}
}
