package presentationimport

import (
	"slices"
	"strings"
	"testing"
)

func TestParseGroupsPreservesSourceOrder(t *testing.T) {
	source := `static species_group species_groups[] = {
    { "Simple", coord_def(0, 0), 50, { SP_HUMAN, SP_MINOTAUR } },
    { "Advanced", coord_def(2, 0), 20, { SP_FELID } },
};`
	groups, err := parseGroups("species-groups.h", []byte(source), "species_groups", "SP_")
	if err != nil {
		t.Fatal(err)
	}
	if len(groups) != 2 || groups[0].Label != "Simple" || !slices.Equal(groups[0].IDs, []string{"SP_HUMAN", "SP_MINOTAUR"}) || groups[1].Label != "Advanced" || !slices.Equal(groups[1].IDs, []string{"SP_FELID"}) {
		t.Fatalf("group order changed: %+v", groups)
	}
}

func TestParseDescriptionsKeepsParagraphs(t *testing.T) {
	source := "%%%%\nHuman\n\nFirst line.\nSecond line.\n\nNext paragraph.\n%%%%\nFelid\n\nCat.\n"
	descriptions, err := parseDescriptions("species.txt", []byte(source))
	if err != nil {
		t.Fatal(err)
	}
	if descriptions["Human"] != "First line.\nSecond line.\n\nNext paragraph." || descriptions["Felid"] != "Cat." {
		t.Fatalf("description prose changed: %+v", descriptions)
	}
}

func TestParseDescriptionsRejectsDuplicate(t *testing.T) {
	_, err := parseDescriptions("species.txt", []byte("%%%%\nHuman\n\nOne.\n%%%%\nHuman\n\nTwo.\n"))
	if err == nil || !strings.Contains(err.Error(), "Human") {
		t.Fatalf("duplicate accepted: %v", err)
	}
}
