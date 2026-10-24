package game

import (
	"testing"

	"crawl/internal/terrain"
)

// Give the fixed Fighter enough MP to exercise Jiyva's paid abilities.
// Production worship and magic schemas remain the source of truth.
func readyJiyvaPowers(t *testing.T, g *Game) {
	t.Helper()

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_JIYVA",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("player lacks a magic pool")
	}

	magic.Max = 20
	magic.Current = 20

	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}
}

// The live terminal menu reads the same Lua registry used by command
// preparation. Both powers must appear without a Go ability switch.
func assertJiyvaAbilityMenu(t *testing.T, g *Game) {
	t.Helper()

	result, err := g.PresentationPolicy("presentation.abilities",
		map[string]any{
			"height": 24,
		})

	if err != nil {
		t.Fatal(err)
	}

	options, ok := result["options"].([]any)

	if !ok {
		t.Fatalf("ability menu options: %T", result["options"])
	}

	seen := map[string]bool{}

	for _, value := range options {
		option, ok := value.(map[string]any)

		if !ok {
			t.Fatalf("ability option: %T", value)
		}

		id, ok := option["id"].(string)

		if ok {
			seen[id] = true
		}
	}

	for _, id := range []string{
		"ABIL_JIYVA_OOZEMANCY",
		"ABIL_JIYVA_SLIMIFY",
	} {
		if !seen[id] {
			t.Fatalf("Jiyva ability menu omitted %s", id)
		}
	}
}

// All candidate rock walls change through the shared temporary terrain
// owner, survive restore, then return to their original features.
func TestJiyvaOozemancyRestoresWalls(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	g.world.DestroyEntity(rat)

	unowned, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_JIYVA_OOZEMANCY",
	})

	if err != nil {
		t.Fatal(err)
	}

	if unowned.Spent != 0 {
		t.Fatalf("unowned Oozemancy: %+v, %v", unowned, err)
	}

	readyJiyvaPowers(t, g)
	assertJiyvaAbilityMenu(t, g)

	before := g.levels[1].Cells()
	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_JIYVA_OOZEMANCY",
	}

	result, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("Oozemancy spent %d aut", result.Spent)
	}

	changed := 0
	current := g.levels[1].Cells()

	for y, row := range before {
		for x, feature := range row {
			if feature != current[y][x] &&
				current[y][x] == terrain.SlimyWall {
				changed++
			}
		}
	}

	if changed == 0 {
		t.Fatal("Oozemancy did not transform visible walls")
	}

	again, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if again.Spent != 0 {
		t.Fatalf("repeated Oozemancy: %+v, %v", again, err)
	}

	magic, _ := g.stores.Magic.Get(g.player)

	if magic.Current >= 20 {
		t.Fatalf("Oozemancy did not spend MP: %d", magic.Current)
	}

	worship, _ := g.scripts.Components()["religion.worship"].Get(
		g.player)
	piety, err := worship.Get("piety")

	if err != nil {
		t.Fatal(err)
	}

	if piety.(int64) >= 200 {
		t.Fatalf("Oozemancy did not spend piety: %v, %v",
			piety, err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["religion.jiyva_powers"].Has(
		restored.player) {
		t.Fatal("restored Oozemancy lost its player timer")
	}

	_, err = restored.scripts.Components()["religion.worship"].Set(
		restored.player,
		map[string]any{
			"god_id": "GOD_TROG",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if restored.scripts.Components()["religion.jiyva_powers"].Has(
		restored.player) {
		t.Fatal("Oozemancy continued without Jiyva")
	}

	after := restored.levels[1].Cells()

	for y, row := range before {
		for x, feature := range row {
			if after[y][x] != feature {
				t.Fatalf("wall %d,%d restored as %s, want %s",
					x, y, after[y][x], feature)
			}
		}
	}
}

// A successful primary hit turns the live monster into a saved allied
// slime, consumes the charge, and skips normal melee damage.
func TestJiyvaSlimifyTransformsMeleeTarget(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	readyJiyvaPowers(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	energy, _ := g.stores.MonsterEnergy.Get(rat)

	energy.Points = -1000

	if _, err := g.stores.MonsterEnergy.Set(rat, *energy); err != nil {
		t.Fatal(err)
	}

	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_JIYVA_SLIMIFY",
	}

	result, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("Slimify spent %d aut", result.Spent)
	}

	for attempt := 0; attempt < 12 &&
		!g.scripts.Components()["religion.jiyva_slime"].Has(rat); attempt++ {
		position, found := g.stores.Positions.Get(rat)

		if !found {
			t.Fatal("target died before it could be slimified")
		}

		player, _ := g.stores.Positions.Get(g.player)
		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   position.X - player.X,
			DY:   position.Y - player.Y,
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent <= 0 {
			t.Fatalf("melee spent %d aut", result.Spent)
		}
	}

	if !g.scripts.Components()["religion.jiyva_slime"].Has(rat) {
		t.Fatal("Slimify never converted the melee target")
	}

	if g.scripts.Components()["religion.jiyva_powers"].Has(
		g.player) {
		t.Fatal("Slimify retained its on-hit charge")
	}

	allegiance, _ := g.scripts.Components()["religion.jiyva_slime"].Get(rat)
	attitude, err := allegiance.Get("attitude")

	if err != nil {
		t.Fatal(err)
	}

	if attitude != "good_neutral" {
		t.Fatalf("slimified target attitude: %v, %v", attitude, err)
	}

	body, found := g.stores.Actors.Get(rat)

	if !found || body.KindID == "MONS_RAT" {
		t.Fatalf("Slimify kept old body: %+v", body)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["religion.jiyva_slime"].Has(rat) {
		t.Fatal("restored run lost slimified allegiance")
	}
}
