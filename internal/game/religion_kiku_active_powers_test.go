package game

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/gravestench/akara"
)

// The terminal reads these exact Lua options, so both newly registered
// powers must be present before either command is submitted.
func assertKikuAbilityMenu(t *testing.T, g *Game) {
	t.Helper()

	result, err := g.PresentationPolicy("presentation.abilities",
		map[string]any{"height": 24})

	if err != nil {
		t.Fatal(err)
	}

	options, ok := result["options"].([]any)

	if !ok {
		t.Fatalf("ability menu options: %T", result["options"])
	}

	wanted := map[string]bool{
		"ABIL_KIKU_UNEARTH_WRETCHES": false,
		"ABIL_KIKU_TORMENT":          false,
	}

	for _, value := range options {
		option, ok := value.(map[string]any)

		if !ok {
			t.Fatalf("ability menu option: %T", value)
		}

		id, ok := option["id"].(string)

		if !ok {
			t.Fatalf("ability menu id: %T", option["id"])
		}

		if _, needed := wanted[id]; needed {
			wanted[id] = true
		}
	}

	for id, seen := range wanted {
		if !seen {
			t.Fatalf("Kiku ability menu omitted %s", id)
		}
	}
}

// The ordinary command bridge must create a real corpse-bearing Kiku actor,
// and the saved component must still own its short life after restoration.
func TestKikuUnearthWretchesSurvivesRestore(t *testing.T) {
	g, err := NewDungeonGame(2061, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_KIKUBAAQUDGHA",
			"piety":  int64(200),
		},
	); err != nil {
		t.Fatal(err)
	}

	assertKikuAbilityMenu(t, g)

	marker := g.scripts.Components()["religion.kiku_wretch"]
	var creature akara.Entity

	for attempt := 0; attempt < 8; attempt++ {
		magic, found := g.stores.Magic.Get(g.player)

		if !found {
			t.Fatal("player has no MP")
		}

		magic.Max = 20
		magic.Current = 20

		if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_KIKU_UNEARTH_WRETCHES",
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent != 10 {
			t.Fatalf("Unearth Wretches spent %d aut", result.Spent)
		}

		for _, entity := range marker.Entities() {
			creature = entity
			break
		}

		if creature != 0 {
			break
		}
	}

	if creature == 0 {
		t.Fatal("Kiku created no real wretch")
	}

	if g.scripts.Components()["magic.summon"].Has(creature) {
		t.Fatal("wretch was registered as a disappearing summon")
	}

	health, found := g.stores.Health.Get(creature)

	if !found || health.Current != 1 {
		t.Fatalf("wretch health: %+v, found %v", health, found)
	}

	for _, item := range g.stores.CarriedBy.Entities() {
		carrier, found := g.stores.CarriedBy.Get(item)

		if !found {
			continue
		}

		if carrier.Holder == creature {
			t.Fatal("Kiku wretch spawned with ordinary monster gear")
		}
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["religion.kiku_wretch"].Has(
		creature) {
		t.Fatal("restored game lost Kiku wretch lifetime")
	}

	lastPosition, found := restored.stores.Positions.Get(creature)

	if !found {
		t.Fatal("restored wretch has no position")
	}

	for attempt := 0; attempt < 5 &&
		restored.scripts.Components()["religion.kiku_wretch"].Has(
			creature); attempt++ {
		if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if restored.scripts.Components()["religion.kiku_wretch"].Has(
		creature) {
		t.Fatal("wretch did not perish after its saved timer")
	}

	corpseFound := false

	for _, entity := range restored.stores.Corpses.Entities() {
		position, found := restored.stores.Positions.Get(entity)

		if !found {
			continue
		}

		if position.LevelID == lastPosition.LevelID &&
			position.X == lastPosition.X &&
			position.Y == lastPosition.Y {
			corpseFound = true

			break
		}
	}

	if !corpseFound {
		t.Fatal("expired wretch left no corpse")
	}
}

// A forged lifetime cannot turn an unrelated actor into an XP-free,
// guaranteed-corpse wretch on restore.
func TestRestoreRejectsInvalidKikuWretch(t *testing.T) {
	g, err := NewDungeonGame(2061, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Components()["religion.kiku_wretch"].Set(
		g.player,
		map[string]any{"remaining_aut": int64(999)},
	); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()

	for i := range snapshot.Entities {
		if snapshot.Entities[i].Player == nil {
			continue
		}

		for j := range snapshot.Entities[i].Dynamic {
			part := &snapshot.Entities[i].Dynamic[j]

			if part.Schema == "religion.kiku_wretch" {
				part.Values["remaining_aut"] = json.RawMessage("30")
			}
		}
	}

	loaded, err := Restore(snapshot)

	if loaded != nil {
		loaded.Close()
	}

	if err == nil {
		t.Fatal("forged Kiku wretch was restored")
	}

	if !strings.Contains(err.Error(), "Kiku wretch") {
		t.Fatalf("forged Kiku wretch restore: %v", err)
	}
}

// A player melee kill must not turn Kiku's own sacrificial monster into XP.
// The body still enters ordinary corpse handling for Necromancy consumers.
func TestPlayerKillOfKikuWretchGivesCorpseButNoExperience(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, found := g.stores.Health.Get(rat)

	if !found {
		t.Fatal("rat has no health")
	}

	health.Current = 1

	if _, err := g.stores.Health.Set(rat, *health); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["religion.kiku_wretch"].Set(
		rat,
		map[string]any{"remaining_aut": int64(29)},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["zap.paralysis"].Set(
		rat,
		map[string]any{"remaining_aut": int64(9999)},
	); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 2 && g.world.EntityExists(rat); attempt++ {
		if _, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		}); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(rat) {
		t.Fatal("paralyzed one-HP wretch survived player melee")
	}

	progress, found := g.stores.Progression.Get(g.player)

	if !found || progress.TotalXP != 0 {
		t.Fatalf("Kiku wretch awarded XP: %+v", progress)
	}

	if len(g.stores.Corpses.Entities()) == 0 {
		t.Fatal("player-killed Kiku wretch left no corpse")
	}
}

// Invoked Torment uses the existing area owner, including the player's
// partial Kiku shield, and remains a normal timed ability command.
func TestKikuTormentUsesGameCommandBridge(t *testing.T) {
	g, err := NewDungeonGame(2063, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_KIKUBAAQUDGHA",
			"piety":  int64(200),
		},
	); err != nil {
		t.Fatal(err)
	}

	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("player has no MP")
	}

	magic.Max = 20
	magic.Current = 20

	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_KIKU_TORMENT",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("Torment spent %d aut", result.Spent)
	}
}
