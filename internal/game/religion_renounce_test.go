package game

import "testing"

// The source ability asks twice before time, piety, or the former god can
// change. The final accepted action uses the same leave path as conversion.
func TestRenounceReligionRequiresTwoConfirmations(t *testing.T) {
	g, err := NewDungeonGame(
		621,
		"SP_HUMAN",
		"JOB_BERSERKER",
		"WPN_HAND_AXE",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	before := g.View().CurrentAut
	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_RENOUNCE_RELIGION",
	}

	first, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if first.Confirmation == "" ||
		first.Spent != 0 ||
		worshipGod(t, g) != "GOD_TROG" {
		t.Fatalf("first renounce prompt: spent=%d prompt=%q events=%+v",
			first.Spent, first.Confirmation, first.Events)
	}

	command.Forced = true
	command.TargetID = first.ConfirmationTarget

	second, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if second.Confirmation == "" ||
		second.Spent != 0 ||
		second.ConfirmationTarget == first.ConfirmationTarget ||
		worshipGod(t, g) != "GOD_TROG" {
		t.Fatalf("second renounce prompt: spent=%d prompt=%q target=%q",
			second.Spent, second.Confirmation, second.ConfirmationTarget)
	}

	command.TargetID = second.ConfirmationTarget

	accepted, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if accepted.Spent == 0 ||
		worshipGod(t, g) != "GOD_NO_GOD" ||
		g.View().CurrentAut <= before {
		t.Fatalf("accepted renunciation: spent=%d events=%+v god=%s",
			accepted.Spent, accepted.Events, worshipGod(t, g))
	}

	if g.View().GodName != "" {
		t.Fatal("renounced god remained in player view")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if worshipGod(t, restored) != "GOD_NO_GOD" ||
		restored.View().GodName != "" {
		t.Fatal("restored renunciation brought back the old god")
	}
}
