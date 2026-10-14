package game

import (
	"dcrawl-go/internal/save"
	"fmt"
	"reflect"
	"strings"
	"testing"
)

type combatRoll struct {
	bound int
	value int
}

type combatRoller struct {
	rolls []combatRoll
}

func (r *combatRoller) Intn(stream string, bound int) (int, error) {
	if stream != "melee" ||
		len(r.rolls) == 0 || r.rolls[0].bound != bound {
		return 0, fmt.Errorf("unexpected %s roll %d; left %+v", stream, bound, r.rolls)
	}

	value := r.rolls[0].value

	r.rolls = r.rolls[1:]

	return value, nil
}

func TestRatBiteWorksForUnarmedFighterAndCostsOneTurn(t *testing.T) {
	g, err := NewScenario(31, testCatalog(t), "WPN_UNARMED", "Barehands")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil ||
		result.Spent != 10 || result.View.CurrentAut != 10 {
		t.Fatalf("unarmed wait/rat bite = %+v, %v", result, err)
	}
}

func TestFighterViewDisplaysSourceDefense(t *testing.T) {
	g := newStepGame(t)
	view := g.View()

	if !view.DefenseKnown ||
		view.PlayerAC != 6 ||
		view.PlayerEV != 5 ||
		view.PlayerSH != 4 {
		t.Fatalf(
			"Fighter defense in view = AC %d EV %d SH %d known %v",
			view.PlayerAC,
			view.PlayerEV,
			view.PlayerSH,
			view.DefenseKnown,
		)
	}
}

func TestPlayerActionResetsPriorRoundShieldBlocks(t *testing.T) {
	g := newStepGame(t)
	state, _ := g.stores.Combat.Get(g.player)

	state.ShieldBlocks = 2

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if state.ShieldBlocks > 1 {
		t.Fatalf("prior-round shield blocks retained: %d", state.ShieldBlocks)
	}
}

func TestCombatStateAndMeleeRNGContinueThroughSave(t *testing.T) {
	g := newStepGame(t)
	state, _ := g.stores.Combat.Get(g.player)

	state.ShieldBlocks = 1

	if _, err := g.rng.Intn("melee", 20); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()

	if snapshot.Version != save.Version {
		t.Fatalf("combat save version %d, want %d", snapshot.Version, save.Version)
	}

	restored, err := Restore(snapshot, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	loaded, _ := restored.stores.Combat.Get(restored.player)

	if loaded.ShieldBlocks != 1 {
		t.Fatalf("saved shield blocks = %d, want 1", loaded.ShieldBlocks)
	}

	want, _ := g.rng.Intn("melee", 100)
	got, _ := restored.rng.Intn("melee", 100)

	if got != want {
		t.Fatalf("melee RNG after load = %d, want %d", got, want)
	}
}

func TestCombatSaveRejectsNegativeBlocksAndOldVersion(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()

	snapshot.Version = 5

	if _, err := Restore(snapshot, testCatalog(t)); err == nil ||
		!strings.Contains(err.Error(), "unsupported save version") {
		t.Fatalf("version-5 restore error = %v", err)
	}

	snapshot.Version = save.Version

	for i := range snapshot.Entities {
		if snapshot.Entities[i].ID == uint64(g.player) {
			snapshot.Entities[i].Combatant.ShieldBlocks = -1
		}
	}

	if _, err := Restore(snapshot, testCatalog(t)); err == nil ||
		!strings.Contains(err.Error(), "combat") {
		t.Fatalf("negative shield-block restore error = %v", err)
	}
}

func TestRestoreRejectsCombatStateItCannotRun(t *testing.T) {
	for _, tc := range []struct {
		name   string
		want   string
		mutate func(*save.Snapshot)
	}{
		{
			name: "cataloged non-rat",
			want: "unsupported melee attacker",
			mutate: func(snapshot *save.Snapshot) {
				for i := range snapshot.Entities {
					if snapshot.Entities[i].AI != nil {
						snapshot.Entities[i].Actor.KindID = "MONS_ORC"
					}
				}
			},
		},

		{
			name: "body armour enchantment",
			want: "defense",
			mutate: func(snapshot *save.Snapshot) {
				for i := range snapshot.Entities {
					if snapshot.Entities[i].Item != nil &&
						snapshot.Entities[i].Item.KindID == "ARM_SCALE_MAIL" {
						snapshot.Entities[i].Item.Plus = 101
					}
				}
			},
		},

		{
			name: "shield enchantment",
			want: "defense",
			mutate: func(snapshot *save.Snapshot) {
				for i := range snapshot.Entities {
					if snapshot.Entities[i].Item != nil &&
						snapshot.Entities[i].Item.KindID == "ARM_BUCKLER" {
						snapshot.Entities[i].Item.Plus = 101
					}
				}
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newStepGame(t)
			before := g.Snapshot()
			bad := g.Snapshot()
			tc.mutate(&bad)

			if reflect.DeepEqual(before, bad) {
				t.Fatal("test did not mutate the save")
			}

			if replacement, err := g.Restore(bad); err == nil {
				replacement.Close()
				t.Fatal("unsupported combat state restored")
			} else if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("restore error %q does not contain %q", err, tc.want)
			}

			if !reflect.DeepEqual(before, g.Snapshot()) {
				t.Fatal("failed restore changed the live game")
			}
		})
	}
}
