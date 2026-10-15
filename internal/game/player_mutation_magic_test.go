package game

import "testing"

func TestAcquiredWildMagicChangesSpellPower(t *testing.T) {
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

	spell := map[string]any{"spell_id": "SPELL_MAGIC_DART"}
	before, err := g.scripts.Policy("magic.spell_power", spell)

	if err != nil {
		t.Fatal(err)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.mutation"]

	if _, err := store.Set(entity, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_WILD_MAGIC",
		"acquired":    int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	after, err := g.scripts.Policy("magic.spell_power", spell)

	if err != nil {
		t.Fatal(err)
	}

	if after["cast_power"].(int64) <= before["cast_power"].(int64) {
		t.Fatalf("acquired Wild Magic did not raise spell power: %v to %v",
			before,
			after)
	}
}

func TestAcquiredStrengthMutationProjectsIntoHudAndSave(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_FLAIL",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	before := g.View().Attributes
	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.mutation"]

	if _, err := store.Set(entity, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_STRONG",
		"acquired":    int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	after := g.View().Attributes

	if after.Strength != before.Strength+4 ||
		after.Intelligence != before.Intelligence-1 ||
		after.Dexterity != before.Dexterity-1 {
		t.Fatalf("Strong did not affect the HUD: before=%+v after=%+v",
			before, after)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if restored := loaded.View().Attributes; restored != after {
		t.Fatalf("mutation stats changed on restore: before=%+v after=%+v",
			after, restored)
	}
}
