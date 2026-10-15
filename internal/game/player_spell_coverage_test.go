package game

import (
	"strings"
	"testing"
)

func TestPlayerSpellCoverageTracksMutationDependentGap(t *testing.T) {
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

	raw, found := result["missing"].([]any)

	if !found {
		t.Fatalf("coverage policy returned %T", result["missing"])
	}

	missing := make([]string, 0, len(raw))

	for _, item := range raw {
		id, ok := item.(string)

		if !ok {
			t.Fatalf("coverage contains %T", item)
		}

		missing = append(missing, id)
	}

	// Unravelling can malmutate the caster. It stays unavailable until
	// acquired player mutations are represented in saved ECS state.
	want := "SPELL_VIOLENT_UNRAVELLING"

	if len(missing) != 1 || missing[0] != want {
		t.Fatalf("player spell coverage gaps changed: %s",
			strings.Join(missing, "\n"))
	}
}
