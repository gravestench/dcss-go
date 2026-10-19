package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A real monster decision selects an overlaid summon book, creates Akara
// actors through Lua, and keeps ownership and RNG continuation on reload.
func TestMonsterDirectSummonsBookCastAndSave(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-direct-summons")
	placePlayerInSlugLine(t, g, caster)

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("resolved intent = %d, want summon spell",
			g.turn.ResolvedIntent)
	}

	store := g.scripts.Components()["magic.summon"]

	if len(store.Entities()) == 0 {
		t.Fatal("monster spell did not create an Akara summon")
	}

	for _, creature := range store.Entities() {
		state, _ := store.Get(creature)
		owner, _ := state.Get("owner")
		source, _ := state.Get("source_id")
		attitude, _ := state.Get("attitude")
		expiry, _ := state.Get("expires_aut")

		if owner != caster ||
			source != "SPELL_SUMMON_SMALL_MAMMAL" ||
			attitude != "hostile" ||
			expiry.(int64) <= int64(g.currentAut) {
			t.Fatalf("invalid monster summon: owner=%v source=%v attitude=%v expiry=%v",
				owner, source, attitude, expiry)
		}

		if _, positioned := g.stores.Positions.Get(creature); !positioned {
			t.Fatal("monster summon has no spatial position")
		}
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("monster summon changed on save restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}

// Forceful Invitation chooses a branch once per monster. Its caster-owned
// component and subsequent source draw must survive save/restore unchanged.
func TestMonsterDirectSummonsInvitationPersists(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-invitation")
	placePlayerInSlugLine(t, g, caster)

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	state, found := g.scripts.Components()["magic.monster_invitation"].Get(caster)

	if !found {
		t.Fatal("Invitation did not save its selected branch on the caster")
	}

	branch, _ := state.Get("branch_id")

	if branch == "" {
		t.Fatal("Invitation saved an empty branch ID")
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("Invitation branch or summons changed on save restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}

// The source removes a dead monster's summons before deleting their owner.
// A save after that death must not contain an orphan entity reference.
func TestMonsterDirectSummonsCasterDeathRestores(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-direct-summons")
	placePlayerInSlugLine(t, g, caster)

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if len(g.scripts.Components()["magic.summon"].Entities()) == 0 {
		t.Fatal("caster made no summon before dying")
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(caster)

	health.Current = 0

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if len(g.scripts.Components()["magic.summon"].Entities()) != 0 {
		t.Fatal("dead caster left owned summons")
	}

	before := g.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("dead-caster cleanup changed on restore")
	}
}

// A mod adds its own spell declaration, book slot, and effect path. The live
// monster cast must find all three through the layered Lua tree without a
// bundled registry edit or Go spell switch.
func TestMonsterDirectSummonsModAddedSpell(t *testing.T) {
	g, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-added-summon")
	placePlayerInSlugLine(t, g, caster)

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	events, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("resolved intent = %d, want mod spell",
			g.turn.ResolvedIntent)
	}

	message := false

	for _, event := range events {
		if strings.Contains(event.Text, "A modded rat answers the call.") {
			message = true
		}
	}

	if !message {
		t.Fatalf("modded effect did not emit its message: %+v", events)
	}

	store := g.scripts.Components()["magic.summon"]

	if len(store.Entities()) != 1 {
		t.Fatalf("modded spell made %d summons, want one",
			len(store.Entities()))
	}

	state, _ := store.Get(store.Entities()[0])
	source, _ := state.Get("source_id")

	if source != "SPELL_MOSS_HELPER" {
		t.Fatalf("modded summon source = %v", source)
	}
}
