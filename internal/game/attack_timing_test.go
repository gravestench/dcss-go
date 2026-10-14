package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestAttackDelayProjectionUsesEveryFighterStart(t *testing.T) {
	for _, weaponID := range []string{"WPN_RAPIER", "WPN_FLAIL", "WPN_WAR_AXE", "WPN_TRIDENT", "WPN_LONG_SWORD", "WPN_UNARMED"} {
		t.Run(weaponID, func(t *testing.T) {
			catalog := testCatalog(t)
			g, err := NewScenario(2, catalog, weaponID, "Tester")
			if err != nil {
				t.Fatal(err)
			}
			defer g.Close()
			in, err := g.playerAttackDelayInput("MONS_RAT")
			if err != nil {
				t.Fatal(err)
			}
			if in.WeaponSkill10 != 20 || in.ShieldsSkill10 != 30 || in.ShieldEV != -50 {
				t.Fatalf("attack delay input = %+v", in)
			}
			if weaponID == "WPN_UNARMED" {
				if !in.Unarmed || in.WeaponSpeed != 0 || in.WeaponSkillID != "SK_UNARMED_COMBAT" {
					t.Fatalf("unarmed attack delay = %+v", in)
				}
				return
			}
			weapon, err := catalog.Item(weaponID)
			if err != nil {
				t.Fatal(err)
			}
			if in.Unarmed || in.WeaponSpeed != weapon.Weapon.Speed || in.WeaponSkillID != weapon.Weapon.SkillID {
				t.Fatalf("%s delay = %+v, catalog %+v", weaponID, in, weapon.Weapon)
			}
		})
	}
}

func TestRapierBumpCostSchedulesTwoRatActions(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}
	health, _ := g.stores.Health.Get(rat)
	health.Current, health.Max = 100, 100
	result, err := g.Step(Command{Kind: CommandMove, DX: 1})
	if err != nil {
		t.Fatal(err)
	}
	if result.Spent != 11 && result.Spent != 12 {
		t.Fatalf("rapier bump cost = %d, want 11 or 12", result.Spent)
	}
	if result.View.CurrentAut != result.Spent {
		t.Fatalf("view time %d differs from spent %d", result.View.CurrentAut, result.Spent)
	}
	actor, _ := g.stores.Actors.Get(rat)
	if actor.NextAut != 20 {
		t.Fatalf("rat deadline = %d, want 20", actor.NextAut)
	}
}

func TestShortUnarmedBumpSchedulesOnlyOneRatAction(t *testing.T) {
	var seed uint64
	for candidate := uint64(1); candidate < 10000; candidate++ {
		roll, err := NewRNGStreams(candidate).Intn("melee", 10800)
		if err != nil {
			t.Fatal(err)
		}
		if roll < 2400 {
			seed = candidate
			break
		}
	}
	if seed == 0 {
		t.Fatal("no seed yielded a 9-aut unarmed attack")
	}
	g, err := NewScenario(seed, testCatalog(t), "WPN_UNARMED", "Tester")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()
	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)
	health.Current, health.Max = 100, 100
	result, err := g.Step(Command{Kind: CommandMove, DX: 1})
	if err != nil || result.Spent != 9 || result.View.CurrentAut != 9 {
		t.Fatalf("unarmed bump = %+v, %v", result, err)
	}
	playerActor, _ := g.stores.Actors.Get(g.player)
	ratActor, _ := g.stores.Actors.Get(rat)
	if playerActor.NextAut != 9 || ratActor.NextAut != 10 {
		t.Fatalf("player deadline %d, rat deadline %d; want 9 and 10", playerActor.NextAut, ratActor.NextAut)
	}
}

func TestBumpRejectsMissingShieldBeforeTimingDraw(t *testing.T) {
	g := newStepGame(t)
	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}
	for _, entity := range g.stores.Equipped.Entities() {
		equipped, _ := g.stores.Equipped.Get(entity)
		if equipped.Slot == "shield" {
			g.stores.Equipped.Remove(entity)
		}
	}
	before := g.Snapshot()
	if _, err := g.Step(Command{Kind: CommandMove, DX: 1}); err == nil {
		t.Fatal("bump accepted missing shield")
	}
	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("failed bump changed state or melee RNG")
	}
}

func TestAttackDelaySaveContinuation(t *testing.T) {
	g := newStepGame(t)
	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)
	health.Current = health.Max
	loaded, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	command := Command{Kind: CommandMove, DX: 1}
	left, leftErr := g.Step(command)
	right, rightErr := loaded.Step(command)
	if leftErr != nil || rightErr != nil || !reflect.DeepEqual(left, right) || !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("attack timing continuation: %+v/%v versus %+v/%v", left, leftErr, right, rightErr)
	}
}

func TestRestoreRejectsMissingTimingEquipment(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	bad := g.Snapshot()
	for i := range bad.Entities {
		if bad.Entities[i].Equipped != nil && bad.Entities[i].Equipped.Slot == "shield" {
			bad.Entities[i].Equipped = nil
			bad.Entities[i].CarriedBy = &ecs.CarriedBy{Holder: g.player}
		}
	}
	if restored, err := g.Restore(bad); err == nil {
		restored.Close()
		t.Fatal("missing timing equipment restored")
	}
	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("failed restore changed live game")
	}
}
