package game

import (
	"reflect"
	"testing"
)

// The Lua statuses are the authoritative state for several independent
// spell effects. A save must carry their timers and mirror recast clock
// without rebuilding those values from a book or a Lua module global.
func TestMonsterSupportStatusesSurviveSave(t *testing.T) {
	g := newZapGame(t)
	monsters := g.stores.MonsterEnergy.Entities()

	if len(monsters) == 0 {
		t.Fatal("scenario has no monster")
	}

	monster := monsters[0]
	states := map[string]map[string]any{
		"combat.monster_boons": {
			"haste_aut": int64(80),
			"might_aut": int64(50),
			"swift_aut": int64(30),
		},

		"combat.monster_brilliance_aura": {
			"remaining_aut": int64(70),
		},

		"combat.monster_empowered_spells": {
			"remaining_aut": int64(60),
		},

		"combat.monster_injury_mirror": {
			"remaining_aut": int64(40),
			"recast_at_aut": int64(200),
		},

		"combat.monster_repulsion": {
			"active": true,
		},

		"combat.monster_still_winds": {
			"remaining_aut": int64(90),
		},

		"combat.monster_trogs_hand": {
			"remaining_aut": int64(100),
		},
	}

	for name, fields := range states {
		store := g.scripts.Components()[name]

		if store == nil {
			t.Fatalf("missing Lua component %s", name)
		}

		if _, err := store.Set(monster, fields); err != nil {
			t.Fatalf("set %s: %v", name, err)
		}
	}

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("monster support state changed across save and restore")
	}

	for name := range states {
		if !loaded.scripts.Components()[name].Has(monster) {
			t.Fatalf("restored monster lost %s", name)
		}
	}
}

// An active Berserker Rage deliberately exceeds catalog HP bounds. The
// save validator must allow that source multiplier while the saved frenzy
// owner records the matching HP inflation.
func TestBerserkMonsterHealthSurvivesSave(t *testing.T) {
	g := newZapGame(t)
	monsters := g.stores.MonsterEnergy.Entities()

	if len(monsters) == 0 {
		t.Fatal("scenario has no monster")
	}

	monster := monsters[0]
	health, _ := g.stores.Health.Get(monster)

	health.Current = (health.Current*3 + 1) / 2
	health.Max = (health.Max*3 + 1) / 2

	if _, err := g.scripts.Components()["magic.monster_allegiance"].Set(
		monster,
		map[string]any{
			"frenzy_aut": int64(100),
			"berserk_hp": true,
		}); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("Berserker Rage HP changed on save restore")
	}
}
