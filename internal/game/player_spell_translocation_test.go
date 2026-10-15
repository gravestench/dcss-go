package game

import (
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/terrain"
)

func grantTranslocationForTest(t *testing.T, g *Game, spellID string) {
	t.Helper()
	grantSummonForTest(t, g, spellID)
	skills, _ := g.stores.Skills.Get(g.player)

	for _, id := range []string{
		"SK_TRANSLOCATIONS",
		"SK_ICE_MAGIC",
	} {
		found := false

		for index := range skills.Entries {
			if skills.Entries[index].ID == id {
				skills.Entries[index].Level = 27
				found = true
			}
		}

		if !found {
			skills.Entries = append(skills.Entries, character.Skill{
				ID:    id,
				Level: 27,
			})
		}
	}
}

func castTranslocation(t *testing.T, g *Game, id string, dx, dy int) StepResult {
	t.Helper()
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: id,
		DX:      dx,
		DY:      dy,
	})

	if err != nil ||
		result.Spent == 0 {
		t.Fatalf("%s cast = %+v, %v", id, result.Events, err)
	}

	return result
}

func quietMonsters(g *Game) {
	for _, entity := range g.stores.MonsterEnergy.Entities() {
		energy, _ := g.stores.MonsterEnergy.Get(entity)

		energy.Points = 0
	}
}

func grantTranslocationForSavedFixture(t *testing.T, g *Game, spellID string) func() {
	t.Helper()
	reset := grantSummonForSavedFixture(t, g, spellID)
	skills, _ := g.stores.Skills.Get(g.player)

	for _, id := range []string{
		"SK_TRANSLOCATIONS",
		"SK_ICE_MAGIC",
	} {
		found := false

		for index := range skills.Entries {
			if skills.Entries[index].ID == id {
				skills.Entries[index].Level = 27
				found = true
			}
		}

		if !found {
			skills.Entries = append(skills.Entries, character.Skill{
				ID:    id,
				Level: 27,
			})
		}
	}

	return reset
}

func TestPasswallDelayAndNoTimeRejection(t *testing.T) {
	g := newStepGame(t)
	grantTranslocationForTest(t, g, "SPELL_PASSWALL")
	quietMonsters(g)
	bad, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_PASSWALL",
		DX:      1,
	})

	if err != nil ||
		bad.Spent != 0 {
		t.Fatalf("Passwall on open floor = %+v, %v", bad, err)
	}

	castTranslocation(t, g, "SPELL_PASSWALL", 1, 1)

	if !g.scripts.Components()["magic.passwall_delay"].Has(g.player) {
		t.Fatal("Passwall has no saved delay")
	}

	for step := 0; step < 4 &&
		g.scripts.Components()["magic.passwall_delay"].Has(g.player); step++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if g.scripts.Components()["magic.passwall_delay"].Has(g.player) {
		t.Fatal("Passwall delay never finished")
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.X != 3 || position.Y != 3 {
		t.Fatalf("Passwall destination = (%d,%d), want (3,3)", position.X, position.Y)
	}
}

func TestGolubriaPassageCreatesLinkedFloorEntrances(t *testing.T) {
	g := newStepGame(t)
	grantTranslocationForTest(t, g, "SPELL_GOLUBRIAS_PASSAGE")
	quietMonsters(g)
	castTranslocation(t, g, "SPELL_GOLUBRIAS_PASSAGE", 3, 0)
	markers := g.scripts.Components()["magic.golubria_passage"].Entities()

	if len(markers) != 2 {
		t.Fatalf("Golubria markers = %d, want 2", len(markers))
	}

	for _, marker := range markers {
		state, _ := g.scripts.Components()["magic.golubria_passage"].Get(marker)
		x, _ := state.Get("x")
		y, _ := state.Get("y")
		feature := g.levels[1].terrain[int(y.(int64))][int(x.(int64))]

		if feature != terrain.PassageOfGolubria {
			t.Fatalf("Golubria marker cell = %s", feature)
		}
	}
}

func TestDispersalAndDisjunctionMoveMonsters(t *testing.T) {
	for _, id := range []string{
		"SPELL_DISPERSAL",
		"SPELL_DISJUNCTION",
	} {
		t.Run(id, func(t *testing.T) {
			g := newStepGame(t)
			grantTranslocationForTest(t, g, id)
			quietMonsters(g)
			rat := ratID(t, g)

			if err := g.levels[1].MoveActor(rat, 2, 1); err != nil {
				t.Fatal(err)
			}

			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			castTranslocation(t, g, id, 0, 0)

			if id == "SPELL_DISJUNCTION" {
				state, ok := g.scripts.Components()["magic.player_status"].Get(g.player)

				if !ok {
					t.Fatal("Disjunction has no timed status")
				}

				remaining, _ := state.Get("disjunction_aut")

				if remaining.(int64) <= 0 {
					t.Fatal("Disjunction status expired immediately")
				}
			} else {
				position, _ := g.stores.Positions.Get(rat)

				if position.X == 2 && position.Y == 1 {
					t.Fatal("Dispersal did not move the nearby rat")
				}
			}
		})
	}
}

func TestGravitasPullsAndManifoldAssaultStrikes(t *testing.T) {
	for _, id := range []string{
		"SPELL_GRAVITAS",
		"SPELL_MANIFOLD_ASSAULT",
	} {
		t.Run(id, func(t *testing.T) {
			g := newStepGame(t)
			grantTranslocationForTest(t, g, id)
			quietMonsters(g)
			rat := ratID(t, g)

			if err := g.levels[1].MoveActor(rat, 4, 1); err != nil {
				t.Fatal(err)
			}

			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			before, _ := g.stores.Health.Get(rat)
			initialHP := before.Current

			if id == "SPELL_GRAVITAS" {
				castTranslocation(t, g, id, 2, 0)
				position, _ := g.stores.Positions.Get(rat)

				if position.X >= 4 {
					t.Fatalf("Gravitas left rat at x=%d", position.X)
				}
			} else {
				castTranslocation(t, g, id, 0, 0)
				after, _ := g.stores.Health.Get(rat)

				if after != nil && after.Current >= initialHP {
					t.Fatalf("Manifold Assault left rat at %d HP", after.Current)
				}
			}
		})
	}
}

func TestLedaAndFrozenRampartsOwnTimedEffects(t *testing.T) {
	for _, id := range []string{
		"SPELL_LEDAS_LIQUEFACTION",
		"SPELL_FROZEN_RAMPARTS",
	} {
		t.Run(id, func(t *testing.T) {
			g := newStepGame(t)
			grantTranslocationForTest(t, g, id)
			quietMonsters(g)
			castTranslocation(t, g, id, 0, 0)
			component := "magic.liquefaction"

			if id == "SPELL_FROZEN_RAMPARTS" {
				component = "magic.frozen_ramparts"

				if len(g.scripts.Components()["magic.frozen_wall"].Entities()) == 0 {
					t.Fatal("Frozen Ramparts created no icy wall markers")
				}

				state, _ := g.scripts.Components()[component].Get(g.player)
				remaining, _ := state.Get("remaining_aut")
				power, _ := state.Get("power")
				lower := int64(30) + power.(int64)
				upper := int64(80) + power.(int64)*3/2

				if remaining.(int64) < lower || remaining.(int64) > upper {
					t.Fatalf("Frozen Ramparts source aut = %d at power %d",
						remaining, power)
				}
			}

			if !g.scripts.Components()[component].Has(g.player) {
				t.Fatalf("%s has no timed component", id)
			}
		})
	}
}

func TestFrozenRampartsDamagesMonsterBesideIcyWall(t *testing.T) {
	g := newStepGame(t)
	grantTranslocationForTest(t, g, "SPELL_FROZEN_RAMPARTS")
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(rat, 1, 2); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)

	health.Max = 20
	health.Current = 20

	energy, _ := g.stores.MonsterEnergy.Get(rat)

	energy.Points = 80

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	castTranslocation(t, g, "SPELL_FROZEN_RAMPARTS", 0, 0)

	if health.Current >= 20 {
		t.Fatalf("icy wall caused no damage, rat HP = %d", health.Current)
	}
}

func TestPasswallDelaySurvivesRestoreAndCanCancel(t *testing.T) {
	g := newStepGame(t)
	reset := grantTranslocationForSavedFixture(t, g, "SPELL_PASSWALL")
	quietMonsters(g)
	castTranslocation(t, g, "SPELL_PASSWALL", 1, 1)
	reset()
	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["magic.passwall_delay"].Has(loaded.player) {
		t.Fatal("Passwall delay lost after restore")
	}

	cancelled, err := loaded.Step(Command{Kind: CommandCancelMemorise})

	if err != nil ||
		cancelled.Spent != 0 ||
		loaded.scripts.Components()["magic.passwall_delay"].Has(loaded.player) {
		t.Fatalf("Passwall cancel = %+v, %v", cancelled, err)
	}
}

func TestGolubriaPassageTriggersAfterRestore(t *testing.T) {
	g := newStepGame(t)
	reset := grantTranslocationForSavedFixture(t, g, "SPELL_GOLUBRIAS_PASSAGE")
	quietMonsters(g)
	castTranslocation(t, g, "SPELL_GOLUBRIAS_PASSAGE", 3, 0)
	reset()
	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	markers := loaded.scripts.Components()["magic.golubria_passage"].Entities()

	if len(markers) != 2 {
		t.Fatalf("restored Golubria markers = %d", len(markers))
	}

	state, _ := loaded.scripts.Components()["magic.golubria_passage"].Get(markers[0])
	xValue, _ := state.Get("x")
	yValue, _ := state.Get("y")
	x, y := int(xValue.(int64)), int(yValue.(int64))

	if err := loaded.levels[1].MoveActor(loaded.player, x, y); err != nil {
		t.Fatal(err)
	}

	if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	position, _ := loaded.stores.Positions.Get(loaded.player)

	if position.X == x && position.Y == y {
		t.Fatal("Golubria entrance did not transport player")
	}

	passages := loaded.scripts.Components()["magic.golubria_passage"].Entities()

	if len(passages) != 1 ||
		loaded.levels[1].terrain[y][x] != terrain.Floor {
		t.Fatal("Golubria did not consume entered passage")
	}
}

func TestLedaAddsMovementTimeAndEnds(t *testing.T) {
	g := newStepGame(t)
	grantTranslocationForTest(t, g, "SPELL_LEDAS_LIQUEFACTION")
	quietMonsters(g)
	castTranslocation(t, g, "SPELL_LEDAS_LIQUEFACTION", 0, 0)
	moved, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil ||
		moved.Spent != 13 {
		t.Fatalf("Leda movement = %d aut, %v", moved.Spent, err)
	}

	if !g.scripts.Components()["magic.liquefaction"].Has(g.player) {
		t.Fatal("Leda aura ended on movement")
	}
}
