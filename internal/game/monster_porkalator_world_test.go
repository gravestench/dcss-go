package game

import (
	"testing"

	"crawl/internal/ecs"
)

// Save validation must admit Kirke's extra hogs and their freed human bodies
// even though neither was drawn from the fixed scenario's monster roster.
// The Lua rule test exercises the actual band spawn and death transition.
func TestKirkeBandOriginAndFreedAttitudeRestore(t *testing.T) {
	g := newStepGame(t)
	hog := ratID(t, g)

	if _, err := g.stores.Actors.Set(hog, ecs.Actor{
		KindID: "MONS_HOG",
		Speed:  13,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(hog, ecs.Health{
		Current: 20,
		Max:     33,
	}); err != nil {
		t.Fatal(err)
	}

	band := g.scripts.Components()["world.kirke_band"]

	if _, err := band.Set(hog, map[string]any{
		"band_member": true,
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["world.kirke_band"].Has(hog) {
		t.Fatal("Kirke band origin was lost on restore")
	}

	if _, err := loaded.stores.Actors.Set(hog, ecs.Actor{
		KindID: "MONS_HUMAN",
		Speed:  10,
	}); err != nil {
		t.Fatal(err)
	}

	if !loaded.scripts.Components()["world.kirke_band"].Remove(hog) {
		t.Fatal("Kirke band origin could not be removed")
	}

	if _, err := loaded.scripts.Components()["world.kirke_freed"].Set(
		hog,
		map[string]any{
			"freed":            true,
			"kind_id":          "MONS_HUMAN",
			"original_kind_id": "MONS_HUMAN",
		},
	); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(loaded.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["world.kirke_freed"].Has(hog) {
		t.Fatal("Kirke's freed attitude was lost on restore")
	}

	// Later polymorph keeps the permanent good-neutral origin while the
	// actor body changes and its source class remains saved separately.
	if _, err := restored.stores.Actors.Set(hog, ecs.Actor{
		KindID: "MONS_ORC",
		Speed:  10,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.stores.Health.Set(hog, ecs.Health{
		Current: 5,
		Max:     7,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.scripts.Components()["magic.monster_polymorph"].Set(
		hog,
		map[string]any{
			"original_kind_id": "MONS_HUMAN",
		},
	); err != nil {
		t.Fatal(err)
	}

	changed, err := Restore(restored.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer changed.Close()

	if !changed.scripts.Components()["world.kirke_freed"].Has(hog) {
		t.Fatal("later polymorph lost Kirke's permanent freedom")
	}
}
