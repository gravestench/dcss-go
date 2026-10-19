package game

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/content"
	"github.com/gravestench/akara"
)

type testSpellRecord struct {
	InLibrary   bool
	KnownSlot   int64
	LetterSlot  int64
	FutureLevel int64
}

func playerSpellRecords(t *testing.T, g *Game) map[string]testSpellRecord {
	t.Helper()

	store, found := g.scripts.Components()["character.spell"]

	if !found {
		t.Fatal("character.spell schema was not registered")
	}

	spells := make(map[string]testSpellRecord)

	for _, entity := range store.Entities() {
		record, hasRecord := store.Get(entity)

		if !hasRecord {
			t.Fatalf("spell entity %d has no record", entity)
		}

		owner, ownerErr := record.Get("owner")

		if ownerErr != nil {
			t.Fatal(ownerErr)
		}

		if owner != akara.Entity(g.player) {
			continue
		}

		spellID, spellErr := record.Get("spell_id")
		library, libraryErr := record.Get("in_library")
		slot, slotErr := record.Get("known_slot")
		letter, letterErr := record.Get("letter_slot")
		future, futureErr := record.Get("future_level")

		fieldErrors := []error{
			spellErr,
			libraryErr,
			slotErr,
			letterErr,
			futureErr,
		}

		for _, fieldErr := range fieldErrors {
			if fieldErr != nil {
				t.Fatalf("spell entity %d: %v", entity, fieldErr)
			}
		}

		id := spellID.(string)

		if _, duplicate := spells[id]; duplicate {
			t.Fatalf("duplicate player spell record %s", id)
		}

		spells[id] = testSpellRecord{
			InLibrary:   library.(bool),
			KnownSlot:   slot.(int64),
			LetterSlot:  letter.(int64),
			FutureLevel: future.(int64),
		}
	}

	return spells
}

func TestStartingSpellHasOwnedECSRecord(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_FIRE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	state, found := playerSpellRecords(t, g)["SPELL_FOXFIRE"]

	if !found {
		t.Fatal("starting Foxfire record is missing")
	}

	if !state.InLibrary ||
		state.KnownSlot != 1 ||
		state.LetterSlot != 1 {
		t.Fatalf("starting Foxfire state = %+v, found %t", state, found)
	}
}

func TestRestoreRejectsInvalidKnownSpellSlot(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_FIRE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	snapshot := g.Snapshot()
	changed := false

	for entityIndex := range snapshot.Entities {
		for componentIndex := range snapshot.Entities[entityIndex].Dynamic {
			component := &snapshot.Entities[entityIndex].Dynamic[componentIndex]

			if component.Schema != "character.spell" {
				continue
			}

			if string(component.Values["spell_id"]) != `"SPELL_FOXFIRE"` {
				continue
			}

			component.Values["known_slot"] = json.RawMessage("53")
			changed = true
		}
	}

	if !changed {
		t.Fatal("save has no starting Foxfire record")
	}

	loaded, restoreErr := Restore(snapshot)

	if loaded != nil {
		loaded.Close()
	}

	if restoreErr == nil {
		t.Fatal("invalid known spell slot was accepted")
	}

	if !strings.Contains(restoreErr.Error(), "known spell slot") {
		t.Fatalf("invalid known spell slot was accepted: %v", restoreErr)
	}
}

func TestPlayerSpellScopeMatchesPinnedSource(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_FIGHTER", "WPN_FLAIL", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	cases := []struct {
		spellID string
		want    string
	}{
		{
			spellID: "SPELL_FOXFIRE",
			want:    "book",
		},

		{
			spellID: "SPELL_THROW_FLAME",
			want:    "invoked",
		},

		{
			spellID: "SPELL_GLACIATE",
			want:    "none",
		},

		{
			spellID: "SPELL_TELEPORT_SELF",
			want:    "none",
		},

		{
			spellID: "SPELL_DEBUGGING_RAY",
			want:    "none",
		},
	}

	for _, tc := range cases {
		t.Run(tc.spellID, func(t *testing.T) {
			result, policyErr := g.scripts.Policy(
				"magic.player_scope",
				map[string]any{"spell_id": tc.spellID},
			)

			if policyErr != nil {
				t.Fatal(policyErr)
			}

			if result["scope"] != tc.want {
				t.Fatalf("scope = %v, want %s", result["scope"], tc.want)
			}
		})
	}
}

func TestRestoreRejectsMonsterOnlyPlayerSpell(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_FIRE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	snapshot := g.Snapshot()
	changed := false

	for entityIndex := range snapshot.Entities {
		for componentIndex := range snapshot.Entities[entityIndex].Dynamic {
			component := &snapshot.Entities[entityIndex].Dynamic[componentIndex]

			if component.Schema != "character.spell" ||
				string(component.Values["spell_id"]) != `"SPELL_FOXFIRE"` {
				continue
			}

			component.Values["spell_id"] = json.RawMessage(`"SPELL_GLACIATE"`)
			changed = true
		}
	}

	if !changed {
		t.Fatal("save has no starting Foxfire record")
	}

	loaded, restoreErr := Restore(snapshot)

	if loaded != nil {
		loaded.Close()
	}

	if restoreErr == nil {
		t.Fatal("monster-only player spell was accepted")
	}

	if !strings.Contains(restoreErr.Error(), "player spell") {
		t.Fatalf("monster-only player spell was accepted: %v", restoreErr)
	}
}

func TestPlayerSpellScopeCoversPinnedCatalog(t *testing.T) {
	catalog, err := content.LoadDefaultSpells()

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_FIGHTER", "WPN_FLAIL", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	counts := map[string]int{
		"book":    0,
		"invoked": 0,
		"none":    0,
	}

	for _, id := range catalog.SpellIDs() {
		result, policyErr := g.scripts.Policy(
			"magic.player_scope",
			map[string]any{"spell_id": id},
		)

		if policyErr != nil {
			t.Fatal(policyErr)
		}

		scope, found := result["scope"].(string)

		if !found {
			t.Fatalf("spell %s has no scope", id)
		}

		counts[scope]++
	}

	if counts["book"] != 109 ||
		counts["invoked"] != 16 ||
		counts["none"] != 278 {
		t.Fatalf("player spell scope counts = %v", counts)
	}
}
