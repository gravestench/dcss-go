package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
)

// A mod can leave a saved axe gate with no positive-weight axe child.
// Rejection must happen before the one-use gate or session RNG changes.
func TestBaileyEmptyThemePoolPreservesGate(t *testing.T) {
	rules, err := modfs.Load("testdata/bailey-zero-axe-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88151, "SP_HUMAN",
		"JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	placeBaileyPortalForTest(t, g)

	before, err := json.Marshal(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err == nil {
		t.Fatal("Bailey entered with no positive-weight axe child")
	}

	after, err := json.Marshal(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("empty Bailey theme pool changed saved session state")
	}
}

// A modded child wider than the grid reaches real Bailey geometry fitting.
// Failure there must undo the selected child and every staged mutation.
func TestBaileyChildPlacementFailureRollsBack(t *testing.T) {
	rules, err := modfs.Load("testdata/bailey-too-wide-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88152, "SP_HUMAN",
		"JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	placeBaileyPortalForTest(t, g)
	position, _ := g.stores.Positions.Get(g.player)
	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.bailey.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_bailey_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"theme":       "axe",
			"layout_id":   "bailey_axe_3",
		},
		"expected_branch_id": "BRANCH_BAILEY",
		"expected_level_id":  int64(3001),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), "does not fit") {
		t.Fatalf("oversized Bailey child was accepted: %v", err)
	}

	afterState := g.Snapshot()

	// Entity IDs may be reserved during a failed stage. Durable entities,
	// world RNG, player, gate, and floor data must remain identical.
	afterState.EntityCursor = beforeState.EntityCursor

	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("failed Bailey child placement changed saved session state")
	}
}
