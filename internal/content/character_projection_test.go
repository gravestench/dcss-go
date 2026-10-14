package content

import "testing"

func TestCharacterProjectionRejectsEmptySelectableMenu(t *testing.T) {
	base, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	species := make([]SpeciesDef, 0, len(base.SpeciesIDs()))
	jobs := make([]JobDef, 0, len(base.JobIDs()))

	for _, id := range base.SpeciesIDs() {
		definition, err := base.Species(id)

		if err != nil {
			t.Fatal(err)
		}

		definition.Selectable = false
		species = append(species, definition)
	}

	for _, id := range base.JobIDs() {
		definition, err := base.Job(id)

		if err != nil {
			t.Fatal(err)
		}

		jobs = append(jobs, definition)
	}

	if _, err := base.WithCharacterDefinitions(species, jobs); err == nil {
		t.Fatal("catalog accepted an empty selectable species menu")
	}
}
