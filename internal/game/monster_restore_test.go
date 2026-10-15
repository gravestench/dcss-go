package game

import (
	"reflect"
	"testing"
)

func TestRestoreRejectsRemovedAndEnumOnlyMonsters(t *testing.T) {
	for _, id := range []string{"MONS_BUMBLEBEE", "MONS_BEAR"} {
		t.Run(id, func(t *testing.T) {
			g, err := NewScenario(42, "WPN_RAPIER", "Hero")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()
			before := g.Snapshot()
			bad := g.Snapshot()
			changed := false

			for i := range bad.Entities {
				if bad.Entities[i].AI != nil {
					bad.Entities[i].Actor.KindID = id
					changed = true
					break
				}
			}

			if !changed {
				t.Fatal("no monster in scenario")
			}

			if replacement, err := g.Restore(bad); err == nil {
				replacement.Close()
				t.Fatal("placeholder restored as live monster")
			}

			if !reflect.DeepEqual(g.Snapshot(), before) {
				t.Fatal("failed restore changed live game")
			}
		})
	}
}
