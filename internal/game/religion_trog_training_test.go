package game

import "testing"

// Trog starts with magic training unavailable. The UI control path and the
// XP owner must agree even when Spellcasting is added later by a mod or item.
func TestTrogWorshipRejectsMagicTrainingControls(t *testing.T) {
	g, err := NewDungeonGame(
		641,
		"SP_HUMAN",
		"JOB_BERSERKER",
		"WPN_HAND_AXE",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if err := g.ChangeSkillTraining("SK_SPELLCASTING", true); err == nil {
		t.Fatal("Trog accepted manual Spellcasting training")
	}

	if err := g.ChangeSkillTraining("SK_FIGHTING", true); err != nil {
		t.Fatalf("Trog blocked mundane skill training: %v", err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if err := restored.ChangeSkillTraining("SK_SPELLCASTING", true); err == nil {
		t.Fatal("restored Trog worship lost the magic-training restriction")
	}
}
