package game

import (
	"strconv"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

// Every integration case starts with the same real Hill Orc game. The
// helper changes only worship, leaving game rules in production Lua.
func newBeoghAbilityGame(t *testing.T, seed uint64) *Game {
	t.Helper()

	g, err := NewDungeonGame(seed, "SP_HILL_ORC", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_BEOGH",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	return g
}

// Set up a real adjacent actor with the component provenance that save
// validation expects from an in-game Beogh resurrection and conversion.
func namedBeoghFollower(t *testing.T, g *Game) akara.Entity {
	t.Helper()

	orc, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Actors.Set(orc, ecs.Actor{
		KindID: "MONS_ORC",
		Speed:  10,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(orc, ecs.Health{
		Current: 10,
		Max:     10,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Combat.Set(orc, ecs.Combatant{}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.AI.Set(orc, ecs.MonsterAI{
		Behavior: "wander",
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.MonsterEnergy.Set(orc, ecs.MonsterEnergy{
		Points: 0,
	}); err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["vault.actor_overrides"].Set(
		orc,
		map[string]any{
			"custom_name": "Burguk",
			"fixed_hp":    int64(10),
			"attitude":    "friendly",
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["religion.beogh_orc"].Set(
		orc,
		map[string]any{
			"attitude":  "friendly",
			"attempted": true,
			"gift":      true,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["religion.beogh_resurrected"].Set(
		orc,
		map[string]any{
			"created_aut": int64(0),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := g.levels[position.LevelID]

	for _, offset := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		x := position.X + offset.x
		y := position.Y + offset.y

		if !level.Walkable(x, y) {
			continue
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			continue
		}

		if err := level.PlaceActor(orc, x, y); err != nil {
			t.Fatal(err)
		}

		return orc
	}

	t.Fatal("player has no free adjacent follower cell")

	return 0
}

// The ordinary game must discover Lua ability files, carry a selected
// command through the generic bridge, and restore its ECS worship state.
func TestBeoghAbilitiesReachGameCommandBridge(t *testing.T) {
	g := newBeoghAbilityGame(t, 2049)
	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("player has no MP component")
	}

	magic.Max = 20
	magic.Current = 20

	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_BEOGH_RECALL_ORCISH_FOLLOWERS",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("Recall spent %d aut, want one turn", result.Spent)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if worshipGod(t, restored) != "GOD_BEOGH" {
		t.Fatal("restored game lost Beogh worship")
	}
}

// Smiting aims through the ordinary ability command and registered spell
// effect. An empty visible cell still commits the source action.
func TestBeoghSmitingUsesGameCommandBridge(t *testing.T) {
	g := newBeoghAbilityGame(t, 2057)
	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("player has no MP component")
	}

	magic.Max = 20
	magic.Current = 20

	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := g.levels[position.LevelID]
	var aim point
	chosen := false

	for _, offset := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		if level.Walkable(position.X+offset.x,
			position.Y+offset.y) {
			aim = offset
			chosen = true

			break
		}
	}

	if !chosen {
		t.Fatal("player has no adjacent aim cell")
	}

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_BEOGH_SMITING",
		DX:        aim.x,
		DY:        aim.y,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("Smiting spent %d aut, want one turn", result.Spent)
	}
}

// A selected corpse crosses the Go selection and confirmation protocol,
// then the Lua monster factory creates a saved companion on the grid.
func TestBeoghResurrectionSurvivesGameRestore(t *testing.T) {
	g := newBeoghAbilityGame(t, 2051)

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no grid position")
	}

	body := testCorpseAt(t, g, "CORPSE_BODY", *position)
	ordinary, _ := g.stores.Corpses.Get(body)

	ordinary.MonsterID = "MONS_ORC"

	_, err := g.scripts.Components()["religion.beogh_corpse"].Set(
		body,
		map[string]any{
			"kind_id":     "MONS_ORC",
			"max_hp":      int64(30),
			"speed":       int64(10),
			"hit_dice":    int64(1),
			"custom_name": "Burguk",
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_BEOGH_RESURRECTION",
	}

	first, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if first.Spent != 0 || first.Selection == nil {
		t.Fatalf("corpse selection = %+v", first)
	}

	if len(first.Selection.Options) != 1 {
		t.Fatalf("corpse selection = %+v", first)
	}

	command.TargetID = first.Selection.Options[0].ID

	second, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if second.Spent != 0 || second.Confirmation == "" {
		t.Fatalf("resurrection confirmation = %+v", second)
	}

	command.Forced = true

	third, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if third.Spent != 10 || g.world.EntityExists(body) {
		t.Fatalf("resurrection spent %d, corpse exists %t",
			third.Spent, g.world.EntityExists(body))
	}

	created := g.scripts.Components()["religion.beogh_resurrected"].Entities()

	if len(created) != 1 {
		t.Fatalf("resurrected actors = %d, want one", len(created))
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if len(restored.scripts.Components()["religion.beogh_resurrected"].Entities()) != 1 {
		t.Fatal("restored game lost resurrected follower")
	}
}

// A named follower and a real inventory item cross both selections.
// The item entity remains owned by the orc after save and restore.
func TestBeoghGiftItemSurvivesGameRestore(t *testing.T) {
	g := newBeoghAbilityGame(t, 2053)
	orc := namedBeoghFollower(t, g)

	item := addCarriedArmour(t, g, "ARM_SCALE_MAIL")
	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_BEOGH_GIFT_ITEM",
	}

	first, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if first.Spent != 0 || first.Selection == nil {
		t.Fatalf("follower selection = %+v", first)
	}

	if len(first.Selection.Options) != 1 {
		t.Fatalf("follower selection = %+v", first)
	}

	if first.Selection.Options[0].ID !=
		strconv.FormatUint(uint64(orc), 10) {
		t.Fatalf("follower selection = %+v", first)
	}

	command.TargetID = first.Selection.Options[0].ID

	second, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if second.Spent != 0 || second.Selection == nil {
		t.Fatalf("item selection = %+v", second)
	}

	choiceRestored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	if !choiceRestored.scripts.Components()["religion.beogh_gift_choice"].Has(choiceRestored.player) {
		t.Fatal("restored game lost the pending follower choice")
	}

	choiceRestored.Close()

	command.TargetID = strconv.FormatUint(uint64(item), 10)

	third, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	carrier, found := g.stores.CarriedBy.Get(item)

	if !found {
		t.Fatal("gift item has no carrier")
	}

	if third.Spent != 10 || carrier.Holder != orc {
		t.Fatalf("gift spent %d, carrier %+v", third.Spent, carrier)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	restoredCarrier, found := restored.stores.CarriedBy.Get(item)

	if !found || restoredCarrier.Holder != orc {
		t.Fatal("restored game lost the follower's gift item")
	}
}
