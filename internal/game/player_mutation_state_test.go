package game

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"github.com/gravestench/akara"
)

type testMutationLevels struct {
	Innate    int64
	Acquired  int64
	Temporary int64
}

func TestRestoreRejectsMissingInnateMutation(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_BARACHI",
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
			record := &snapshot.Entities[entityIndex].Dynamic[componentIndex]

			if record.Schema == "character.mutation" &&
				string(record.Values["mutation_id"]) == `"MUT_HOP"` {
				record.Values["innate"] = json.RawMessage("0")
				record.Values["acquired"] = json.RawMessage("1")
				changed = true
			}
		}
	}

	if !changed {
		t.Fatal("snapshot has no starting Hop mutation")
	}

	loaded, restoreErr := Restore(snapshot)

	if loaded != nil {
		loaded.Close()
	}

	if restoreErr == nil {
		t.Fatal("missing innate mutation was accepted")
	}

	if !strings.Contains(restoreErr.Error(), "innate mutation") {
		t.Fatalf("missing innate mutation was accepted: %v", restoreErr)
	}
}

func TestAcquiredMutationRecordSurvivesSave(t *testing.T) {
	g, err := NewScenario(1, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	addPlayerMutation(t, g, "MUT_MISSING_EYE")
	before := playerMutationRecords(t, g)

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if after := playerMutationRecords(t, restored); !reflect.DeepEqual(after, before) {
		t.Fatalf("acquired mutation changed on restore: before=%v after=%v",
			before, after)
	}
}

func TestRestoreRejectsDuplicateMutationRecord(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_BARACHI",
		"JOB_FIRE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	snapshot := g.Snapshot()
	playerIndex := -1
	mutationIndex := -1

	for index, entity := range snapshot.Entities {
		if entity.ID == snapshot.PlayerID {
			playerIndex = index
		}

		for _, record := range entity.Dynamic {
			if record.Schema == "character.mutation" &&
				string(record.Values["mutation_id"]) == `"MUT_HOP"` {
				mutationIndex = index
			}
		}
	}

	if playerIndex < 0 || mutationIndex < 0 {
		t.Fatal("snapshot lacks player or Hop mutation")
	}

	for _, record := range snapshot.Entities[mutationIndex].Dynamic {
		if record.Schema == "character.mutation" &&
			string(record.Values["mutation_id"]) == `"MUT_HOP"` {
			snapshot.Entities[playerIndex].Dynamic = append(
				snapshot.Entities[playerIndex].Dynamic,
				record,
			)
		}
	}

	loaded, restoreErr := Restore(snapshot)

	if loaded != nil {
		loaded.Close()
	}

	if restoreErr == nil {
		t.Fatal("duplicate mutation record was accepted")
	}

	if !strings.Contains(restoreErr.Error(), "duplicate ID") {
		t.Fatalf("duplicate mutation record was accepted: %v", restoreErr)
	}
}

func playerMutationRecords(t *testing.T, g *Game) map[string]testMutationLevels {
	t.Helper()

	store, found := g.scripts.Components()["character.mutation"]

	if !found {
		t.Fatal("character.mutation schema was not registered")
	}

	levels := make(map[string]testMutationLevels)

	for _, entity := range store.Entities() {
		record, hasRecord := store.Get(entity)

		if !hasRecord {
			t.Fatalf("mutation entity %d has no record", entity)
		}

		owner, err := record.Get("owner")

		if err != nil {
			t.Fatal(err)
		}

		if owner != akara.Entity(g.player) {
			continue
		}

		rawID, idErr := record.Get("mutation_id")
		innate, innateErr := record.Get("innate")
		acquired, acquiredErr := record.Get("acquired")
		temporary, temporaryErr := record.Get("temporary")

		for _, fieldErr := range []error{
			idErr,
			innateErr,
			acquiredErr,
			temporaryErr,
		} {
			if fieldErr != nil {
				t.Fatal(fieldErr)
			}
		}

		id := rawID.(string)

		if _, duplicate := levels[id]; duplicate {
			t.Fatalf("duplicate player mutation record %s", id)
		}

		levels[id] = testMutationLevels{
			Innate:    innate.(int64),
			Acquired:  acquired.(int64),
			Temporary: temporary.(int64),
		}
	}

	return levels
}

func TestStartingInnateMutationsAreSavedRecords(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_BARACHI",
		"JOB_FIRE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	before := playerMutationRecords(t, g)

	for _, id := range []string{
		"MUT_DAYSTALKER",
		"MUT_HOP",
		"MUT_SLOW",
	} {
		if before[id] != (testMutationLevels{Innate: 1}) {
			t.Fatalf("starting %s mutation = %+v", id, before[id])
		}
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if after := playerMutationRecords(t, loaded); !reflect.DeepEqual(before, after) {
		t.Fatalf("mutation records changed on restore: before=%v after=%v",
			before,
			after)
	}
}
