package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/save"
	"github.com/gravestench/akara"
)

// Place a real catalog Orb on the player's cell. The normal pickup system
// must process the entity exactly as it will process the Hall's live Orb.
func putOrbAtPlayer(t *testing.T, g *Game) akara.Entity {
	t.Helper()

	orb, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	g.noteEntity(orb)

	if _, err := g.stores.Items.Set(orb, ecs.Item{
		KindID:   "ORB_ZOT",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	if _, err := g.stores.Positions.Set(orb, *position); err != nil {
		t.Fatal(err)
	}

	return orb
}

// The pinned source treats Orb pickup as a chapter change, not an inventory
// transfer. Restore must retain that chapter after the floor entity is gone.
func TestOrbPickupStartsSavedEscapeWithoutInventoryStack(t *testing.T) {
	g := newStepGame(t)
	orb := putOrbAtPlayer(t, g)

	result, err := g.Step(Command{Kind: CommandPickup})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 || g.stores.Items.Has(orb) {
		t.Fatalf("Orb pickup spent %d aut and left item %v",
			result.Spent, g.stores.Items.Has(orb))
	}

	for _, entity := range g.stores.CarriedBy.Entities() {
		item, found := g.stores.Items.Get(entity)

		if found && item.KindID == "ORB_ZOT" {
			t.Fatal("Orb became an inventory stack")
		}
	}

	phase := g.scripts.Components()["character.endgame"]
	state, found := phase.Get(g.player)

	if !found {
		t.Fatal("Orb pickup did not give the player endgame state")
	}

	value, err := state.Get("phase")

	if err != nil {
		t.Fatal(err)
	}

	if value != "escaping" {
		t.Fatalf("Orb phase = %v, %v", value, err)
	}

	joined := ""

	for _, event := range result.Events {
		joined += event.Text + "\n"
	}

	if !strings.Contains(joined, "You pick up the Orb of Zot!") ||
		!strings.Contains(joined, "get back out of the dungeon") {
		t.Fatalf("Orb pickup messages = %q", joined)
	}

	before := g.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("Orb pickup changed across restore")
	}
}

// Restoring a second live Orb after the chapter has advanced could permit
// repeated pickups or an impossible win state. The Lua save policy rejects it.
func TestOrbEscapeRejectsSavedDuplicateOrb(t *testing.T) {
	g := newStepGame(t)
	putOrbAtPlayer(t, g)

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	snapshot.EntityCursor++
	snapshot.Entities = append(snapshot.Entities, save.EntityRecord{
		ID: snapshot.EntityCursor,
		Item: &ecs.Item{
			KindID:   "ORB_ZOT",
			Quantity: 1,
		},
		Position: position,
	})

	_, err := Restore(snapshot)

	if err == nil {
		t.Fatal("duplicate Orb restored successfully")
	}

	if !strings.Contains(err.Error(), "saved Orb item conflicts") {
		t.Fatalf("duplicate Orb restore error = %v", err)
	}
}

// A generated Dungeon exit is a real decision point. Source DCSS asks before
// leaving without the Orb, then ends the run as a loss if confirmed.
func TestDungeonExitRequiresConfirmationWithoutOrb(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	before := g.Snapshot()

	choice, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	if choice.Spent != 0 || choice.Confirmation == "" {
		t.Fatalf("unconfirmed exit: spent=%d confirmation=%q err=%v",
			choice.Spent, choice.Confirmation, err)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("unconfirmed exit changed the run")
	}

	left, err := g.Step(Command{
		Kind:   CommandUpstairs,
		Forced: true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if left.Spent == 0 {
		t.Fatalf("confirmed exit: spent=%d err=%v", left.Spent, err)
	}

	state, found := g.scripts.Components()["character.endgame"].Get(g.player)

	if !found {
		t.Fatal("leaving did not retain endgame state")
	}

	phase, err := state.Get("phase")

	if err != nil {
		t.Fatal(err)
	}

	if phase != "left" {
		t.Fatalf("exit phase = %v, %v", phase, err)
	}
}

// A normal win uses the same live Orb pickup path as the Hall and preserves
// its terminal player chapter after restore.
func TestOrbEscapeWinsAndStopsFurtherTurns(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	putOrbAtPlayer(t, g)

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	won, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	if won.Spent == 0 || won.Confirmation != "" {
		t.Fatalf("Orb escape: spent=%d confirmation=%q err=%v",
			won.Spent, won.Confirmation, err)
	}

	state, found := g.scripts.Components()["character.endgame"].Get(g.player)

	if !found {
		t.Fatal("winner has no saved chapter")
	}

	phase, err := state.Get("phase")

	if err != nil {
		t.Fatal(err)
	}

	if phase != "won" {
		t.Fatalf("winning phase = %v, %v", phase, err)
	}

	before := g.Snapshot()
	ignored, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if ignored.Spent != 0 || !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatalf("finished run advanced: spent=%d err=%v", ignored.Spent, err)
	}

	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("victory changed across save restore")
	}
}

// Choose a saved RNG state whose next source check spawns an Orb Guardian.
// The policy still performs all real draws, including the eager Pan row draw.
func guardianSpawnState(t *testing.T) uint64 {
	t.Helper()

	for candidate := uint64(0); candidate < 10000; candidate++ {
		stream := NewRNGStreams(1)

		stream.states["orb_run"] = candidate

		gate, _ := stream.Intn("orb_run", 18)
		rare, _ := stream.Intn("orb_run", 10)
		_, _ = stream.Intn("orb_run", 2)
		category, _ := stream.Intn("orb_run", 90)

		if gate < 5 &&
			rare != 0 &&
			category < 15 {
			return candidate
		}
	}

	t.Fatal("no deterministic Orb Guardian spawn state")

	return 0
}

// The saved aut clock crosses the five-turn boundary exactly once after
// restore. The Lua defender policy creates a normal persistent ECS monster.
func TestOrbRunGuardianSpawnsAtSavedBoundary(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	putOrbAtPlayer(t, g)

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	for g.currentAut < 40 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	spawnState := guardianSpawnState(t)

	g.rng.states["orb_run"] = spawnState

	before := g.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	for _, run := range []*Game{g, restored} {
		if _, err := run.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		guardians := 0

		for _, entity := range run.stores.Actors.Entities() {
			actor, _ := run.stores.Actors.Get(entity)

			if actor.KindID == "MONS_ORB_GUARDIAN" {
				guardians++
			}
		}

		if guardians != 1 {
			t.Fatalf("Orb-run boundary spawned %d guardians", guardians)
		}
	}

	live := g.Snapshot()
	loaded := restored.Snapshot()

	if !reflect.DeepEqual(live, loaded) {
		for index := range live.Entities {
			left := reflect.ValueOf(live.Entities[index])
			right := reflect.ValueOf(loaded.Entities[index])

			for field := 0; field < left.NumField(); field++ {
				if !reflect.DeepEqual(left.Field(field).Interface(),
					right.Field(field).Interface()) {
					t.Logf("entity %d field %s: %#v / %#v",
						live.Entities[index].ID,
						left.Type().Field(field).Name,
						left.Field(field).Interface(),
						right.Field(field).Interface())
				}
			}
		}

		t.Fatalf("Orb-run divergence: clock=%d/%d rng=%v/%v entities=%d/%d levels=%d/%d messages=%v/%v",
			live.CurrentAut, loaded.CurrentAut,
			live.RNG, loaded.RNG,
			len(live.Entities), len(loaded.Entities),
			len(live.Levels), len(loaded.Levels),
			live.Messages, loaded.Messages)
	}
}
