package game

import "testing"

// A live vault callback can recolour a wall after generation. The tint must
// survive save/restore separately from the wall's terrain identity.
func TestLiveCellColourSurvivesRestore(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	if err := g.levels[1].SetCellColour(4, 4, "lightmagenta"); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	colour, found := restored.levels[1].CellColour(4, 4)

	if !found || colour != "lightmagenta" {
		t.Fatalf("restored cell colour = %q, found %v", colour, found)
	}
}
