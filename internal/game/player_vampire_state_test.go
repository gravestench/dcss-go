package game

import "testing"

func newVampireGame(t *testing.T) *Game {
	t.Helper()

	g, err := NewDungeonGame(
		73,
		"SP_VAMPIRE",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	return g
}

func vampireState(t *testing.T, g *Game) (bool, int64) {
	t.Helper()

	state, found := g.scripts.Components()["character.vampire"].Get(g.player)

	if !found {
		t.Fatal("Vampire has no blood state")
	}

	alive, err := state.Get("alive")

	if err != nil {
		t.Fatal(err)
	}

	remaining, err := state.Get("ritual_remaining_aut")

	if err != nil {
		t.Fatal(err)
	}

	return alive.(bool), remaining.(int64)
}

func TestVampireStartsAliveAndStateSurvivesSave(t *testing.T) {
	g, err := NewDungeonGame(
		73,
		"SP_VAMPIRE",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	store := g.scripts.Components()["character.vampire"]

	if store == nil {
		t.Fatal("vampire state schema is missing")
	}

	state, found := store.Get(g.player)

	if !found {
		t.Fatal("Vampire has no blood state")
	}

	alive, err := state.Get("alive")

	if err != nil {
		t.Fatal(err)
	}

	if alive != true {
		t.Fatalf("starting Vampire blood state = %v", alive)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	loaded, found := restored.scripts.Components()["character.vampire"].Get(
		restored.player,
	)

	if !found {
		t.Fatal("restore lost Vampire blood state")
	}

	alive, err = loaded.Get("alive")

	if err != nil {
		t.Fatal(err)
	}

	if alive != true {
		t.Fatalf("restored Vampire blood state = %v", alive)
	}
}

func TestRestoreRejectsMissingVampireBloodState(t *testing.T) {
	g, err := NewDungeonGame(
		73,
		"SP_VAMPIRE",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	snapshot := g.Snapshot()
	removed := false

	for entityIndex := range snapshot.Entities {
		records := snapshot.Entities[entityIndex].Dynamic

		for componentIndex, record := range records {
			if record.Schema == "character.vampire" {
				snapshot.Entities[entityIndex].Dynamic = append(
					records[:componentIndex],
					records[componentIndex+1:]...,
				)
				removed = true

				break
			}
		}
	}

	if !removed {
		t.Fatal("Vampire snapshot has no blood state to remove")
	}

	restored, restoreErr := Restore(snapshot)

	if restored != nil {
		restored.Close()
	}

	if restoreErr == nil {
		t.Fatal("Vampire without blood state was restored")
	}
}

func TestVampireBloodRitualCompletesAcrossSave(t *testing.T) {
	g := newVampireGame(t)
	defer g.Close()
	removeFixtureRat(t, g)
	startingHealth, _ := g.stores.Health.Get(g.player)
	startingMax := startingHealth.Max

	started, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_EXSANGUINATE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if started.Spent == 0 {
		t.Fatal("Exsanguinate spent no time")
	}

	alive, remaining := vampireState(t, g)

	if !alive || remaining != 50 {
		t.Fatalf("started bloodletting = alive %t, %d aut", alive, remaining)
	}

	for range 4 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	alive, remaining = vampireState(t, restored)

	if !alive || remaining != 10 {
		t.Fatalf("saved bloodletting = alive %t, %d aut", alive, remaining)
	}

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	alive, remaining = vampireState(t, restored)

	if alive || remaining != 0 {
		t.Fatalf("completed bloodletting = alive %t, %d aut", alive, remaining)
	}

	bloodlessHealth, _ := restored.stores.Health.Get(restored.player)

	if bloodlessHealth.Max >= startingMax {
		t.Fatalf("bloodless max HP %d, living max HP %d",
			bloodlessHealth.Max, startingMax)
	}

	forbidden, err := restored.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_EXSANGUINATE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if forbidden.Spent != 0 {
		t.Fatal("bloodless Vampire started bloodletting again")
	}

	if _, err := restored.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_REVIVIFY",
	}); err != nil {
		t.Fatal(err)
	}

	for range 5 {
		if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	alive, remaining = vampireState(t, restored)

	if !alive || remaining != 0 {
		t.Fatalf("revived Vampire = alive %t, %d aut", alive, remaining)
	}

	frail := playerMutationRecords(t, restored)["MUT_FRAIL"]

	if frail.Temporary != 1 {
		t.Fatalf("Revivify temporary Frail = %d", frail.Temporary)
	}
}

func TestRevivifyFrailRespectsMutationResistance(t *testing.T) {
	g := newVampireGame(t)
	defer g.Close()
	removeFixtureRat(t, g)

	if _, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_EXSANGUINATE",
	}); err != nil {
		t.Fatal(err)
	}

	for range 5 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	resistance, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.mutation"].Set(
		resistance,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_MUTATION_RESISTANCE",
			"acquired":    int64(3),
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_REVIVIFY",
	}); err != nil {
		t.Fatal(err)
	}

	for range 5 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	alive, remaining := vampireState(t, g)

	if !alive || remaining != 0 {
		t.Fatalf("Revivify ended alive=%t, remaining=%d", alive, remaining)
	}

	if frail := playerMutationRecords(t, g)["MUT_FRAIL"]; frail.Temporary != 0 {
		t.Fatalf("mutation resistance did not prevent Frail: %+v", frail)
	}
}

func TestBloodlessVampireBatFormUsesMagicAndDrainsStats(t *testing.T) {
	g := newVampireGame(t)
	defer g.Close()
	removeFixtureRat(t, g)

	mutations := g.scripts.Components()["character.mutation"]
	upgraded := false

	for _, entity := range mutations.Entities() {
		record, found := mutations.Get(entity)

		if !found {
			continue
		}

		id, err := record.Get("mutation_id")

		if err != nil {
			t.Fatal(err)
		}

		if id == "MUT_VAMPIRISM" {
			_, err = mutations.Set(entity, map[string]any{
				"owner":       g.player,
				"mutation_id": "MUT_VAMPIRISM",
				"innate":      int64(2),
			})

			if err != nil {
				t.Fatal(err)
			}

			upgraded = true
			break
		}
	}

	if !upgraded {
		t.Fatal("Vampire starts without Vampirism")
	}

	_, err := g.scripts.Components()["character.vampire"].Set(
		g.player,
		map[string]any{
			"alive": false,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	magic, _ := g.stores.Magic.Get(g.player)

	magic.Max = 10
	magic.Current = 10

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_TRAN_BAT",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 || magic.Current != 8 {
		t.Fatalf("Bat Form spent %d aut and left %d MP", result.Spent, magic.Current)
	}

	form, found := g.scripts.Components()["magic.player_form"].Get(g.player)

	if !found {
		t.Fatal("Bat Form did not create a form")
	}

	id, err := form.Get("form_id")

	if err != nil {
		t.Fatal(err)
	}

	if id != "bat" {
		t.Fatalf("Bat Form ID = %v", id)
	}

	loss, found := g.scripts.Components()["character.stat_loss"].Get(g.player)

	if !found {
		t.Fatal("Bat Form did not drain attributes")
	}

	for _, field := range []string{
		"strength",
		"intelligence",
		"dexterity",
	} {
		amount, err := loss.Get(field)

		if err != nil {
			t.Fatal(err)
		}

		if amount != int64(2) {
			t.Fatalf("Bat Form %s loss = %v", field, amount)
		}
	}

	ended, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_END_TRANSFORMATION",
	})

	if err != nil {
		t.Fatal(err)
	}

	if ended.Spent == 0 ||
		g.scripts.Components()["magic.player_form"].Has(g.player) {
		t.Fatal("End Transformation did not restore Vampire form")
	}
}
