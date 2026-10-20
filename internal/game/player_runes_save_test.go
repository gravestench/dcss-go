package game

import (
	"reflect"
	"testing"
)

// A collected rune is player progress. It must survive after the floor
// item has gone, with no inventory entity required to reconstruct it.
func TestPlayerRuneProgressSurvivesSaveRestore(t *testing.T) {
	game := newStepGame(t)
	defer game.Close()

	runes := game.scripts.Components()["character.runes"]

	if _, err := runes.Set(game.player, map[string]any{
		"collected": map[string]any{
			"RUNE_CEREBOV": true,
		},
	}); err != nil {
		t.Fatal(err)
	}

	before := game.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("collected rune or other game state changed across restore")
	}
}
