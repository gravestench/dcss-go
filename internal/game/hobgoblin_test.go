package game

import (
	"reflect"
	"testing"
)

func TestGeneratedDungeonIncludesSourceHobgoblinsAndSaves(t *testing.T) {
	var encountered *Game

	for seed := uint64(1); seed <= 3; seed++ {
		g := newGeneratedTestGame(t, seed)

		for _, entity := range g.stores.AI.Entities() {
			actor, _ := g.stores.Actors.Get(entity)

			if actor.KindID == "MONS_HOBGOBLIN" {
				encountered = g
				break
			}
		}

		if encountered != nil {
			break
		}
	}

	if encountered == nil {
		t.Fatal("hobgoblin never appeared in generated D:1-2")
	}

	before := encountered.Snapshot()
	loaded, err := Restore(before, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("hobgoblin state changed across save and restore")
	}
}
