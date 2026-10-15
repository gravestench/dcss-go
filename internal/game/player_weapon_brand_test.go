package game

import (
	"reflect"
	"strings"
	"testing"

	"github.com/gravestench/akara"
)

func playerMeleeWeapon(t *testing.T, g *Game) akara.Entity {
	t.Helper()

	for _, entity := range g.stores.Equipped.Entities() {
		equipped, found := g.stores.Equipped.Get(entity)
		carrier, carried := g.stores.CarriedBy.Get(entity)

		if found &&
			carried &&
			equipped.Slot == "weapon" &&
			carrier.Holder == g.player {
			return entity
		}
	}

	t.Fatal("player has no wielded weapon")

	return 0
}

func TestFlamingPlayerMeleeUsesLuaBrand(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	weaponID := playerMeleeWeapon(t, g)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_FLAMING"

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Max = 1000
	ratHealth.Current = 1000

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Max = 1000
	playerHealth.Current = 1000

	for attempt := 0; attempt < 60; attempt++ {
		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "burns the rat") {
				return
			}
		}
	}

	t.Fatal("flaming player weapon never burned a rat")
}

func TestChaosKnightStartingWeaponCanStrike(t *testing.T) {
	g, err := newScenario(7, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_CHAOS_KNIGHT",
	}, "WPN_HAND_AXE", "Chaos Tester", ordinaryMonsterScenarioID)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Max = 1000
	health.Current = 1000

	for attempt := 0; attempt < 50; attempt++ {
		_, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		if err != nil {
			t.Fatalf("chaos weapon attack %d: %v", attempt, err)
		}
	}
}

func TestSpeedBrandShortensPlayerMeleeTurn(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	weapon, _ := g.stores.Items.Get(playerMeleeWeapon(t, g))

	weapon.Ego = "SPWPN_SPEED"

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent < 7 || result.Spent > 9 {
		t.Fatalf("speed branded rapier spent %d aut, want 7-9", result.Spent)
	}
}

func TestProtectionBrandAddsFiveACWhileWielded(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	baseline := g.View().PlayerAC
	weapon, _ := g.stores.Items.Get(playerMeleeWeapon(t, g))

	weapon.Ego = "SPWPN_PROTECTION"

	if got := g.View().PlayerAC; got != baseline+5 {
		t.Fatalf("protection brand AC = %d, want %d", got, baseline+5)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if got := restored.View().PlayerAC; got != baseline+5 {
		t.Fatalf("restored protection AC = %d, want %d", got, baseline+5)
	}

	weapon.Ego = ""

	if got := g.View().PlayerAC; got != baseline {
		t.Fatalf("unbranded weapon AC = %d, want %d", got, baseline)
	}
}

func TestSpectralPlayerWeaponCreatesSavedCommandedAlly(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	weaponID := equipPlayerLauncher(t, g, "WPN_CLUB")
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_SPECTRAL"

	ratID(t, g)

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	var spectral akara.Entity

	for _, entity := range g.stores.Actors.Entities() {
		actor, _ := g.stores.Actors.Get(entity)

		if actor.KindID == "MONS_SPECTRAL_WEAPON" {
			spectral = entity
		}
	}

	if spectral == 0 {
		t.Fatalf("spectral brand made no ally: %+v", result.Events)
	}

	var struck bool

	for _, event := range result.Events {
		if strings.Contains(event.Text, "spectral weapon") &&
			strings.Contains(event.Text, "rat") {
			struck = true
		}
	}

	if !struck {
		t.Fatalf("spectral ally did not strike on command: %+v", result.Events)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("spectral ally changed across save and restore")
	}

	left, leftErr := g.Step(Command{Kind: CommandWait})
	right, rightErr := restored.Step(Command{Kind: CommandWait})

	if leftErr != nil {
		t.Fatal(leftErr)
	}

	if rightErr != nil {
		t.Fatal(rightErr)
	}

	if !reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatalf("spectral wait diverged after restore: %v / %v",
			leftErr, rightErr)
	}

	if g.world.EntityExists(spectral) {
		t.Fatal("uncommanded spectral weapon did not fade")
	}
}

func TestLethalBaseHitSkipsVenomAfterDeath(t *testing.T) {
	g, err := NewScenario(7, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	weapon, _ := g.stores.Items.Get(playerMeleeWeapon(t, g))

	weapon.Ego = "SPWPN_VENOM"

	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 1

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if g.world.EntityExists(rat) {
		t.Fatal("source lethal bump did not kill the rat")
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "poisoned") {
			t.Fatal("venom poisoned a rat killed by base damage")
		}
	}
}
