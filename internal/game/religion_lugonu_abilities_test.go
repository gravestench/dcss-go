package game

import (
	"os"
	"path/filepath"
	"strconv"
	"testing"

	"crawl/internal/save"
	"github.com/gravestench/akara"
)

// A source Abyssal Knight already has an exit at the pocket start. The
// divine power must use that same world transition from any floor cell.
func TestLugonuDepartUsesSavedAbyssReturn(t *testing.T) {
	g, err := NewDungeonGame(1, "SP_HUMAN",
		"JOB_ABYSSAL_KNIGHT", "WPN_HAND_AXE", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	initial, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("baseline pocket restore: %v", err)
	}

	initial.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_LUGONU",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_LUGONU_ABYSS_EXIT",
	})

	if err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if result.Spent != 10 || position.LevelID != 1 {
		t.Fatalf("Depart spent %d, level %d, events %+v",
			result.Spent, position.LevelID, result.Events)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	position, _ = restored.stores.Positions.Get(restored.player)

	if position.LevelID != 1 {
		t.Fatalf("restored Depart level = %d", position.LevelID)
	}
}

// The real terminal command bridge keeps the selected weapon across a
// free confirmation and save, then mutates that exact carried item once.
func TestLugonuBlessWeaponSelectionAndRestore(t *testing.T) {
	g, err := NewDungeonGame(1, "SP_HUMAN",
		"JOB_ABYSSAL_KNIGHT", "WPN_HAND_AXE", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_LUGONU",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_LUGONU_BLESS_WEAPON",
	}

	first, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if first.Spent != 0 || first.Selection == nil ||
		len(first.Selection.Options) == 0 {
		t.Fatalf("blessing selection = %+v", first)
	}

	command.TargetID = first.Selection.Options[0].ID
	selectedID, err := strconv.ParseUint(command.TargetID, 10, 64)

	if err != nil {
		t.Fatal(err)
	}

	weapon := akara.Entity(selectedID)
	before, found := g.stores.Items.Get(weapon)

	if !found {
		t.Fatal("selected weapon has no item component")
	}

	initialPlus := before.Plus

	second, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if second.Spent != 0 || second.Confirmation == "" {
		t.Fatalf("blessing confirmation = %+v", second)
	}

	restoredChoice, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("restore pending blessing: %v", err)
	}

	restoredChoice.Close()
	command.Forced = true

	third, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	after, found := g.stores.Items.Get(weapon)

	if third.Spent != 10 || !found ||
		after.Ego != "SPWPN_DISTORTION" ||
		after.Plus != initialPlus+2 {
		t.Fatalf("blessing result spent %d, item %+v", third.Spent, after)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("restore blessed weapon: %v", err)
	}

	defer restored.Close()

	if restored.scripts.Components()["religion.lugonu_bless_choice"].Has(
		restored.player) {
		t.Fatal("completed blessing still has a pending choice")
	}
}

// A real generated floor must accept permanent corruption, keep its
// stair graph valid, and restore the saved nexus after terrain changes.
func TestLugonuCorruptGeneratedFloorAndRestore(t *testing.T) {
	g, err := NewDungeonGame(1, "SP_HUMAN",
		"JOB_ABYSSAL_KNIGHT", "WPN_HAND_AXE", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_LUGONU",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_LUGONU_ABYSS_EXIT",
	}); err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_LUGONU",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	corrupted := false

	for attempt := 0; attempt < 12; attempt++ {
		magic, _ := g.stores.Magic.Get(g.player)
		magic.Max = 20
		magic.Current = 20

		if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
			t.Fatal(err)
		}

		health, _ := g.stores.Health.Get(g.player)
		health.Current = health.Max

		if _, err := g.stores.Health.Set(g.player, *health); err != nil {
			t.Fatal(err)
		}

		before, _ := g.scripts.Components()["religion.worship"].Get(g.player)
		beforePiety, err := before.Get("piety")

		if err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_LUGONU_CORRUPT",
		})

		if err != nil {
			t.Fatal(err)
		}

		after, _ := g.scripts.Components()["religion.worship"].Get(g.player)
		afterPiety, err := after.Get("piety")

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent == 10 && afterPiety.(int64) <
			beforePiety.(int64) {
			corrupted = true
			break
		}
	}

	if !corrupted {
		t.Fatal("Corrupt never succeeded on the generated floor")
	}

	// Keep one inspectable full-floor ASCII snapshot with its stair
	// connections. Regeneration is explicit; normal tests only compare it.
	snapshot := g.Snapshot()
	levels := make(map[int]save.LevelRecord, len(snapshot.Levels))

	for _, level := range snapshot.Levels {
		levels[level.ID] = level
	}

	floor, found := levels[1]

	if !found {
		t.Fatal("corrupted Dungeon:1 is absent")
	}

	textMap := formatLevelTextSnapshot(floor, levels)
	path := filepath.Join("testdata", "lugonu_corruption_d1.txt")

	if os.Getenv("UPDATE_LUGONU_SNAPSHOT") == "1" {
		if err := os.WriteFile(path, []byte(textMap), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	want, err := os.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if textMap != string(want) {
		t.Fatal("corrupted Dungeon:1 map differs from its text snapshot")
	}

	if _, err := g.scripts.Policy("save.validate_lugonu_corruption", nil); err != nil {
		t.Fatalf("corruption nexus validation: %v", err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("restore corrupted floor: %v", err)
	}

	defer restored.Close()

	blocked, err := restored.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_LUGONU_CORRUPT",
	})

	if err != nil {
		t.Fatal(err)
	}

	if blocked.Spent != 0 {
		t.Fatalf("corrupted floor allowed a second invocation: %+v", blocked)
	}
}

// Enter keeps the departure cell in the Abyss owner. Depart after a
// saved Abyss visit must return to the same generated Dungeon floor.
func TestLugonuEnterAndDepartRoundTrip(t *testing.T) {
	g, err := NewDungeonGame(1, "SP_HUMAN",
		"JOB_ABYSSAL_KNIGHT", "WPN_HAND_AXE", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_LUGONU",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_LUGONU_ABYSS_EXIT",
	}); err != nil {
		t.Fatal(err)
	}

	origin, _ := g.stores.Positions.Get(g.player)
	entered := false

	for attempt := 0; attempt < 12; attempt++ {
		magic, _ := g.stores.Magic.Get(g.player)
		magic.Max = 20
		magic.Current = 20

		if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
			t.Fatal(err)
		}

		health, _ := g.stores.Health.Get(g.player)
		health.Current = health.Max

		if _, err := g.stores.Health.Set(g.player, *health); err != nil {
			t.Fatal(err)
		}

		_, err := g.scripts.Components()["religion.worship"].Set(
			g.player,
			map[string]any{
				"god_id": "GOD_LUGONU",
				"piety":  int64(200),
			},
		)

		if err != nil {
			t.Fatal(err)
		}

		if _, err := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_LUGONU_ABYSS_ENTER",
		}); err != nil {
			t.Fatal(err)
		}

		position, _ := g.stores.Positions.Get(g.player)

		if position.LevelID != origin.LevelID {
			entered = true
			break
		}
	}

	if !entered {
		t.Fatal("Enter the Abyss never succeeded")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("restore entered Abyss: %v", err)
	}

	defer restored.Close()

	magic, _ := restored.stores.Magic.Get(restored.player)
	magic.Max = 20
	magic.Current = 20

	if _, err := restored.stores.Magic.Set(restored.player, *magic); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_LUGONU_ABYSS_EXIT",
	}); err != nil {
		t.Fatal(err)
	}

	returned, _ := restored.stores.Positions.Get(restored.player)

	if returned.LevelID != origin.LevelID ||
		returned.X != origin.X || returned.Y != origin.Y {
		t.Fatalf("Depart returned to %+v, want %+v", returned, origin)
	}
}

// The real ray and monster will check must hand a successful invocation
// to the Abyss owner without killing or replacing the target entity.
func TestLugonuBanishKeepsMonsterIdentity(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	banished := false

	for attempt := 0; attempt < 80; attempt++ {
		worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

		if !found {
			t.Fatal("player lacks worship state")
		}

		if err := worship.Set("god_id", "GOD_LUGONU"); err != nil {
			t.Fatal(err)
		}

		if err := worship.Set("piety", int64(200)); err != nil {
			t.Fatal(err)
		}

		magic, _ := g.stores.Magic.Get(g.player)
		magic.Max = 20
		magic.Current = 20

		if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
			t.Fatal(err)
		}

		health, _ := g.stores.Health.Get(g.player)
		health.Current = health.Max

		if _, err := g.stores.Health.Set(g.player, *health); err != nil {
			t.Fatal(err)
		}

		dx, dy := placePlayerBesideMonster(t, g, rat)
		result, err := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_LUGONU_BANISH",
			DX:        dx,
			DY:        dy,
		})

		if err != nil {
			t.Fatal(err)
		}

		position, exists := g.stores.Positions.Get(rat)

		if result.Spent == 10 && exists &&
			position.LevelID != 1 {
			banished = true
			break
		}
	}

	if !banished || !g.world.EntityExists(rat) {
		t.Fatal("Banish did not move the original monster to the Abyss")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("restore banished monster: %v", err)
	}

	defer restored.Close()

	if !restored.world.EntityExists(rat) {
		t.Fatal("restore lost the banished monster entity")
	}
}
