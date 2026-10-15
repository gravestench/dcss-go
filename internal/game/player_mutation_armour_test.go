package game

import "testing"

func TestToughSkinMutationRaisesDisplayedArmourClass(t *testing.T) {
	g := newStepGame(t)
	before := g.View().PlayerAC
	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.mutation"]

	if _, err := store.Set(entity, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_TOUGH_SKIN",
		"acquired":    int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	if got := g.View().PlayerAC; got != before+1 {
		t.Fatalf("Tough Skin AC = %d, want %d", got, before+1)
	}
}

func TestDistortionFieldMutationRaisesDisplayedEvasion(t *testing.T) {
	g := newStepGame(t)
	before := g.View().PlayerEV
	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.mutation"]

	if _, err := store.Set(entity, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_DISTORTION_FIELD",
		"acquired":    int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	if got := g.View().PlayerEV; got != before+2 {
		t.Fatalf("Distortion Field EV = %d, want %d", got, before+2)
	}
}

func TestBonePlatesAddSourceShieldValues(t *testing.T) {
	for _, vector := range []struct {
		level int64
		bonus int
	}{
		{
			level: 1,
			bonus: 4,
		},

		{
			level: 2,
			bonus: 6,
		},

		{
			level: 3,
			bonus: 8,
		},
	} {
		g := newStepGame(t)
		before := g.View().PlayerSH
		entity, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		if _, err := g.scripts.Components()["character.mutation"].Set(
			entity,
			map[string]any{
				"owner":       g.player,
				"mutation_id": "MUT_LARGE_BONE_PLATES",
				"acquired":    vector.level,
			},
		); err != nil {
			t.Fatal(err)
		}

		if got := g.View().PlayerSH; got != before+vector.bonus {
			t.Fatalf("bone plates level %d SH = %d, want %d",
				vector.level, got, before+vector.bonus)
		}
	}
}

func TestSturdyFrameReducesBodyArmourEvasionPenalty(t *testing.T) {
	g := newStepGame(t)
	before := g.View().PlayerEV
	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.mutation"].Set(
		entity,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_STURDY_FRAME",
			"acquired":    int64(1),
		},
	); err != nil {
		t.Fatal(err)
	}

	if got := g.View().PlayerEV; got <= before {
		t.Fatalf("Sturdy Frame EV = %d, want more than %d", got, before)
	}
}

func TestBonePlatesShieldWithoutEquippedShield(t *testing.T) {
	g := newStepGame(t)

	for _, item := range g.stores.Equipped.Entities() {
		equipped, found := g.stores.Equipped.Get(item)

		if found && equipped.Slot == "shield" {
			g.stores.Equipped.Remove(item)
		}
	}

	if got := g.View().PlayerSH; got != 0 {
		t.Fatalf("player without shield has SH %d", got)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.mutation"].Set(
		entity,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_LARGE_BONE_PLATES",
			"acquired":    int64(1),
		},
	); err != nil {
		t.Fatal(err)
	}

	if got := g.View().PlayerSH; got != 4 {
		t.Fatalf("bone plates without a shield show SH %d, want 4", got)
	}
}

func TestDeformedAndPseudopodsReduceBodyArmourACOnce(t *testing.T) {
	g := newStepGame(t)
	before := g.View().PlayerAC
	store := g.scripts.Components()["character.mutation"]

	for _, mutationID := range []string{
		"MUT_DEFORMED",
		"MUT_PSEUDOPODS",
	} {
		entity, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		if _, err := store.Set(entity, map[string]any{
			"owner":       g.player,
			"mutation_id": mutationID,
			"acquired":    int64(1),
		}); err != nil {
			t.Fatal(err)
		}

		if got := g.View().PlayerAC; got != before-3 {
			t.Fatalf("body armour mutation %s AC = %d, want %d",
				mutationID, got, before-3)
		}
	}
}
