package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/terrain"
)

// Clear walls admit ordinary sight but interrupt source no-trans cries.
func TestMonsterBattlecryNoTransSight(t *testing.T) {
	g := newStepGame(t)
	level, err := NewLevel(99, [][]terrain.ID{{
		terrain.Floor,
		terrain.ClearRockWall,
		terrain.Floor,
	}}, g.stores.Positions)

	if err != nil {
		t.Fatal(err)
	}

	grid := scriptGrid{
		levels: map[int]*Level{
			99: level,
		},
		opaque: func(int) map[point]bool {
			return nil
		},
	}

	ordinary, err := grid.Visible(99, 0, 0, 7, 2, 0)

	if err != nil {
		t.Fatal(err)
	}

	noTrans, err := grid.VisibleNoTrans(99, 0, 0, 7, 2, 0)

	if err != nil {
		t.Fatal(err)
	}

	if !ordinary || noTrans {
		t.Fatalf("clear wall sight: ordinary %t, no-trans %t",
			ordinary, noTrans)
	}
}

// A real caster inspires a same-genus ally, persists its actor-owned Might,
// and resumes from the same saved monster-spell and AI streams.
func TestMonsterBattlecryBookCastAndSave(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-battlecries")
	placePlayerInSlugLine(t, g, caster)
	ally := nearbyEndoplasmAlly(t, g, caster)
	energy, _ := g.stores.MonsterEnergy.Get(caster)
	casterPos, _ := g.stores.Positions.Get(caster)
	playerPos, _ := g.stores.Positions.Get(g.player)
	level := g.levels[casterPos.LevelID]

	if level.ClearProjectilePath(casterPos.X, casterPos.Y,
		playerPos.X, playerPos.Y) {
		t.Fatal("expected intervening ally to block physical projectiles")
	}

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	boons := g.scripts.Components()["combat.monster_boons"]

	if g.turn.ResolvedIntent != ecs.IntentSpell ||
		!boons.Has(ally) || boons.Has(caster) {
		t.Fatalf("Battlecry intent %d, ally boon %t, caster boon %t",
			g.turn.ResolvedIntent, boons.Has(ally), boons.Has(caster))
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

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) ||
		!loaded.scripts.Components()["combat.monster_boons"].Has(ally) {
		t.Fatal("Battlecry's saved boon changed on restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}
