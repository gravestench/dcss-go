package game

import "testing"

func TestPlayerSpellCoverageHasNoMutationDependentGap(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_CONJURER",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	result, err := g.scripts.Policy("magic.effect_coverage", nil)

	if err != nil {
		t.Fatal(err)
	}

	switch missing := result["missing"].(type) {
	case []any:
		if len(missing) != 0 {
			t.Fatalf("player spell coverage gaps: %v", missing)
		}

	case map[string]any:
		if len(missing) != 0 {
			t.Fatalf("player spell coverage gaps: %v", missing)
		}

	default:
		t.Fatalf("coverage policy returned %T", result["missing"])
	}
}
