package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func TestReservedItemSaveRoundTrip(t *testing.T) {
	game := newStepGame(t)
	owner, err := game.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Items.Set(owner, ecs.Item{
		KindID:   "SCR_ACQUIREMENT",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.CarriedBy.Set(owner, ecs.CarriedBy{
		Holder: game.player,
	}); err != nil {
		t.Fatal(err)
	}

	offered, err := game.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Items.Set(offered, ecs.Item{
		KindID:   "WPN_CLUB",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.ReservedBy.Set(offered, ecs.ReservedBy{
		Owner: owner,
	}); err != nil {
		t.Fatal(err)
	}

	menu := game.scripts.Components()["scroll.acquirement_offers"]

	if _, err := menu.Set(owner, map[string]any{
		"offer_ids": []any{offered},
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := game.Snapshot()
	record := reservedRecord(snapshot, uint64(offered))

	if record == nil ||
		record.ReservedBy == nil ||
		record.ReservedBy.Owner != owner ||
		record.Position != nil ||
		record.CarriedBy != nil {
		t.Fatalf("reserved item snapshot = %+v", record)
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("reservation changed during restore")
	}
}

func reservedRecord(snapshot save.Snapshot, id uint64) *save.EntityRecord {
	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID == id {
			return &snapshot.Entities[index]
		}
	}

	return nil
}

func TestReservedItemSaveRejectsBadLocations(t *testing.T) {
	for _, testcase := range []struct {
		name   string
		mutate func(*save.EntityRecord)
	}{
		{
			name: "zero owner",
			mutate: func(record *save.EntityRecord) {
				record.ReservedBy = &ecs.ReservedBy{}
			},
		},

		{
			name: "two locations",
			mutate: func(record *save.EntityRecord) {
				record.ReservedBy = &ecs.ReservedBy{
					Owner: 1,
				}
			},
		},

		{
			name: "dead owner",
			mutate: func(record *save.EntityRecord) {
				record.Position = nil
				record.ReservedBy = &ecs.ReservedBy{
					Owner: 999999,
				}
			},
		},

		{
			name: "self owner",
			mutate: func(record *save.EntityRecord) {
				record.Position = nil
				record.ReservedBy = &ecs.ReservedBy{
					Owner: 999999,
				}

				record.ID = 999999
			},
		},
	} {
		t.Run(testcase.name, func(t *testing.T) {
			game := newStepGame(t)
			snapshot := game.Snapshot()
			changed := false

			for index := range snapshot.Entities {
				if snapshot.Entities[index].Item != nil &&
					snapshot.Entities[index].Position != nil {
					testcase.mutate(&snapshot.Entities[index])
					changed = true
					break
				}
			}

			if !changed {
				t.Fatal("fixture has no floor item")
			}

			restored, err := Restore(snapshot)

			if err == nil {
				restored.Close()
				t.Fatal("invalid reservation accepted")
			}

			if !strings.Contains(err.Error(), "item") &&
				!strings.Contains(err.Error(), "reservation") {
				t.Fatalf("unexpected error: %v", err)
			}
		})
	}
}
