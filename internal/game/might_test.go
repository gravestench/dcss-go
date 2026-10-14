package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

func carriedMight(t *testing.T, g *Game) uint64 {
	t.Helper()

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)

		if item.KindID == "POT_MIGHT" {
			carrier, ok := g.stores.CarriedBy.Get(entity)

			if !ok || carrier.Holder != g.player {
				t.Fatal("starting might potion is not carried")
			}

			return uint64(entity)
		}
	}

	t.Fatal("missing starting might potion")

	return 0
}

func TestQuaffMightConsumesAndDecaysByActionCost(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(ratID(t, g), 14, 7); err != nil {
		t.Fatal(err)
	}

	id := carriedMight(t, g)
	expected := RestoreRNGStreams(g.seed, g.rng.States())
	roll, _ := expected.Intn("potion", 40)
	result, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: id,
	})

	if err != nil || result.Spent != 10 || result.View.MightAut != (35+roll)*10-10 {
		t.Fatalf("might quaff = %+v, %v", result, err)
	}

	if g.world.EntityExists(akara.Entity(id)) || !strings.Contains(result.Events[0].Text, "very mighty") {
		t.Fatalf("potion not consumed or source message missing: %+v", result)
	}

	if _, ok := g.stores.Durations.Get(g.player); !ok {
		t.Fatal("player has no duration state")
	}

	if expected.States()["potion"] != g.rng.States()["potion"] {
		t.Fatal("might potion did not consume exactly one potion draw")
	}

	before := result.View.MightAut
	result, err = g.Step(Command{Kind: CommandWait})

	if err != nil || result.View.MightAut != before-10 {
		t.Fatalf("wait decay = %+v, %v", result, err)
	}

	status, _ := g.stores.Durations.Get(g.player)
	status.MightAut = 9
	result, err = g.Step(Command{Kind: CommandWait})

	if err != nil || result.View.MightAut != 0 || !containsEvent(result.Events, "You feel a little less mighty now.") {
		t.Fatalf("expiry = %+v, %v", result, err)
	}
}

func TestMightRepeatQuaffCapsAtEightyTurns(t *testing.T) {
	g := newStepGame(t)
	id := carriedMight(t, g)
	item, _ := g.stores.Items.Get(akara.Entity(id))
	item.Quantity = 2
	status, _ := g.stores.Durations.Get(g.player)
	status.MightAut = 790
	result, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: id,
	})

	if err != nil || result.View.MightAut != 790 || item.Quantity != 1 ||
		!containsEvent(result.Events, "You feel mightier all of a sudden.") {
		t.Fatalf("repeat might = %+v, %v; stack %+v", result, err, item)
	}
}

func TestMightDecaysByVariableMeleeActionCost(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	status, _ := g.stores.Durations.Get(g.player)
	status.MightAut = 20
	attack, err := newPlayerCombat(g).attackInput("MONS_RAT")

	if err != nil || !attack.Mighty {
		t.Fatalf("live attack did not project might: %+v, %v", attack, err)
	}

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil || result.Spent <= 0 || result.View.MightAut != 20-int(result.Spent) {
		t.Fatalf("mighty attack timing = %+v, %v", result, err)
	}
}

func containsEvent(events []Event, text string) bool {
	for _, event := range events {
		if event.Text == text {
			return true
		}
	}

	return false
}

func TestMightSaveContinuationAndLegacyDefault(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: carriedMight(t, g),
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	left, leftErr := g.Step(Command{Kind: CommandWait})
	right, rightErr := loaded.Step(Command{Kind: CommandWait})

	if leftErr != nil || rightErr != nil || !reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("might continuation = %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
	}

	legacy := newStepGame(t).Snapshot()

	for i := range legacy.Entities {
		legacy.Entities[i].Durations = nil
	}

	old, err := Restore(legacy, testCatalog(t))

	if err != nil || old.View().MightAut != 0 {
		t.Fatalf("old save restore = %v, might %d", err, old.View().MightAut)
	}

	defer old.Close()
}

func TestMightRestoreRejectsBadOwnershipAndRange(t *testing.T) {
	g := newStepGame(t)
	base := g.Snapshot()

	for _, tc := range []struct {
		name string
		edit func(*ecs.Durations, *ecs.Durations)
	}{
		{
			name: "negative",
			edit: func(player, monster *ecs.Durations) {
				player.MightAut = -1
			},
		},
		{
			name: "over cap",
			edit: func(player, monster *ecs.Durations) {
				player.MightAut = 801
			},
		},
		{
			name: "monster",
			edit: func(player, monster *ecs.Durations) {
				monster.MightAut = 10
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			bad := base
			bad.Entities = append([]save.EntityRecord(nil), base.Entities...)

			for i := range bad.Entities {
				record := &bad.Entities[i]

				if record.Player != nil {
					copy := *record.Durations
					record.Durations = &copy
				}

				if record.AI != nil {
					record.Durations = &ecs.Durations{}
				}
			}

			var player *ecs.Durations
			var monster *ecs.Durations

			for i := range bad.Entities {
				if bad.Entities[i].Player != nil {
					player = bad.Entities[i].Durations
				}

				if bad.Entities[i].AI != nil {
					monster = bad.Entities[i].Durations
				}
			}

			tc.edit(player, monster)

			if _, err := Restore(bad, testCatalog(t)); err == nil {
				t.Fatal("bad duration save accepted")
			}
		})
	}
}
