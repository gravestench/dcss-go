package game

import (
	"fmt"
	"reflect"
	"strings"
	"testing"
	"time"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

type combatRoll struct{ bound, value int }
type combatRoller struct{ rolls []combatRoll }

func (r *combatRoller) Intn(stream string, bound int) (int, error) {
	if stream != "melee" || len(r.rolls) == 0 || r.rolls[0].bound != bound {
		return 0, fmt.Errorf("unexpected %s roll %d; left %+v", stream, bound, r.rolls)
	}
	value := r.rolls[0].value
	r.rolls = r.rolls[1:]
	return value, nil
}

func TestRatBiteAppliesSourceDefenseToLiveFighter(t *testing.T) {
	for _, tc := range []struct {
		name, message  string
		rolls          []combatRoll
		hpLoss, blocks int
	}{
		{"dodge", "dodge", []combatRoll{{20, 0}, {10, 5}, {11, 5}, {100, 10}, {15, 14}, {18, 0}, {19, 0}}, 0, 0},
		{"block", "block", []combatRoll{{20, 0}, {10, 5}, {11, 5}, {100, 10}, {15, 0}, {18, 17}, {19, 18}}, 0, 1},
		{"absorb", "no damage", []combatRoll{{20, 19}, {10, 0}, {11, 0}, {100, 10}, {15, 14}, {18, 0}, {19, 0}, {3, 2}, {7, 6}}, 0, 0},
		{"hit", "bites you", []combatRoll{{20, 19}, {10, 0}, {11, 0}, {100, 10}, {15, 14}, {18, 0}, {19, 0}, {3, 2}, {7, 0}}, 3, 0},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newStepGame(t)
			rat := ratID(t, g)
			if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
				t.Fatal(err)
			}
			if _, err := g.stores.Intents.Set(rat, ecs.Intent{
				Kind: ecs.IntentMelee,
				DX:   -1,
			}); err != nil {
				t.Fatal(err)
			}
			g.turn.Actor = rat
			rng := &combatRoller{rolls: tc.rolls}
			before, _ := g.stores.Health.Get(g.player)
			initialHP := before.Current
			system := newCombatSystem(g)
			system.roller = rng
			if err := system.Update(nil, time.Duration(10)); err != nil {
				t.Fatal(err)
			}
			after, _ := g.stores.Health.Get(g.player)
			state, _ := g.stores.Combat.Get(g.player)
			if initialHP-after.Current != tc.hpLoss || state.ShieldBlocks != tc.blocks || len(rng.rolls) != 0 {
				t.Fatalf("HP %d -> %d, combat %+v, rolls %+v", initialHP, after.Current, state, rng.rolls)
			}
			if len(g.turn.Events) != 1 || !strings.Contains(strings.ToLower(g.turn.Events[0].Text), tc.message) {
				t.Fatalf("events %+v do not report %q", g.turn.Events, tc.message)
			}
		})
	}
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
	if err != nil || result.Spent != 10 || result.View.CurrentAut != 10 {
		t.Fatalf("unarmed wait/rat bite = %+v, %v", result, err)
	}
}

func TestFighterViewDisplaysSourceDefense(t *testing.T) {
	g := newStepGame(t)
	view := g.View()
	if !view.DefenseKnown || view.PlayerAC != 6 || view.PlayerEV != 5 || view.PlayerSH != 4 {
		t.Fatalf("Fighter defense in view = AC %d EV %d SH %d known %v", view.PlayerAC, view.PlayerEV, view.PlayerSH, view.DefenseKnown)
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
	if snapshot.Version != 6 || save.Version != 6 {
		t.Fatalf("combat save version %d/%d, want 6", snapshot.Version, save.Version)
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
	if _, err := Restore(snapshot, testCatalog(t)); err == nil || !strings.Contains(err.Error(), "unsupported save version") {
		t.Fatalf("version-5 restore error = %v", err)
	}
	snapshot.Version = save.Version
	for i := range snapshot.Entities {
		if snapshot.Entities[i].ID == uint64(g.player) {
			snapshot.Entities[i].Combatant.ShieldBlocks = -1
		}
	}
	if _, err := Restore(snapshot, testCatalog(t)); err == nil || !strings.Contains(err.Error(), "combat") {
		t.Fatalf("negative shield-block restore error = %v", err)
	}
}

func TestRestoreRejectsCombatStateItCannotRun(t *testing.T) {
	for _, tc := range []struct {
		name, want string
		mutate     func(*save.Snapshot)
	}{
		{"cataloged non-rat", "unsupported melee attacker", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].AI != nil {
					snapshot.Entities[i].Actor.KindID = "MONS_ORC"
				}
			}
		}},
		{"body armour enchantment", "defense", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Item != nil && snapshot.Entities[i].Item.KindID == "ARM_SCALE_MAIL" {
					snapshot.Entities[i].Item.Plus = 101
				}
			}
		}},
		{"shield enchantment", "defense", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Item != nil && snapshot.Entities[i].Item.KindID == "ARM_BUCKLER" {
					snapshot.Entities[i].Item.Plus = 101
				}
			}
		}},
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
