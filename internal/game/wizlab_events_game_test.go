package game

import (
	"testing"

	"crawl/internal/terrain"
)

// Select a named source room through the same staged transaction and Lua
// commit callback as ordinary portal entry. The requested layout replaces
// only the random destination draw; the gate, population, and save path
// remain the production ones.
func enterNamedWizlab(t *testing.T, id string) *Game {
	t.Helper()

	g := newGeneratedTestGame(t, 88301)
	gate := placeWizlabPortalForTest(t, g)
	stage, err := g.stageGeneratedLevel(
		"world.generate_wizlab_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   id,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	portal := luaPortal{
		stage:        stage,
		operation:    "enter",
		commitPolicy: "world.wizlab.commit_travel",
		source:       gate,
		sourceID:     1,
		toLevelID:    stage.levelID,
		destination:  stage.entry,
	}

	if _, err := portal.commit(g); err != nil {
		if rollbackErr := stage.rollback(); rollbackErr != nil {
			t.Errorf("failed entry rollback: %v", rollbackErr)
		}

		t.Fatal(err)
	}

	// The real command advances this generic clock after the portal
	// commit. Mark the selected floor here because this helper called the
	// transaction directly in order to choose a named source room.
	if _, err := g.scripts.Policy("world.zot_clock", map[string]any{
		"branch_id":   "BRANCH_WIZLAB",
		"level_id":    stage.levelID,
		"elapsed_aut": int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	// An ordinary command completes the branch transition's remaining
	// world systems, including the current-floor Zot clock witness.
	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	return g
}

// Each source callback family must materialize one state owner that can
// survive save/restore with its exact selected room and gate address.
func TestWizlabEventFamiliesSaveAndRestore(t *testing.T) {
	cases := []struct {
		name   string
		schema string
	}{
		{
			name:   "wizlab_doroklohe",
			schema: "world.wizlab_doroklohe",
		},
		{
			name:   "wizlab_wucad",
			schema: "world.wizlab_wucad",
		},
		{
			name:   "wizlab_borgnjor",
			schema: "world.wizlab_borgnjor",
		},
		{
			name:   "wizlab_zonguldrok",
			schema: "world.wizlab_zonguldrok",
		},
	}

	for _, sample := range cases {
		t.Run(sample.name, func(t *testing.T) {
			g := enterNamedWizlab(t, sample.name)
			store := g.scripts.Components()[sample.schema]

			if store == nil || len(store.Entities()) != 1 {
				t.Fatalf("%s has no unique Akara event owner", sample.name)
			}

			restored, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatalf("%s cannot restore: %v", sample.name, err)
			}

			store = restored.scripts.Components()[sample.schema]

			if store == nil || len(store.Entities()) != 1 {
				t.Fatalf("%s event owner was lost on restore", sample.name)
			}
		})
	}
}

// Cigotuvi's authored mutant beast is a primal three-facet individual.
// Its source form must survive resolution to the shared monster catalog ID.
func TestWizlabCigotuviMutantBeastForm(t *testing.T) {
	g := enterNamedWizlab(t, "wizlab_cigotuvi")
	store := g.scripts.Components()["monster.mutant_beast"]

	if store == nil || len(store.Entities()) != 1 {
		t.Fatal("Cigotuvi's source beast lost its individual form")
	}

	state, found := store.Get(store.Entities()[0])

	if !found {
		t.Fatal("mutant beast has no saved Akara state")
	}

	tier, _ := state.Get("tier")
	hitDice, _ := state.Get("hit_dice")

	if tier != "primal" || hitDice != int64(27) {
		t.Fatalf("Cigotuvi beast form = %v, %v", tier, hitDice)
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("Cigotuvi beast cannot restore: %v", err)
	}
}

// Move one source countdown to the next player action while leaving the
// rest of its real populated state and marker group intact.
func forceWizlabEventDeadline(t *testing.T, g *Game, schema string) {
	t.Helper()

	store := g.scripts.Components()[schema]

	if store == nil || len(store.Entities()) != 1 {
		t.Fatalf("%s has no unique event owner", schema)
	}

	state, _ := store.Get(store.Entities()[0])

	if err := state.Set("next_aut", int64(g.currentAut+10)); err != nil {
		t.Fatal(err)
	}
}

// The first Doroklohe countdown warns and advances its saved phase.
func TestWizlabDorokloheFirstLiveWarning(t *testing.T) {
	g := enterNamedWizlab(t, "wizlab_doroklohe")
	forceWizlabEventDeadline(t, g, "world.wizlab_doroklohe")

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.wizlab_doroklohe"]
	state, _ := store.Get(store.Entities()[0])
	phase, _ := state.Get("phase")

	if phase != int64(2) {
		t.Fatalf("Doroklohe first phase = %v", phase)
	}
}

// The M callback consumes source G graves and produces real hostile actors.
// The save path then joins each spawned actor to its consumed grave.
func TestWizlabZonguldrokLiveGraveWave(t *testing.T) {
	g := enterNamedWizlab(t, "wizlab_zonguldrok")
	forceWizlabEventDeadline(t, g, "world.wizlab_zonguldrok")

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.wizlab_zonguldrok"]
	state, _ := store.Get(store.Entities()[0])
	count, _ := state.Get("count")

	if count == int64(0) {
		t.Fatal("Zonguldrok source graves did not awaken")
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("Zonguldrok grave wave cannot restore: %v", err)
	}
}

// A permanent undead killed after the initial population can award XP.
// Its encounter death count supplies the extra restore capacity.
func TestWizlabZonguldrokGraveRewardRestores(t *testing.T) {
	g := enterNamedWizlab(t, "wizlab_zonguldrok")
	forceWizlabEventDeadline(t, g, "world.wizlab_zonguldrok")

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	actors := g.scripts.Components()["world.wizlab_event_actor"]

	if actors == nil || len(actors.Entities()) == 0 {
		t.Fatal("Zonguldrok has no awakened grave actor")
	}

	grave := actors.Entities()[0]
	health, found := g.stores.Health.Get(grave)

	if !found {
		t.Fatal("grave actor has no health")
	}

	health.Current = 0

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.wizlab_zonguldrok"]
	state, _ := store.Get(store.Entities()[0])
	killed, _ := state.Get("killed")

	if killed == int64(0) {
		t.Fatal("grave death did not reach the encounter owner")
	}

	// Simulate one credited XP after the death signal. The existing
	// progression validator still checks skill and level consistency.
	progress, _ := g.stores.Progression.Get(g.player)
	training, _ := g.stores.SkillTraining.Get(g.player)
	progress.TotalXP++
	training.AvailableXP += 10

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("Zonguldrok grave reward cannot restore: %v", err)
	}
}

// The revealed D door is an ordinary door after the encounter creates
// it. Opening it through the player command must keep the floor valid.
func TestWizlabZonguldrokOpenDoorRestores(t *testing.T) {
	g := enterNamedWizlab(t, "wizlab_zonguldrok")
	store := g.scripts.Components()["world.wizlab_zonguldrok"]
	state, _ := store.Get(store.Entities()[0])
	xValue, _ := state.Get("door_x")
	yValue, _ := state.Get("door_y")
	doorX := int(xValue.(int64))
	doorY := int(yValue.(int64))
	position, _ := g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]
	floor.terrain[doorY][doorX] = terrain.ClosedDoor

	if err := state.Set("door_appeared", true); err != nil {
		t.Fatal(err)
	}

	directions := []point{
		{
			x: 0,
			y: -1,
		},
		{
			x: 1,
			y: 0,
		},
		{
			x: 0,
			y: 1,
		},
		{
			x: -1,
			y: 0,
		},
	}
	placed := false

	for _, direction := range directions {
		x := doorX + direction.x
		y := doorY + direction.y
		_, occupied := floor.ActorAt(x, y)

		if !floor.Walkable(x, y) || occupied {
			continue
		}

		if err := floor.MoveActor(g.player, x, y); err != nil {
			t.Fatal(err)
		}

		opened, err := g.Step(Command{
			Kind: CommandOpenDoor,
			DX:   -direction.x,
			DY:   -direction.y,
		})

		if err != nil || opened.Spent == 0 {
			t.Fatalf("cannot open Zonguldrok door: %+v, %v", opened, err)
		}

		placed = true
		break
	}

	if !placed {
		t.Fatal("Zonguldrok door has no adjacent landing")
	}

	if floor.terrain[doorY][doorX] != terrain.OpenDoor {
		t.Fatal("ordinary open command did not change the source door")
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("opened Zonguldrok door cannot restore: %v", err)
	}
}

// Wucad's source A timer places short-lived monks through the ordinary
// summon owner, with event provenance surviving a save round trip.
func TestWizlabWucadLiveMonkSummons(t *testing.T) {
	g := enterNamedWizlab(t, "wizlab_wucad")
	forceWizlabEventDeadline(t, g, "world.wizlab_wucad")

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	actors := g.scripts.Components()["world.wizlab_event_actor"]

	if actors == nil || len(actors.Entities()) == 0 {
		t.Fatal("Wucad source timer placed no monks")
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("Wucad monks cannot restore: %v", err)
	}
}
