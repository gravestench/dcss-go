package character

import (
	"testing"

	"dcrawl-go/internal/content"
)

func TestBaseStatSum(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	got, err := BaseStatSum(catalog, "SP_HUMAN", "JOB_FIGHTER")

	if err != nil ||
		got != (Attributes{
			Strength:     16,
			Intelligence: 8,
			Dexterity:    12,
		}) {
		t.Fatalf("Human/Fighter base attributes = %+v, %v", got, err)
	}

	for _, pair := range [][2]string{
		{"SP_HUMAN", "JOB_WANDERER"},
		{"SP_FELID", "JOB_HUNTER"},
		{"SP_HUMAN", "JOB_HEALER"},
	} {
		if _, err := BaseStatSum(catalog, pair[0], pair[1]); err == nil {
			t.Fatalf("invalid fixed-stat pair %s/%s accepted", pair[0], pair[1])
		}
	}
}
