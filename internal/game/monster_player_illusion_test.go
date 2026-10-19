package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// A live Mara cast snapshots the player into an independently saved actor.
// Restoring the game must retain that snapshot and its ordinary AI turn.
func TestMaraPlayerIllusionCastAndRestore(t *testing.T) {
	game, caster, rules := moddedEndoplasmGame(t,
		"testdata/player-illusion")
	actor, found := game.stores.Actors.Get(caster)

	if !found {
		t.Fatal("generated caster has no actor")
	}

	actor.KindID = "MONS_MARA"

	player, _ := game.stores.Players.Get(game.player)

	player.Name = "Mirror Hero"

	durations, _ := game.stores.Durations.Get(game.player)

	durations.HasteAut = 30
	durations.MightAut = 20

	_, err := game.scripts.Components()["zap.player_confusion"].Set(
		game.player,
		map[string]any{
			"remaining_aut": int64(40),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	if game.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("Mara intent = %d, want spell",
			game.turn.ResolvedIntent)
	}

	profiles := game.scripts.Components()["magic.player_illusion"]

	if profiles == nil {
		t.Fatal("player illusion schema not registered")
	}

	illusions := profiles.Entities()

	if len(illusions) != 1 {
		t.Fatalf("Mara made %d player illusions, want one",
			len(illusions))
	}

	copy := illusions[0]
	profile, found := profiles.Get(copy)

	if !found {
		t.Fatal("illusion has no saved profile")
	}

	name, _ := profile.Get("name")
	damage, _ := profile.Get("damage")

	if name != "Mirror Hero" || damage.(int64) <= 5 {
		t.Fatalf("illusion profile name=%v damage=%v",
			name, damage)
	}

	boons := game.scripts.Components()["combat.monster_boons"]
	status, found := boons.Get(copy)

	if !found {
		t.Fatal("illusion lost copied internal durations")
	}

	haste, _ := status.Get("haste_aut")
	might, _ := status.Get("might_aut")

	if haste != int64(30) || might != int64(20) {
		t.Fatalf("illusion boons haste=%v might=%v",
			haste, might)
	}

	confused := game.scripts.Components()["magic.monster_confusion"]
	confusion, found := confused.Get(copy)

	if !found {
		t.Fatal("illusion lost copied confusion")
	}

	remaining, _ := confusion.Get("remaining_aut")

	if remaining != int64(40) {
		t.Fatalf("illusion confusion=%v, want 40", remaining)
	}

	// The copied body is frozen at cast time even if the player changes.
	player.Name = "Changed Hero"

	unchanged, _ := profile.Get("name")

	if unchanged != "Mirror Hero" {
		t.Fatal("player rename changed existing illusion")
	}

	player.Name = "Mirror Hero"

	copyActor, found := game.stores.Actors.Get(copy)

	if !found || copyActor.KindID != "MONS_PLAYER_ILLUSION" {
		t.Fatal("illusion lacks player-illusion actor kind")
	}

	if _, placed := game.stores.Positions.Get(copy); !placed {
		t.Fatal("illusion lacks grid position")
	}

	// The generated Dungeon roster still owns the original endoplasm.
	actor.KindID = "MONS_ENDOPLASM"

	if err := game.scheduler.Spend(caster, ecs.Intent{
		Kind: game.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	before := game.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("player illusion profile changed during restore")
	}

	assertSupportContinuation(t, game, loaded, caster)
}
