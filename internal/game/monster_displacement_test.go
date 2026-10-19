package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A real monster spell choice must move its Akara actor through the Lua
// blink policy. The moved position and random stream must survive restore.
func TestMonsterBlinkBookCastAndSave(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-displacement")
	placePlayerInSlugLine(t, g, caster)

	before, _ := g.stores.Positions.Get(caster)
	start := *before
	energy, _ := g.stores.MonsterEnergy.Get(caster)
	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("resolved intent = %d, want Blink spell",
			g.turn.ResolvedIntent)
	}

	after, _ := g.stores.Positions.Get(caster)

	if after.LevelID != start.LevelID ||
		(after.X == start.X && after.Y == start.Y) {
		t.Fatalf("Blink did not move caster: before=%+v after=%+v",
			start, after)
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
		t.Fatal("Blink position changed on save restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}

// Recall's two timers belong to an Akara component. A saved mid-chant
// caster must resume with exactly that timer, while impossible times fail.
func TestMonsterRecallTimerSaveValidation(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-displacement")
	store := g.scripts.Components()["magic.monster_recall"]

	if _, err := store.Set(caster, map[string]any{
		"foe":        g.player,
		"chant_aut":  int64(20),
		"breath_aut": int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("Recall chant changed on save restore")
	}

	loaded.Close()

	if _, err := store.Set(g.player, map[string]any{
		"foe":        caster,
		"chant_aut":  int64(20),
		"breath_aut": int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := RestoreWithRules(g.Snapshot(), rules,
		RestorePolicy{}); err == nil ||
		!strings.Contains(err.Error(), "invalid Word of Recall owner") {
		t.Fatalf("non-monster recall owner restore error = %v", err)
	}

	store.Remove(g.player)

	if _, err := store.Set(caster, map[string]any{
		"foe":        g.player,
		"chant_aut":  int64(40),
		"breath_aut": int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := RestoreWithRules(g.Snapshot(), rules,
		RestorePolicy{}); err == nil ||
		!strings.Contains(err.Error(), "invalid Word of Recall state") {
		t.Fatalf("invalid recall timer restore error = %v", err)
	}
}
