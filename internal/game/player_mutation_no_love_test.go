package game

import "testing"

func TestNoLoveTurnsExistingSummonHostileAndRestores(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_SUMMONER",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	cast, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUMMON_SMALL_MAMMAL",
	})

	if err != nil {
		t.Fatal(err)
	}

	if cast.Spent == 0 {
		t.Fatal("Small Mammal did not summon before No Love")
	}

	store := g.scripts.Components()["magic.summon"]
	summoned := store.Entities()

	if len(summoned) != 1 {
		t.Fatalf("got %d existing summons, want one", len(summoned))
	}

	ally := summoned[0]
	before, found := store.Get(ally)

	if !found {
		t.Fatal("summon lost its allegiance state")
	}

	hostile, err := before.Get("hostile")

	if err != nil {
		t.Fatal(err)
	}

	if hostile != false {
		t.Fatalf("ordinary summon started hostile: %v", hostile)
	}

	addSkillSacrificeForTest(t, g, "MUT_NO_LOVE")

	// The source clears sacrificed skill points and training when the
	// mutation is acquired. This fixture inserts the record directly.
	skills, _ := g.stores.Skills.Get(g.player)
	training, _ := g.stores.SkillTraining.Get(g.player)

	for index := range skills.Entries {
		if skills.Entries[index].ID == "SK_SUMMONINGS" {
			skills.Entries[index].Level = 0
			skills.Entries[index].Points = 0
		}
	}

	for index := range training.Settings {
		if training.Settings[index].ID == "SK_SUMMONINGS" {
			training.Settings[index].Enabled = false
			training.Settings[index].Focused = false
		}
	}

	refused, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUMMON_SMALL_MAMMAL",
	})

	if err != nil {
		t.Fatal(err)
	}

	if refused.Spent != 0 {
		t.Fatalf("No Love summon refusal spent %d aut", refused.Spent)
	}

	stillAllied, _ := store.Get(ally)
	hostile, _ = stillAllied.Get("hostile")

	if hostile != false {
		t.Fatal("existing ally changed before its next monster action")
	}

	g.turn.Actor = ally
	updateLuaSystem(t, g, "monster.decision", 10)

	changed, _ := store.Get(ally)
	hostile, err = changed.Get("hostile")

	if err != nil {
		t.Fatal(err)
	}

	if hostile != true {
		t.Fatal("No Love did not turn the acting summon hostile")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	saved, found := restored.scripts.Components()["magic.summon"].Get(ally)

	if !found {
		t.Fatal("hostile summon was lost on restore")
	}

	hostile, err = saved.Get("hostile")

	if err != nil {
		t.Fatal(err)
	}

	if hostile != true {
		t.Fatal("hostile allegiance was lost on restore")
	}
}
