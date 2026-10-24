package game

import (
	"testing"

	"crawl/internal/terrain"
)

// The scenario Fighter normally has little MP. Supplying a test pool
// lets the command exercise source price and target rules directly.
func readyFedhasWorshipper(t *testing.T, g *Game) {
	t.Helper()

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_FEDHAS",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	refillFedhasMagic(t, g)
}

// Derived level-one MP returns after each timed action. Refill only the
// fixture's pool before another paid ability; gameplay still spends it.
func refillFedhasMagic(t *testing.T, g *Game) {
	t.Helper()

	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("Fedhas player has no magic pool")
	}

	magic.Max = 40
	magic.Current = 40

	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}
}

// Rejecting a distant target is free, while the valid wall creates a
// saved god-sourced actor. The following low-MP rejection is also free.
func useFedhasBriars(t *testing.T, g *Game) {
	t.Helper()

	invalid, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_FEDHAS_GROW_BALLISTOMYCETE",
		DX:        3,
	})

	if err != nil {
		t.Fatal(err)
	}

	if invalid.Spent != 0 {
		t.Fatalf("distant Fedhas aim spent %d aut", invalid.Spent)
	}

	briar, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_FEDHAS_WALL_OF_BRIARS",
	})

	if err != nil {
		t.Fatal(err)
	}

	if briar.Spent != 10 {
		t.Fatalf("Wall of Briars spent %d aut", briar.Spent)
	}

	plantFound := false
	store := g.scripts.Components()["magic.summon"]

	for _, entity := range store.Entities() {
		state, exists := store.Get(entity)

		if !exists {
			continue
		}

		source, getErr := state.Get("source_id")

		if getErr != nil {
			t.Fatal(getErr)
		}

		if source == "GOD_FEDHAS" {
			plantFound = true
		}
	}

	if !plantFound {
		t.Fatal("Wall of Briars created no saved Fedhas plant")
	}

	lowMagic, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_FEDHAS_OVERGROW",
		DX:        1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if lowMagic.Spent != 0 {
		t.Fatalf("low-MP Overgrow spent %d aut", lowMagic.Spent)
	}
}

// Failure spends a turn but leaves the wall intact. Refill and retry
// until one invocation changes terrain, preserving real failure odds.
func useFedhasOvergrow(t *testing.T, g *Game, level *Level,
	x, y int,
) {
	t.Helper()

	for attempt := 0; attempt < 20; attempt++ {
		refillFedhasMagic(t, g)

		result, err := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_FEDHAS_OVERGROW",
			DX:        1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent != 10 {
			t.Fatalf("Overgrow spent %d aut", result.Spent)
		}

		if level.Cells()[y][x] == terrain.Floor {
			return
		}
	}

	t.Fatal("Overgrow never changed its aimed wall")
}

// The restored floor and plant must agree about position, owner, god,
// side, and finite lifetime. Another plant elsewhere cannot satisfy this.
func assertFedhasOvergrowRestore(t *testing.T, g *Game,
	levelID, x, y int,
) {
	t.Helper()

	if got := g.levels[levelID].Cells()[y][x]; got != terrain.Floor {
		t.Fatalf("restored Overgrow floor is %s", got)
	}

	plant, occupied := g.levels[levelID].ActorAt(x, y)

	if !occupied {
		t.Fatal("restored Overgrow floor lost its plant")
	}

	state, saved := g.scripts.Components()["magic.summon"].Get(plant)

	if !saved {
		t.Fatal("restored Overgrow plant lost its summon record")
	}

	owner, _ := state.Get("owner")
	source, _ := state.Get("source_id")
	attitude, _ := state.Get("attitude")
	expiry, _ := state.Get("expires_aut")

	if owner != g.player ||
		source != "GOD_FEDHAS" ||
		attitude != "friendly" ||
		expiry.(int64) <= int64(g.currentAut) {
		t.Fatalf("invalid restored Overgrow plant: owner=%v source=%v attitude=%v expiry=%v",
			owner, source, attitude, expiry)
	}
}

// The game command uses Lua's ability registry and saves both ECS plants
// and the permanent floor edit made by the selected Overgrow cluster.
func TestFedhasActivePowersSurviveRestore(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	g.world.DestroyEntity(rat)
	readyFedhasWorshipper(t, g)

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("Fedhas player has no map position")
	}

	level := g.levels[position.LevelID]
	x := position.X + 1
	y := position.Y

	if err := level.SetCell(x, y, terrain.RockWall); err != nil {
		t.Fatal(err)
	}

	useFedhasBriars(t, g)
	useFedhasOvergrow(t, g, level, x, y)

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	assertFedhasOvergrowRestore(t, restored, position.LevelID, x, y)
}
