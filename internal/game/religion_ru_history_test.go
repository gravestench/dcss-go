package game

import (
	"strings"
	"testing"
)

// Accept two different source sacrifices across a save boundary. The
// second action must add to the restored history rather than restart it.
func TestRuSacrificeHistoryAccumulatesAcrossRestore(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	g.world.DestroyEntity(rat)
	worship := g.scripts.Components()["religion.worship"]

	if _, err := worship.Set(g.player, map[string]any{
		"god_id": "GOD_RU",
		"piety":  int64(10),
	}); err != nil {
		t.Fatal(err)
	}

	setRuHistoryOffer(t, g, "ABIL_RU_SACRIFICE_WORDS", 0)
	acceptRuHistoryOffer(t, g, "ABIL_RU_SACRIFICE_WORDS")
	assertRuHistoryCount(t, g, 1)

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	assertRuHistoryCount(t, loaded, 1)
	setRuHistoryOffer(t, loaded, "ABIL_RU_SACRIFICE_DRINK", 1)
	acceptRuHistoryOffer(t, loaded, "ABIL_RU_SACRIFICE_DRINK")
	assertRuHistoryCount(t, loaded, 2)
}

// Install a current quoted offer through the real player component store.
// Words and Drink have fixed mutations, so no variant pool is needed.
func setRuHistoryOffer(t *testing.T, g *Game, ability string, count int64) {
	t.Helper()

	if _, err := g.scripts.Components()["religion.ru"].Set(
		g.player,
		map[string]any{
			"available": []any{ability},
			"quoted_piety": map[string]any{
				ability: int64(30),
			},
			"sacrifice_mutations": count,
		},
	); err != nil {
		t.Fatal(err)
	}
}

// Use the same forced command emitted after the UI confirmation prompt.
func acceptRuHistoryOffer(t *testing.T, g *Game, ability string) {
	t.Helper()
	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: ability,
		Forced:    true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("Ru sacrifice spent %d aut: %+v", result.Spent,
			result.Events)
	}
}

// A cleared offer must leave the lifetime count on the player.
func assertRuHistoryCount(t *testing.T, g *Game, want int64) {
	t.Helper()
	record, found := g.scripts.Components()["religion.ru"].Get(g.player)

	if !found {
		t.Fatal("player lost Ru history")
	}

	count, err := record.Get("sacrifice_mutations")

	if err != nil {
		t.Fatal(err)
	}

	if count != want {
		t.Fatalf("Ru sacrifice count = %v, want %d", count, want)
	}
}

// Ru's accepted mutation count is historical player state. Restore must
// keep it even when the current offer list is empty, and reject corruption.
func TestRuSacrificeHistorySurvivesSaveAndRejectsNegativeCount(
	t *testing.T,
) {
	g := newStepGame(t)
	worship := g.scripts.Components()["religion.worship"]

	if _, err := worship.Set(g.player, map[string]any{
		"god_id": "GOD_RU",
		"piety":  int64(50),
	}); err != nil {
		t.Fatal(err)
	}

	ru := g.scripts.Components()["religion.ru"]

	if _, err := ru.Set(g.player, map[string]any{
		"sacrifice_mutations": int64(4),
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	record, found := loaded.scripts.Components()["religion.ru"].Get(
		loaded.player)

	if !found {
		t.Fatal("restored player lost Ru history")
	}

	count, err := record.Get("sacrifice_mutations")

	if err != nil {
		t.Fatal(err)
	}

	if count != int64(4) {
		t.Fatalf("restored Ru sacrifice count = %v", count)
	}

	if err := record.Set("sacrifice_mutations", int64(-1)); err != nil {
		t.Fatal(err)
	}

	invalid, err := Restore(loaded.Snapshot())

	if invalid != nil {
		invalid.Close()
	}

	if err == nil {
		t.Fatal("negative Ru history passed save validation")
	}

	if !strings.Contains(err.Error(), "invalid Ru sacrifice progress") {
		t.Fatalf("negative Ru history passed save validation: %v", err)
	}
}
