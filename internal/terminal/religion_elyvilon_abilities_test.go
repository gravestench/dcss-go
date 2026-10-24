package terminal

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/game"
)

// The terminal obtains every Elyvilon row from the same Lua ability
// registry used by commands; no patron-specific key or Go menu is needed.
func TestElyvilonAbilityMenuShowsFourPowers(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(1, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()

	snapshot := g.Snapshot()
	for i := range snapshot.Entities {
		if snapshot.Entities[i].Player == nil {
			continue
		}
		for j := range snapshot.Entities[i].Dynamic {
			worship := &snapshot.Entities[i].Dynamic[j]
			if worship.Schema == "religion.worship" {
				worship.Values["god_id"] =
					json.RawMessage(`"GOD_ELYVILON"`)
				worship.Values["piety"] = json.RawMessage(`200`)
			}
		}
	}

	restored, err := game.Restore(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()

	m.game = restored
	m.screen = ScreenPlay
	m.handleKey("a")
	view := plainApp(m)

	for _, name := range []string{
		"Purification",
		"Heal Other",
		"Heal Self",
		"Divine Vigour",
	} {
		if !strings.Contains(view, name) {
			t.Fatalf("Elyvilon menu lacks %q:\n%s", name, view)
		}
	}
}
