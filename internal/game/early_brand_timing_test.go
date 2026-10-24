package game

import (
	"testing"

	"crawl/internal/ecs"
)

func TestSpeedBrandReducesMonsterMeleeEnergyCost(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	monster := ratID(t, g)
	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_SPEED"

	energy, _ := g.stores.MonsterEnergy.Get(monster)

	energy.Points = 80

	if err := g.scheduler.Spend(monster, ecs.Intent{
		Kind: ecs.IntentMelee,
	}); err != nil {
		t.Fatal(err)
	}

	if energy.Points != 73 && energy.Points != 74 {
		t.Fatalf("speed brand left %d energy, want 73 or 74", energy.Points)
	}
}

func TestSpeedBrandDoesNotAccelerateThrownMissile(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	monster := ratID(t, g)
	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_SPEED"

	missileID := giveTestMonsterItem(t, g, monster, "MI_STONE", "missile", 4)
	energy, _ := g.stores.MonsterEnergy.Get(monster)

	energy.Points = 80

	if err := g.scheduler.Spend(monster, ecs.Intent{
		Kind:   ecs.IntentRanged,
		ItemID: missileID,
	}); err != nil {
		t.Fatal(err)
	}

	if energy.Points != 70 {
		t.Fatalf("thrown missile left %d energy, want 70", energy.Points)
	}
}

// Source Speed changes a launcher shot's monster energy cost, while the
// thrown-missile test above proves the same brand does not alter a throw.
func TestSpeedBrandAcceleratesMonsterLauncher(t *testing.T) {
	g := newStepGame(t)
	monster := ratID(t, g)
	launcherID := giveTestMonsterItem(t, g, monster,
		"WPN_SLING", "weapon", 1)
	launcher, _ := g.stores.Items.Get(launcherID)
	energy, _ := g.stores.MonsterEnergy.Get(monster)

	launcher.Ego = "SPWPN_SPEED"
	energy.Points = 80

	if err := g.scheduler.Spend(monster, ecs.Intent{
		Kind:   ecs.IntentRanged,
		ItemID: launcherID,
	}); err != nil {
		t.Fatal(err)
	}

	if energy.Points != 73 && energy.Points != 74 {
		t.Fatalf("speed launcher left %d energy, want 73 or 74",
			energy.Points)
	}
}
