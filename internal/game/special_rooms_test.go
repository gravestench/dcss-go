package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
)

// A test overlay changes only source map eligibility. The bundled hooks,
// variable geometry, tagged child, ECS population, and save path stay live.
func TestSpecialRoomPlacesAndRestoresNamedChild(t *testing.T) {
	rules, err := modfs.Load("testdata/special-rooms")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		29,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	parent := false
	child := false

	for _, id := range g.levels[1].VaultIDs() {
		parent = parent || id == "special_room"
		child = child || id == "special_room_kobold"
	}

	if !parent || !child {
		t.Fatalf("special room history lacks parent or child: %v",
			g.levels[1].VaultIDs())
	}

	foundMonster := false

	for _, entity := range g.stores.Actors.Entities() {
		if !g.scripts.Components()["vault.origin"].Has(entity) {
			continue
		}

		actor, exists := g.stores.Actors.Get(entity)

		if exists && actor.KindID == "MONS_KOBOLD" {
			foundMonster = true
		}
	}

	if !foundMonster {
		t.Fatal("authored kobold room produced no ECS kobold")
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("special room population or source history changed on restore")
	}
}
