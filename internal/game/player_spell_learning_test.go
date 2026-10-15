package game

import "testing"

func TestHumanFireElementalistStartsWithTwoFreeSpellLevels(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_FIRE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	result, err := g.scripts.Policy("magic.spell_levels", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["total"] != int64(3) ||
		result["available"] != int64(2) {
		t.Fatalf("starting spell levels = %v, want total 3 available 2", result)
	}
}

func TestHedgeWizardBeginsMemorisingLibrarySpell(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_HEDGE_WIZARD",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	result, err := g.scripts.Policy(
		"magic.begin_learning",
		map[string]any{"spell_id": "SPELL_SLOW"},
	)

	if err != nil {
		t.Fatal(err)
	}

	if result["started"] != true {
		t.Fatalf("memorisation did not begin: %v", result)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	state, found := g.scripts.Components()["character.spellcasting"].Get(g.player)

	if !found {
		t.Fatal("player lacks spellcasting state")
	}

	spellID, _ := state.Get("learning_spell_id")
	remaining, _ := state.Get("learning_remaining")

	if spellID != "SPELL_SLOW" || remaining != int64(1) {
		t.Fatalf("memorisation state = %v, %v", spellID, remaining)
	}
}

func TestMemorisationCommandPreparesOnlyLibrarySpell(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_HEDGE_WIZARD",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	valid, err := g.scripts.Policy("command.prepare", map[string]any{
		"kind":     18,
		"spell_id": "SPELL_SLOW",
	})

	if err != nil {
		t.Fatal(err)
	}

	intent, found := valid["intent"].(map[string]any)

	if !found {
		t.Fatalf("valid memorisation intent is missing: %v", valid)
	}

	if intent["kind"] != int64(14) ||
		intent["spell_id"] != "SPELL_SLOW" {
		t.Fatalf("valid memorisation intent = %v", valid)
	}

	invalid, err := g.scripts.Policy("command.prepare", map[string]any{
		"kind":     18,
		"spell_id": "SPELL_GLACIATE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if invalid["intent"] != nil || invalid["message"] == nil {
		t.Fatalf("invalid spell spent a turn: %v", invalid)
	}
}

func TestMemorisationTakesTurnsBeforeSpellIsKnown(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_HEDGE_WIZARD",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	started, err := g.Step(Command{
		Kind:    CommandMemorise,
		SpellID: "SPELL_SLOW",
	})

	if err != nil {
		t.Fatal(err)
	}

	if started.Spent != 10 ||
		playerSpellRecords(t, g)["SPELL_SLOW"].KnownSlot != 0 {
		t.Fatalf("memorisation completed too early after %d aut", started.Spent)
	}

	completed, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if completed.Spent != 10 ||
		playerSpellRecords(t, g)["SPELL_SLOW"].KnownSlot == 0 {
		t.Fatalf("memorisation did not complete after %d aut", completed.Spent)
	}
}

func TestMemorisationContinuesAfterRestore(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_HEDGE_WIZARD",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.Step(Command{
		Kind:    CommandMemorise,
		SpellID: "SPELL_SLOW",
	})

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if playerSpellRecords(t, loaded)["SPELL_SLOW"].KnownSlot != 0 {
		t.Fatal("restored memorisation completed before its remaining turn")
	}

	_, err = loaded.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if playerSpellRecords(t, loaded)["SPELL_SLOW"].KnownSlot == 0 {
		t.Fatal("restored memorisation did not finish")
	}
}

func TestCancelledMemorisationKeepsSpellUnknownWithoutTime(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_HEDGE_WIZARD",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.Step(Command{
		Kind:    CommandMemorise,
		SpellID: "SPELL_SLOW",
	})

	if err != nil {
		t.Fatal(err)
	}

	before := g.currentAut
	cancelled, err := g.Step(Command{Kind: CommandCancelMemorise})

	if err != nil {
		t.Fatal(err)
	}

	if cancelled.Spent != 0 || g.currentAut != before {
		t.Fatalf("cancellation spent %d aut", cancelled.Spent)
	}

	if playerSpellRecords(t, g)["SPELL_SLOW"].KnownSlot != 0 {
		t.Fatal("cancelled spell became known")
	}

	state, found := g.scripts.Components()["character.spellcasting"].Get(g.player)

	if !found {
		t.Fatal("player lacks spellcasting state")
	}

	remaining, _ := state.Get("learning_remaining")

	if remaining != int64(0) {
		t.Fatalf("cancelled memorisation has %v turns remaining", remaining)
	}
}

func TestDjinniLearnsScheduledSpellAtLevelThree(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_DJINNI",
		"JOB_FIRE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	futureID := ""

	for id, state := range playerSpellRecords(t, g) {
		if state.FutureLevel == 3 {
			futureID = id
		}
	}

	if futureID == "" {
		t.Fatal("Djinni has no scheduled XL3 spell")
	}

	progress, found := g.stores.Progression.Get(g.player)

	if !found {
		t.Fatal("Djinni has no progression state")
	}

	progress.TotalXP = 100
	_, err = g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if progress.PendingStatLevel == 3 {
		_, err = g.ChooseStat("dex")

		if err != nil {
			t.Fatal(err)
		}
	}

	if progress.Level < 3 {
		t.Fatalf("Djinni reached only XL%d", progress.Level)
	}

	if playerSpellRecords(t, g)[futureID].KnownSlot == 0 {
		t.Fatalf("Djinni did not learn scheduled XL3 spell %s", futureID)
	}
}

func TestForgettingSpellFreesLevelsButKeepsLibraryEntry(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_HEDGE_WIZARD",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	before, err := g.scripts.Policy("magic.spell_levels", nil)

	if err != nil {
		t.Fatal(err)
	}

	forgotten, err := g.scripts.Policy(
		"magic.forget",
		map[string]any{"spell_id": "SPELL_MAGIC_DART"},
	)

	if err != nil {
		t.Fatal(err)
	}

	if forgotten["forgotten"] != true {
		t.Fatalf("known spell was not forgotten: %v", forgotten)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	state := playerSpellRecords(t, g)["SPELL_MAGIC_DART"]

	if !state.InLibrary ||
		state.KnownSlot != 0 ||
		state.LetterSlot != 0 {
		t.Fatalf("forgotten spell record = %+v", state)
	}

	after, err := g.scripts.Policy("magic.spell_levels", nil)

	if err != nil {
		t.Fatal(err)
	}

	if after["available"].(int64) != before["available"].(int64)+1 {
		t.Fatalf("free spell levels changed from %v to %v", before, after)
	}
}
