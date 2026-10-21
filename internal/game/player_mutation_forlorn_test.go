package game

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestForlornCannotRestoreWithReligion(t *testing.T) {
	g, err := NewDungeonGame(
		59,
		"SP_DEMIGOD",
		"JOB_FIGHTER",
		"WPN_RAPIER",
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

			if record.Schema == "religion.worship" {
				record.Values["god_id"] = json.RawMessage(`"GOD_TROG"`)
				changed = true
			}
		}
	}

	if !changed {
		t.Fatal("Demigod snapshot has no worship state")
	}

	restored, restoreErr := Restore(snapshot)

	if restored != nil {
		restored.Close()
	}

	if restoreErr == nil ||
		!strings.Contains(restoreErr.Error(), "Forlorn") {
		t.Fatalf("restored impossible Forlorn religion: %v", restoreErr)
	}
}
