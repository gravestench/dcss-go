package game

import (
	"testing"

	"dcrawl-go/internal/modfs"
)

func TestChaosCloneIsSavedAsAnAdditionalMonster(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, "WPN_RAPIER", "Tester", ordinaryMonsterScenarioID, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	before := len(g.stores.Actors.Entities())

	if _, err := g.scripts.Policy("test.chaos_clone", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if got := len(g.stores.Actors.Entities()); got != before+1 {
		t.Fatalf("chaos clone created %d extra actors, want 1", got-before)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if got := len(loaded.stores.Actors.Entities()); got != before+1 {
		t.Fatalf("restored chaos clone actors = %d, want %d", got, before+1)
	}
}

func TestChaosMonsterHasteSurvivesSave(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, "WPN_RAPIER", "Tester", ordinaryMonsterScenarioID, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	rat := ratID(t, g)

	if _, err := g.scripts.Policy("test.chaos_haste", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if !g.scripts.Components()["combat.monster_chaos"].Has(rat) {
		t.Fatal("chaos haste did not attach to the monster")
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["combat.monster_chaos"].Has(rat) {
		t.Fatal("restore lost chaos haste")
	}
}

func TestGeneratedDungeonChaosCloneRestores(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(41, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	before := len(g.stores.Actors.Entities())

	if _, err := g.scripts.Policy("test.chaos_clone", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if got := len(g.stores.Actors.Entities()); got != before+1 {
		t.Fatalf("chaos clone added %d actors, want 1", got-before)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}

func TestGeneratedDungeonNettedMonsterBanishmentRestores(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(41, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Policy("test.banish_netted", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}

func TestSummonedChaosCloneKeepsExpiryAndRestores(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(41, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Policy("test.clone_summon", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	clones := g.scripts.Components()["combat.chaos_clone"]
	summons := g.scripts.Components()["magic.summon"]
	count := 0

	for _, entity := range g.stores.Actors.Entities() {
		if clones.Has(entity) {
			count++

			if !summons.Has(entity) {
				t.Fatal("chaos clone of a summon lost its expiry")
			}
		}
	}

	if count != 1 {
		t.Fatalf("summoned chaos clones = %d, want 1", count)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}

func TestSpectralWeaponDamageSharesWithPlayerNonlethally(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, "WPN_RAPIER", "Tester", ordinaryMonsterScenarioID, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	weaponID := equipPlayerLauncher(t, g, "WPN_CLUB")
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_SPECTRAL"

	if _, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	}); err != nil {
		t.Fatal(err)
	}

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 20

	if _, err := g.scripts.Policy("test.damage_spectral", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if playerHealth.Current != 16 {
		t.Fatalf("spectral backlash left player at %d HP, want 16",
			playerHealth.Current)
	}

	playerHealth.Current = 1

	if _, err := g.scripts.Policy("test.damage_spectral", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if playerHealth.Current != 1 {
		t.Fatalf("spectral backlash killed its owner at %d HP",
			playerHealth.Current)
	}
}

func TestBanishedJackalFollowerRestoresWithoutCrossLevelLink(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	var g *Game

	for seed := uint64(1); seed <= 64; seed++ {
		candidate, err := newScenarioWithRules(seed, startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		}, "WPN_RAPIER", "Tester", populationScenarioID, rules)

		if err != nil {
			t.Fatal(err)
		}

		if len(candidate.stores.Followers.Entities()) > 0 {
			g = candidate

			break
		}

		_ = candidate.Close()
	}

	if g == nil {
		t.Fatal("no jackal band appeared in 64 seeded populations")
	}

	defer g.Close()

	if _, err := g.scripts.Policy("test.banish_follower", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}

func TestSlowedChaosCloneKeepsSpeedStateAcrossRestore(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, "WPN_RAPIER", "Tester", ordinaryMonsterScenarioID, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Policy("test.clone_slowed", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	clones := g.scripts.Components()["combat.chaos_clone"]
	slowed := g.scripts.Components()["projectile.slow"]
	count := 0

	for _, entity := range g.stores.Actors.Entities() {
		if clones.Has(entity) {
			count++

			if !slowed.Has(entity) {
				t.Fatal("slowed chaos clone lost its speed state")
			}
		}
	}

	if count != 1 {
		t.Fatalf("slowed chaos clones = %d, want 1", count)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}

func TestGeneratedDungeonChaosCloneKillXPStillRestores(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(41, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	for _, policy := range []string{
		"test.chaos_clone",
		"test.kill_clone",
	} {
		if _, err := g.scripts.Policy(policy, nil); err != nil {
			t.Fatal(err)
		}

		if err := g.scripts.ApplyPending(); err != nil {
			t.Fatal(err)
		}
	}

	g.turn.Actor = g.player
	updateLuaSystem(t, g, "actor.death", 10)

	if !g.scripts.Components()["combat.chaos_clone_rewards"].Has(g.player) {
		t.Fatal("clone kill did not record its extra XP")
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}

func TestChaosCloneDuplicatesMonsterEquipment(t *testing.T) {
	rules, err := modfs.Load("testdata/chaos-clone-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, "WPN_RAPIER", "Tester", ordinaryMonsterScenarioID, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Policy("test.clone_geared", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	clones := g.scripts.Components()["combat.chaos_clone"]
	copyFound := false

	for _, entity := range g.stores.CarriedBy.Entities() {
		carrier, _ := g.stores.CarriedBy.Get(entity)

		if clones.Has(carrier.Holder) {
			item, _ := g.stores.Items.Get(entity)
			copyFound = item.KindID == "WPN_DAGGER"
		}
	}

	if !copyFound {
		t.Fatal("chaos clone did not duplicate the source weapon")
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}
