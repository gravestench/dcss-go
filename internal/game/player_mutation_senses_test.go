package game

import "testing"

func monsterInView(view View, role string) (EntityView, bool) {
	for _, entity := range view.Entities {
		if entity.Role == role {
			return entity, true
		}
	}

	return EntityView{}, false
}

func TestInvisibleMonsterSensingAndSave(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if _, err := g.scripts.Components()["magic.monster_enchant"].Set(
		rat,
		map[string]any{
			"invisible_aut": int64(30),
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, found := monsterInView(g.View(), "monster"); found {
		t.Fatal("ordinary sight revealed an invisible monster")
	}

	addPlayerMutation(t, g, "MUT_ANTENNAE")

	if _, found := monsterInView(g.View(), "disturbance"); found {
		t.Fatal("antennae detected a monster beyond two cells")
	}

	if err := g.levels[1].MoveActor(rat, 3, 3); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MapCell(3, 3); err != nil {
		t.Fatal(err)
	}

	if _, found := monsterInView(g.View(), "disturbance"); !found {
		t.Fatal("antennae missed a monster behind a remembered wall")
	}

	if err := g.levels[1].MoveActor(rat, 3, 1); err != nil {
		t.Fatal(err)
	}

	disturbance, found := monsterInView(g.View(), "disturbance")

	if !found ||
		disturbance.Glyph != '{' ||
		disturbance.ID != 0 ||
		disturbance.KindID != "" {
		t.Fatalf("antennae leaked identity or missed marker: %+v", disturbance)
	}

	addPlayerMutation(t, g, "MUT_ACUTE_VISION")

	seen, found := monsterInView(g.View(), "monster")

	if !found ||
		seen.ID != uint64(rat) ||
		seen.KindID != "MONS_RAT" {
		t.Fatalf("acute vision did not reveal monster: %+v", seen)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if _, found := monsterInView(restored.View(), "monster"); !found {
		t.Fatal("save/restore lost mutation-based invisible sight")
	}
}
