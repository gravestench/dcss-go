package game

import (
	"reflect"
	"slices"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

func givePlayerProjectileItem(
	t *testing.T,
	g *Game,
	kindID string,
	quantity int,
	slot string,
) akara.Entity {
	t.Helper()

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(entity, ecs.Item{
		KindID:   kindID,
		Quantity: quantity,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.CarriedBy.Set(entity, ecs.CarriedBy{
		Holder: g.player,
	}); err != nil {
		t.Fatal(err)
	}

	if slot != "" {
		if _, err := g.stores.Equipped.Set(entity, ecs.Equipped{
			Slot: slot,
		}); err != nil {
			t.Fatal(err)
		}
	}

	return entity
}

func TestRangedEquipmentAndThrownStackSurviveSave(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	equipPlayerLauncher(t, g, "WPN_SLING")
	givePlayerProjectileItem(t, g, "MI_BOOMERANG", 2, "")

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("projectile equipment changed after restore")
	}
}

func equipPlayerLauncher(t *testing.T, g *Game, kindID string) akara.Entity {
	t.Helper()

	for _, entity := range g.stores.Equipped.Entities() {
		carrier, found := g.stores.CarriedBy.Get(entity)

		if found && carrier.Holder == g.player {
			g.stores.Equipped.Remove(entity)
		}
	}

	return givePlayerProjectileItem(t, g, kindID, 1, "weapon")
}

func TestPlayerFiresWieldedLauncherThroughRangedIntent(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	equipPlayerLauncher(t, g, "WPN_SLING")
	result, err := g.Step(Command{
		Kind: CommandFire,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent <= 0 {
		t.Fatalf("firing did not spend time: %+v", result)
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "shoot") {
			return
		}
	}

	t.Fatalf("firing had no shot event: %+v", result.Events)
}

// A source-legal Acid launcher uses the ordinary player firing command and
// keeps its equipped brand after the resulting turn is saved and restored.
func TestAcidLauncherShotSurvivesSaveRestore(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)
	originalMax := ratHealth.Max

	ratHealth.Current = 1000
	ratHealth.Max = 1000

	launcherID := equipPlayerLauncher(t, g, "WPN_SLING")
	launcher, _ := g.stores.Items.Get(launcherID)

	launcher.Ego = "SPWPN_ACID"

	splashed := false

	for attempt := 0; attempt < 20 && !splashed; attempt++ {
		result, err := g.Step(Command{
			Kind: CommandFire,
			DX:   1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent <= 0 {
			t.Fatal("Acid launcher shot did not spend a turn")
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "rat is splashed with acid") {
				splashed = true
			}
		}
	}

	if !splashed {
		t.Fatal("Acid launcher never splashed its struck target")
	}

	// Restore source-valid rat HP before asking the save validator to load it.
	ratHealth, _ = g.stores.Health.Get(rat)
	ratHealth.Max = originalMax
	ratHealth.Current = min(ratHealth.Current, originalMax)

	before := g.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("Acid launcher turn changed across save restore")
	}
}

// Melee-only brands on a saved launcher must be rejected before the player
// spends time or changes the live ECS state.
func TestInvalidLauncherBrandDoesNotSpendTurn(t *testing.T) {
	g := newStepGame(t)
	launcherID := equipPlayerLauncher(t, g, "WPN_SLING")
	launcher, _ := g.stores.Items.Get(launcherID)

	launcher.Ego = "SPWPN_VAMPIRISM"

	before := g.Snapshot()
	_, err := g.Step(Command{
		Kind: CommandFire,
		DX:   1,
	})

	if err == nil {
		t.Fatal("melee-only launcher brand was accepted")
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("invalid launcher brand spent a turn")
	}
}

func TestPlayerCanFireEveryImportedLauncherFamily(t *testing.T) {
	launchers := []string{
		"WPN_BLOWGUN",
		"WPN_ARBALEST",
		"WPN_HAND_CROSSBOW",
		"WPN_TRIPLE_CROSSBOW",
		"WPN_SHORTBOW",
		"WPN_LONGBOW",
		"WPN_SLING",
		"WPN_FUSTIBALUS",
	}

	for _, kindID := range launchers {
		t.Run(kindID, func(t *testing.T) {
			g := newStepGame(t)
			equipPlayerLauncher(t, g, kindID)

			result, err := g.Step(Command{
				Kind: CommandFire,
				DX:   1,
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent <= 0 {
				t.Fatalf("%s shot spent no time: %+v", kindID, result)
			}

			fired := false

			for _, event := range result.Events {
				fired = fired || strings.Contains(event.Text, "shoot")
			}

			if !fired {
				t.Fatalf("%s made no shot: %+v", kindID, result.Events)
			}
		})
	}
}

func TestPlayerShotContactsFirstMonsterOnRay(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	equipPlayerLauncher(t, g, "WPN_SLING")
	result, err := g.Step(Command{
		Kind: CommandFire,
		DX:   2,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent <= 0 {
		t.Fatal("a monster between the player and aim cell blocked firing")
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "rat") {
			return
		}
	}

	t.Fatalf("shot did not resolve against the first monster: %+v", result.Events)
}

func TestPlayerThrowConsumesOneMissileFromStack(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	stoneID := givePlayerProjectileItem(t, g, "MI_STONE", 3, "")
	result, err := g.Step(Command{
		Kind:   CommandThrow,
		DX:     1,
		ItemID: uint64(stoneID),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent <= 0 {
		t.Fatalf("throwing did not spend time: %+v", result)
	}

	stone, found := g.stores.Items.Get(stoneID)

	if !found || stone.Quantity != 2 {
		t.Fatalf("throwing left stack %+v, found=%v", stone, found)
	}
}

func TestThrownBoomerangPracticesWithoutHitting(t *testing.T) {
	g := newStepGame(t)
	boomerangID := givePlayerProjectileItem(t, g, "MI_BOOMERANG", 1, "")

	result, err := g.Step(Command{
		Kind:   CommandThrow,
		DX:     1,
		ItemID: uint64(boomerangID),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent <= 0 {
		t.Fatalf("throw spent no time: %+v", result)
	}

	training, _ := g.stores.SkillTraining.Get(g.player)

	if !slices.Contains(training.RecentAll, "SK_THROWING") {
		t.Fatalf("missed throw did not practice Throwing: %+v", training.RecentAll)
	}

	boomerang, found := g.stores.Items.Get(boomerangID)

	if !found || boomerang.Quantity != 1 {
		t.Fatalf("returning boomerang changed stack: %+v, found=%v", boomerang, found)
	}
}

func TestSmallPlayerCannotThrowJavelinOrLargeRock(t *testing.T) {
	for _, kindID := range []string{
		"MI_JAVELIN",
		"MI_LARGE_ROCK",
	} {
		t.Run(kindID, func(t *testing.T) {
			g := newStepGame(t)
			player, _ := g.stores.Players.Get(g.player)

			player.SpeciesID = "SP_SPRIGGAN"

			if _, err := g.stores.Players.Set(g.player, *player); err != nil {
				t.Fatal(err)
			}

			missileID := givePlayerProjectileItem(t, g, kindID, 1, "")
			before := g.currentAut

			result, err := g.Step(Command{
				Kind:   CommandThrow,
				DX:     1,
				ItemID: uint64(missileID),
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent != 0 || g.currentAut != before {
				t.Fatalf("invalid throw spent %d aut", result.Spent)
			}

			missile, found := g.stores.Items.Get(missileID)

			if !found || missile.Quantity != 1 {
				t.Fatalf("invalid throw changed stack: %+v, found=%v", missile, found)
			}
		})
	}
}

func TestThrownNetCatchesMonsterAndSavesHeldState(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			g.Close()
			t.Fatal(err)
		}

		netID := givePlayerProjectileItem(t, g, "MI_THROWING_NET", 1, "")
		result, err := g.Step(Command{
			Kind:   CommandThrow,
			DX:     1,
			ItemID: uint64(netID),
		})

		if err != nil {
			g.Close()
			t.Fatal(err)
		}

		caught := false

		for _, event := range result.Events {
			caught = caught || strings.Contains(event.Text, "caught in the net")
		}

		if !caught {
			g.Close()
			continue
		}

		snapshot := g.Snapshot()
		heldSaved := false
		netSaved := false

		for _, record := range snapshot.Entities {
			for _, component := range record.Dynamic {
				heldSaved = heldSaved || component.Schema == "projectile.held"
				netSaved = netSaved || component.Schema == "projectile.net"
			}
		}

		if !heldSaved || !netSaved {
			g.Close()
			t.Fatalf("caught net missing from save: held=%v net=%v", heldSaved, netSaved)
		}

		loaded, err := Restore(snapshot)
		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		defer loaded.Close()

		if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
			t.Fatal("held net state changed on restore")
		}

		heldStore := loaded.scripts.Components()["projectile.held"]
		escaped := false

		for turn := 0; turn < 16; turn++ {
			if len(heldStore.Entities()) == 0 {
				escaped = true
				break
			}

			if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
				t.Fatal(err)
			}
		}

		if !escaped && len(heldStore.Entities()) != 0 {
			t.Fatal("caught monster never escaped the net")
		}

		return
	}

	t.Fatal("no seed caught the rat in a net")
}

func TestFlamingLauncherAppliesLuaBrandEffect(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			g.Close()
			t.Fatal(err)
		}

		launcherID := equipPlayerLauncher(t, g, "WPN_SHORTBOW")
		launcher, _ := g.stores.Items.Get(launcherID)

		launcher.Ego = "SPWPN_FLAMING"

		if _, err := g.stores.Items.Set(launcherID, *launcher); err != nil {
			g.Close()
			t.Fatal(err)
		}

		result, err := g.Step(Command{
			Kind: CommandFire,
			DX:   1,
		})

		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "burns the rat") {
				return
			}
		}
	}

	t.Fatal("no flaming shortbow shot applied its brand")
}

func TestPoisonedDartStoresMonsterPoisonThroughSave(t *testing.T) {
	for seed := uint64(1); seed <= 30; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			g.Close()
			t.Fatal(err)
		}

		dartID := givePlayerProjectileItem(t, g, "MI_DART", 1, "")
		dart, _ := g.stores.Items.Get(dartID)

		dart.Ego = "poisoned"

		if _, err := g.stores.Items.Set(dartID, *dart); err != nil {
			g.Close()
			t.Fatal(err)
		}

		if _, err := g.Step(Command{
			Kind:   CommandThrow,
			DX:     1,
			ItemID: uint64(dartID),
		}); err != nil {
			g.Close()
			t.Fatal(err)
		}

		snapshot := g.Snapshot()
		poisoned := false

		for _, record := range snapshot.Entities {
			for _, component := range record.Dynamic {
				poisoned = poisoned || component.Schema == "projectile.poison"
			}
		}

		if !poisoned {
			g.Close()
			continue
		}

		loaded, err := Restore(snapshot)
		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		defer loaded.Close()

		if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
			t.Fatal("monster poison state changed on restore")
		}

		return
	}

	t.Fatal("no seed poisoned the rat with a dart")
}

func TestCurareDartSlowsSurvivingMonster(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			g.Close()
			t.Fatal(err)
		}

		rat := ratID(t, g)
		health, _ := g.stores.Health.Get(rat)

		health.Current = 50
		health.Max = 50

		if _, err := g.stores.Health.Set(rat, *health); err != nil {
			g.Close()
			t.Fatal(err)
		}

		dartID := givePlayerProjectileItem(t, g, "MI_DART", 1, "")
		dart, _ := g.stores.Items.Get(dartID)

		dart.Ego = "curare"

		if _, err := g.stores.Items.Set(dartID, *dart); err != nil {
			g.Close()
			t.Fatal(err)
		}

		_, err = g.Step(Command{
			Kind:   CommandThrow,
			DX:     1,
			ItemID: uint64(dartID),
		})

		if err != nil {
			g.Close()
			t.Fatal(err)
		}

		slowStore, found := g.scripts.Components()["projectile.slow"]
		slowed := found && len(slowStore.Entities()) > 0
		g.Close()

		if slowed {
			return
		}
	}

	t.Fatal("no curare dart slowed the surviving rat")
}

func TestDispersalJavelinMovesSurvivingMonster(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			g.Close()
			t.Fatal(err)
		}

		rat := ratID(t, g)
		health, _ := g.stores.Health.Get(rat)

		health.Current = 50
		health.Max = 50

		if _, err := g.stores.Health.Set(rat, *health); err != nil {
			g.Close()
			t.Fatal(err)
		}

		javelinID := givePlayerProjectileItem(t, g, "MI_JAVELIN", 1, "")
		javelin, _ := g.stores.Items.Get(javelinID)

		javelin.Ego = "dispersal"

		if _, err := g.stores.Items.Set(javelinID, *javelin); err != nil {
			g.Close()
			t.Fatal(err)
		}

		result, err := g.Step(Command{
			Kind:   CommandThrow,
			DX:     1,
			ItemID: uint64(javelinID),
		})

		if err != nil {
			g.Close()
			t.Fatal(err)
		}

		moved := false

		for _, event := range result.Events {
			moved = moved || strings.Contains(event.Text, "blinks away")
		}

		position, found := g.stores.Positions.Get(rat)
		g.Close()

		if moved &&
			found &&
			(position.X != 4 || position.Y != 1) {
			return
		}
	}

	t.Fatal("no dispersal javelin blinked the surviving rat")
}

func TestJavelinPenetratesTwoMonstersOnItsRay(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	first := ratID(t, g)
	actor, _ := g.stores.Actors.Get(first)
	health, _ := g.stores.Health.Get(first)
	ai, _ := g.stores.AI.Get(first)
	energy, _ := g.stores.MonsterEnergy.Get(first)
	combat, _ := g.stores.Combat.Get(first)
	second, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Actors.Set(second, *actor); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(second, *health); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.AI.Set(second, *ai); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.MonsterEnergy.Set(second, *energy); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Combat.Set(second, *combat); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].PlaceActor(second, 5, 1); err != nil {
		t.Fatal(err)
	}

	javelinID := givePlayerProjectileItem(t, g, "MI_JAVELIN", 1, "")
	result, err := g.Step(Command{
		Kind:   CommandThrow,
		DX:     2,
		ItemID: uint64(javelinID),
	})

	if err != nil {
		t.Fatal(err)
	}

	contacts := 0

	for _, event := range result.Events {
		if strings.Contains(event.Text, "rat") &&
			(strings.Contains(event.Text, "hits") ||
				strings.Contains(event.Text, "misses")) {
			contacts++
		}
	}

	if contacts != 2 {
		t.Fatalf("javelin resolved %d monster contacts, want 2", contacts)
	}
}

func shieldedGoblinScenario(t *testing.T, seed uint64) *Game {
	t.Helper()
	g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		g.Close()
		t.Fatal(err)
	}

	rat := ratID(t, g)
	goblin, err := testCatalog(t).Monster("MONS_GOBLIN")

	if err != nil {
		g.Close()
		t.Fatal(err)
	}

	if _, err := g.stores.Actors.Set(rat, ecs.Actor{
		KindID: goblin.ID,
		Speed:  goblin.Speed,
	}); err != nil {
		g.Close()
		t.Fatal(err)
	}

	shieldID := giveTestMonsterItem(t, g, rat, "ARM_BUCKLER", "shield", 1)
	shield, _ := g.stores.Items.Get(shieldID)

	shield.Plus = 10

	if _, err := g.stores.Items.Set(shieldID, *shield); err != nil {
		g.Close()
		t.Fatal(err)
	}

	return g
}

func TestShieldedMonsterCanBlockPlayerShot(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g := shieldedGoblinScenario(t, seed)
		equipPlayerLauncher(t, g, "WPN_SLING")
		result, err := g.Step(Command{
			Kind: CommandFire,
			DX:   1,
		})

		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "blocks the sling bullet") {
				return
			}
		}
	}

	t.Fatal("no shielded goblin blocked a player shot")
}

func TestJavelinPiercesMonsterShield(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g := shieldedGoblinScenario(t, seed)
		javelinID := givePlayerProjectileItem(t, g, "MI_JAVELIN", 1, "")
		result, err := g.Step(Command{
			Kind:   CommandThrow,
			DX:     1,
			ItemID: uint64(javelinID),
		})

		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "blocks the javelin") {
				t.Fatal("shield blocked a penetrating javelin")
			}

			if strings.Contains(event.Text, "pierces through") {
				return
			}
		}
	}

	t.Fatal("no javelin pierced the goblin's buckler")
}
