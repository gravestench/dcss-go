package game

import (
	"strings"
	"testing"

	"crawl/internal/character"
	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

func grantZapForTest(t *testing.T, g *Game, id string) {
	t.Helper()

	store := g.scripts.Components()["character.spell"]
	var entity akara.Entity

	for _, candidate := range store.Entities() {
		record, _ := store.Get(candidate)
		owner, _ := record.Get("owner")
		spellID, _ := record.Get("spell_id")

		if owner == g.player && spellID == id {
			entity = candidate
			break
		}
	}

	if entity == 0 {
		created, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		entity = created
	}

	_, err := store.Set(entity, map[string]any{
		"owner":        g.player,
		"spell_id":     id,
		"in_library":   true,
		"known_slot":   int64(2),
		"letter_slot":  int64(2),
		"future_level": int64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 8

	magic, _ := g.stores.Magic.Get(g.player)

	magic.Current = 80
	magic.Max = 80

	skills, _ := g.stores.Skills.Get(g.player)
	trained := map[string]bool{
		"SK_CONJURATIONS": true,
		"SK_EARTH_MAGIC":  true,
		"SK_NECROMANCY":   true,
		"SK_ICE_MAGIC":    true,
		"SK_HEXES":        true,
		"SK_POISON_MAGIC": true,
		"SK_FIRE_MAGIC":   true,
		"SK_AIR_MAGIC":    true,
		"SK_SPELLCASTING": true,
	}

	for index := range skills.Entries {
		skill := &skills.Entries[index]

		if trained[skill.ID] {
			skill.Level = 27
			delete(trained, skill.ID)
		}
	}

	for id := range trained {
		skills.Entries = append(skills.Entries, character.Skill{
			ID:    id,
			Level: 27,
		})
	}

	if _, err := g.stores.Skills.Set(g.player, *skills); err != nil {
		t.Fatal(err)
	}
}

func newZapGame(t *testing.T) *Game {
	t.Helper()
	g, err := newScenario(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_CONJURER",
	}, "", "Tester", ordinaryMonsterScenarioID)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	return g
}

func TestPlayerPhysicalZapsStrikeAlongSourceRange(t *testing.T) {
	cases := []struct {
		id   string
		name string
	}{
		{
			id:   "SPELL_SANDBLAST",
			name: "blast of sand",
		},

		{
			id:   "SPELL_STONE_ARROW",
			name: "stone arrow",
		},

		{
			id:   "SPELL_IRON_SHOT",
			name: "iron shot",
		},

		{
			id:   "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
			name: "crystal spear",
		},

		{
			id:   "SPELL_THROW_FLAME",
			name: "puff of flame",
		},
	}

	for _, tc := range cases {
		t.Run(tc.id, func(t *testing.T) {
			g := newZapGame(t)
			grantZapForTest(t, g, tc.id)

			if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
				t.Fatal(err)
			}

			for attempt := 0; attempt < 6; attempt++ {
				result, err := g.Step(Command{
					Kind:    CommandForceCast,
					SpellID: tc.id,
					DX:      1,
				})

				if err != nil {
					t.Fatal(err)
				}

				if result.Spent == 0 {
					t.Fatalf("%s spent no time", tc.id)
				}

				for _, event := range result.Events {
					if strings.Contains(event.Text, tc.name) {
						return
					}
				}
			}

			t.Fatalf("%s had no projectile result after six casts", tc.id)
		})
	}
}

func TestSearingRayChannelsThreeWaitsAndChargesEachRay(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_SEARING_RAY")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SEARING_RAY",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if _, ok := g.scripts.Components()["magic.channel"].Get(g.player); !ok {
		t.Fatalf("Searing Ray did not begin channeling: %+v", result.Events)
	}

	magic, _ := g.stores.Magic.Get(g.player)
	afterCast := magic.Current

	for i := 0; i < 3; i++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		if magic.Current != afterCast-i-1 {
			t.Fatalf("wait %d MP = %d, want %d", i+1,
				magic.Current, afterCast-i-1)
		}
	}

	if _, ok := g.scripts.Components()["magic.channel"].Get(g.player); ok {
		t.Fatal("Searing Ray continued past its third wait")
	}

	if health.Current >= 500 {
		t.Fatal("Searing Ray never struck the rat")
	}
}

func TestFlameWaveExpandsOnWaitAndStopsAtMaxRadius(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_FLAME_WAVE")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_FLAME_WAVE",
	}); err != nil {
		t.Fatal(err)
	}

	if health.Current >= 500 {
		t.Fatal("initial Flame Wave did not hit the adjacent rat")
	}

	magic, _ := g.stores.Magic.Get(g.player)
	afterCast := magic.Current

	for i := 0; i < 2; i++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		if magic.Current != afterCast-i-1 {
			t.Fatalf("wave wait %d MP = %d, want %d", i+1,
				magic.Current, afterCast-i-1)
		}
	}

	if _, ok := g.scripts.Components()["magic.channel"].Get(g.player); ok {
		t.Fatal("Flame Wave continued past radius three")
	}
}

func cloudAtForTest(g *Game, x, y int, kind string) bool {
	store := g.scripts.Components()["world.cloud"]

	for _, entity := range store.Entities() {
		cloud, _ := store.Get(entity)
		cloudX, _ := cloud.Get("x")
		cloudY, _ := cloud.Get("y")
		cloudKind, _ := cloud.Get("kind_id")

		if cloudX == int64(x) &&
			cloudY == int64(y) &&
			cloudKind == kind {
			return true
		}
	}

	return false
}

func TestMephiticCloudPersistsAndConfusesMonster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_MEPHITIC_CLOUD")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 500
	playerHealth.Max = 500

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_MEPHITIC_CLOUD",
			DX:      1,
		}); err != nil {
			t.Fatal(err)
		}

		if cloudAtForTest(g, 4, 1, "CLOUD_MEPHITIC") {
			break
		}
	}

	if !cloudAtForTest(g, 4, 1, "CLOUD_MEPHITIC") {
		t.Fatal("Mephitic Cloud did not place a persistent center cloud")
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.runAction(rat, ecs.Intent{}, 10, "monster"); err != nil {
			t.Fatal(err)
		}

		if g.scripts.Components()["magic.monster_confusion"].Has(rat) {
			return
		}
	}

	t.Fatal("Mephitic Cloud never confused the rat")
}

func TestFireStormDamagesAndLeavesFireCloud(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_FIRE_STORM")
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 1000
	playerHealth.Max = 1000

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	var lastEvents []Event

	for attempt := 0; attempt < 8; attempt++ {
		result, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_FIRE_STORM",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		lastEvents = result.Events

		if cloudAtForTest(g, 4, 1, "CLOUD_FIRE") {
			break
		}
	}

	if !cloudAtForTest(g, 4, 1, "CLOUD_FIRE") {
		t.Fatalf("Fire Storm left no fire cloud at its center: %+v", lastEvents)
	}

	if health.Current >= 500 {
		t.Fatal("Fire Storm did not damage the target")
	}
}

func TestDazzlingFlashAppliesSourceLengthBlindness(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_DAZZLING_FLASH")
	rat := ratID(t, g)
	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 500
	playerHealth.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_DAZZLING_FLASH",
		}); err != nil {
			t.Fatal(err)
		}

		state, found := g.scripts.Components()["magic.monster_enchant"].Get(rat)

		if !found {
			continue
		}

		blind, err := state.Get("blind_aut")

		if err != nil {
			t.Fatal(err)
		}

		if blind.(int64) > 0 {
			return
		}
	}

	t.Fatal("Dazzling Flash never blinded the rat")
}

func TestShockBouncesFromRockButStopsAtTree(t *testing.T) {
	for _, tc := range []struct {
		name     string
		feature  terrain.ID
		contacts int
	}{
		{
			name:     "rock",
			feature:  terrain.RockWall,
			contacts: 2,
		},

		{
			name:     "tree",
			feature:  terrain.Tree,
			contacts: 1,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newZapGame(t)
			grantZapForTest(t, g, "SPELL_SHOCK")
			rat := ratID(t, g)
			health, _ := g.stores.Health.Get(rat)

			health.Current = 500
			health.Max = 500

			if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
				t.Fatal(err)
			}

			if err := g.levels[1].SetCell(6, 1, tc.feature); err != nil {
				t.Fatal(err)
			}

			result, err := g.Step(Command{
				Kind:    CommandForceCast,
				SpellID: "SPELL_SHOCK",
				DX:      1,
			})

			if err != nil {
				t.Fatal(err)
			}

			contacts := 0

			for _, event := range result.Events {
				if strings.Contains(event.Text, "zap") &&
					strings.Contains(event.Text, "rat") {
					contacts++
				}
			}

			if contacts != tc.contacts {
				t.Fatalf("rat contacts = %d, want %d: %+v",
					contacts, tc.contacts, result.Events)
			}
		})
	}
}

func TestLightningBoltRespectsElectricImmunity(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_LIGHTNING_BOLT")
	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)

	actor.KindID = "MONS_AIR_ELEMENTAL"

	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	events, err := g.runAction(g.player, ecs.Intent{
		Kind:    ecs.IntentPlayerSpell,
		SpellID: "SPELL_LIGHTNING_BOLT",
		DX:      1,
		Forced:  true,
	}, 10, "player")

	if err != nil {
		t.Fatal(err)
	}

	if health.Current != 500 {
		t.Fatalf("rElec 3 target lost %d HP: %+v",
			500-health.Current, events)
	}
}

func TestChainLightningArcsBackToCasterAtReducedDamage(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_CHAIN_LIGHTNING")
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 500
	ratHealth.Max = 500

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 500
	playerHealth.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	events, err := g.runAction(g.player, ecs.Intent{
		Kind:    ecs.IntentPlayerSpell,
		SpellID: "SPELL_CHAIN_LIGHTNING",
		Forced:  true,
	}, 10, "player")

	if err != nil {
		t.Fatal(err)
	}

	if ratHealth.Current >= 500 {
		t.Fatalf("first arc did not hurt the rat: %+v", events)
	}

	if playerHealth.Current >= 500 {
		t.Fatalf("second arc did not return to the caster: %+v", events)
	}
}

func TestLRDExplodesWallAroundCenterWithoutDestroyingIt(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_LRD")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].SetCell(5, 1, terrain.RockWall); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8 && health.Current == 500; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_LRD",
			DX:      2,
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}
	}

	if health.Current >= 500 {
		t.Fatal("rock wall fragments did not hit adjacent rat")
	}

	if got := g.levels[1].Cells()[1][5]; got != terrain.RockWall {
		t.Fatalf("LRD destroyed target wall: %s", got)
	}
}

func TestShatterBreaksDoorAndHitsMonsterBeyondIt(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_SHATTER")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 2, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].SetCell(3, 1, terrain.ClosedDoor); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8 && health.Current == 500; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_SHATTER",
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}
	}

	if got := g.levels[1].Cells()[1][3]; got != terrain.Floor {
		t.Fatalf("Shatter did not break the door: %s", got)
	}

	if health.Current >= 500 {
		t.Fatal("Shatter did not reach the rat beyond the broken door")
	}
}

func TestPoisonousVapoursPoisonsVisibleMonsterAtTargetCell(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_POISONOUS_VAPOURS")
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_POISONOUS_VAPOURS",
			DX:      1,
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		if state, ok := g.scripts.Components()["projectile.poison"].Get(rat); ok {
			degree, _ := state.Get("degree")

			if degree.(int64) < 1 {
				t.Fatalf("vapours left poison degree %v", degree)
			}

			return
		}
	}

	t.Fatal("Poisonous Vapours never poisoned the rat")
}

func TestScorchDamagesAndMakesMonsterFireVulnerable(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_SCORCH")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_SCORCH",
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		if state, ok := g.scripts.Components()["zap.fire_vulnerability"].Get(rat); ok {
			remaining, _ := state.Get("remaining_aut")

			if remaining.(int64) < 10 || health.Current >= 500 {
				t.Fatalf("Scorch left HP %d and vulnerability %v",
					health.Current, remaining)
			}

			return
		}
	}

	t.Fatal("Scorch never damaged and marked the rat")
}

func TestConjureFlameLeavesEmbersThenIgnitesWhenVacated(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_CONJURE_FLAME")

	if err := g.levels[1].MoveActor(ratID(t, g), 6, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8 &&
		!cloudAtForTest(g, 3, 1, "CLOUD_EMBERS"); attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_CONJURE_FLAME",
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}
	}

	if !cloudAtForTest(g, 3, 1, "CLOUD_EMBERS") {
		t.Fatal("Conjure Flame did not leave embers")
	}

	if err := g.levels[1].MoveActor(g.player, 2, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 3 &&
		!cloudAtForTest(g, 3, 1, "CLOUD_FIRE"); attempt++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !cloudAtForTest(g, 3, 1, "CLOUD_FIRE") {
		t.Fatal("vacated embers did not ignite")
	}
}

func TestDischargeArcsToAdjacentMonsterAndBackToPlayer(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_DISCHARGE")
	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 500
	ratHealth.Max = 500

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 500
	playerHealth.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8 && ratHealth.Current == 500; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_DISCHARGE",
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}
	}

	if ratHealth.Current >= 500 {
		t.Fatal("Discharge did not strike the adjacent rat")
	}

	if playerHealth.Current >= 500 {
		t.Fatal("Discharge did not arc back to the caster")
	}
}

func TestThunderboltGainsChargesOnConsecutiveCasts(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_THUNDERBOLT")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for cast := 1; cast <= 2; cast++ {
		result, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_THUNDERBOLT",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		state, ok := g.scripts.Components()["zap.thunderbolt"].Get(g.player)

		if !ok {
			t.Fatalf("cast %d did not store charge state: %+v", cast, result.Events)
		}

		charges, _ := state.Get("charges")

		if charges != int64(cast) {
			t.Fatalf("cast %d stored %v charges", cast, charges)
		}
	}

	if health.Current >= 500 {
		t.Fatal("Thunderbolt never damaged the adjacent rat")
	}
}

func TestFreezingCloudPlacesPersistentColdCloudAtTarget(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_FREEZING_CLOUD")

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_FREEZING_CLOUD",
			DX:      2,
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		if cloudAtForTest(g, 5, 1, "CLOUD_COLD") {
			return
		}
	}

	t.Fatal("Freezing Cloud did not place a cold cloud at its target")
}

func TestMysticBlastDamagesAndKnocksBackAdjacentRat(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_ISKENDERUNS_MYSTIC_BLAST")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_ISKENDERUNS_MYSTIC_BLAST",
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		position, _ := g.stores.Positions.Get(rat)

		if position.X > 4 {
			if health.Current >= 500 {
				t.Fatal("Mystic Blast pushed the rat without damaging it")
			}

			return
		}
	}

	t.Fatal("Mystic Blast never knocked the rat away")
}

func TestMaxwellsCouplingChargesThenVaporizesNearestMonster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_MAXWELLS_COUPLING")
	rat := ratID(t, g)
	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 500
	playerHealth.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_MAXWELLS_COUPLING",
		}); err != nil {
			t.Fatal(err)
		}

		if _, ok := g.scripts.Components()["magic.channel"].Get(g.player); ok {
			break
		}
	}

	if _, ok := g.scripts.Components()["magic.channel"].Get(g.player); !ok {
		t.Fatal("Maxwell's Coupling did not begin charging")
	}

	for wait := 0; wait < 12; wait++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		if _, ok := g.scripts.Components()["magic.channel"].Get(g.player); !ok {
			break
		}
	}

	health, _ := g.stores.Health.Get(rat)

	if health != nil && health.Current > 0 {
		t.Fatalf("Maxwell's Coupling left rat at %d HP", health.Current)
	}

	if _, ok := g.scripts.Components()["magic.channel"].Get(g.player); ok {
		t.Fatal("Maxwell's Coupling did not end after discharge")
	}
}

func TestIrradiateDamagesWretchesAndContaminatesCaster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_IRRADIATE")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_IRRADIATE",
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		wretched, ok := g.scripts.Components()["zap.wretched"].Get(rat)

		if !ok {
			continue
		}

		remaining, _ := wretched.Get("remaining_aut")
		contamination, ok := g.scripts.Components()["zap.contamination"].Get(g.player)

		if !ok ||
			remaining.(int64) <= 0 ||
			health.Current >= 500 {
			t.Fatalf("Irradiate left HP %d, wretched %v, contamination %v",
				health.Current, remaining, ok)
		}

		amount, _ := contamination.Get("amount")

		if amount.(int64) < 1000 {
			t.Fatalf("Irradiate added only %v contamination", amount)
		}

		return
	}

	t.Fatal("Irradiate never affected the adjacent rat")
}

func TestInvokedFastrootGrabsAndConstrictsMonster(t *testing.T) {
	g := newZapGame(t)
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 500
	health.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	decision, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
		"spell_id": "SPELL_FASTROOT",
		"power":    100,
		"dx":       1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if decision["invoked"] != true {
		t.Fatalf("Fastroot was not invoked: %+v", decision)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	state, ok := g.scripts.Components()["zap.grasping_roots"].Get(rat)

	if !ok {
		t.Fatal("Fastroot did not grasp adjacent rat")
	}

	remaining, _ := state.Get("remaining_aut")

	if remaining.(int64) < 20 {
		t.Fatalf("Fastroot duration = %v", remaining)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if health.Current >= 500 {
		t.Fatal("Fastroot did not constrict the rat")
	}
}

func TestPolarVortexKeepsSavedWindAndDamagesNearbyMonster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_POLAR_VORTEX")
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 1000
	playerHealth.Max = 1000

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 500
	ratHealth.Max = 500

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_POLAR_VORTEX",
		}); err != nil {
			t.Fatal(err)
		}

		if _, active := g.scripts.Components()["zap.polar_vortex"].Get(g.player); active {
			break
		}
	}

	if _, active := g.scripts.Components()["zap.polar_vortex"].Get(g.player); !active {
		t.Fatal("Polar Vortex never began")
	}

	if _, flying := g.scripts.Components()["zap.flight"].Get(g.player); !flying {
		t.Fatal("Polar Vortex did not grant flight")
	}

	for turn := 0; turn < 3 && ratHealth.Current == 500; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if ratHealth.Current == 500 {
		t.Fatal("Polar Vortex wind never damaged the nearby rat")
	}
}

func TestOrbOfDestructionMovesThenExplodesOnTarget(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_IOOD")
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 1000
	playerHealth.Max = 1000

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 500
	ratHealth.Max = 500

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_IOOD",
			DX:      3,
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		if len(g.scripts.Components()["zap.iood"].Entities()) > 0 {
			break
		}
	}

	if len(g.scripts.Components()["zap.iood"].Entities()) == 0 {
		t.Fatal("Orb of Destruction did not create a moving orb")
	}

	for turn := 0; turn < 8 && ratHealth.Current == 500; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if ratHealth.Current == 500 {
		t.Fatal("Orb of Destruction did not reach the rat")
	}
}

func TestThrowFlameDoesNotDamageFireImmuneMonster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_THROW_FLAME")
	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)

	actor.KindID = "MONS_FIRE_ELEMENTAL"

	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_THROW_FLAME",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatalf("Throw Flame spent no time: %+v", result.Events)
	}

	if health.Current != 100 {
		t.Fatalf("fire immune monster lost %d HP", 100-health.Current)
	}
}

func TestStoneArrowReducesTargetHealth(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_STONE_ARROW")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 6; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_STONE_ARROW",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		health, _ = g.stores.Health.Get(rat)

		if health.Current < 100 {
			return
		}
	}

	t.Fatal("Stone Arrow never damaged the target")
}

func TestStoneArrowOrdinaryCastFindsVisibleTarget(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_STONE_ARROW")

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandCast,
		SpellID: "SPELL_STONE_ARROW",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatalf("visible target was rejected: %+v", result.Events)
	}
}

func TestSlowZapAppliesSpeedAndDuration(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_SLOW")
	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)
	baseSpeed := actor.Speed

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 12; attempt++ {
		result, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_SLOW",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent == 0 {
			t.Fatalf("Slow spent no time: %+v", result.Events)
		}

		state, found := g.scripts.Components()["projectile.slow"].Get(rat)

		if found {
			remaining, err := state.Get("remaining_aut")

			if err != nil {
				t.Fatal(err)
			}

			actor, _ = g.stores.Actors.Get(rat)

			if actor.Speed >= baseSpeed || remaining.(int64) <= 0 {
				t.Fatalf("Slow left speed %d and duration %v", actor.Speed, remaining)
			}

			return
		}
	}

	t.Fatal("Slow never affected the target")
}

func TestInvokedParalysisStopsMonsterActions(t *testing.T) {
	g := newZapGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 12; attempt++ {
		decision, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
			"spell_id": "SPELL_PARALYSE",
			"power":    100,
			"dx":       1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if decision["invoked"] != true {
			t.Fatalf("Paralysis was not invoked: %+v", decision)
		}

		if err := g.scripts.ApplyPending(); err != nil {
			t.Fatal(err)
		}

		state, found := g.scripts.Components()["zap.paralysis"].Get(rat)

		if !found {
			continue
		}

		remaining, err := state.Get("remaining_aut")

		if err != nil {
			t.Fatal(err)
		}

		if remaining.(int64) < 10 {
			t.Fatalf("Paralysis duration is too short: %v", remaining)
		}

		playerHealth, _ := g.stores.Health.Get(g.player)
		before := playerHealth.Current

		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		playerHealth, _ = g.stores.Health.Get(g.player)

		if playerHealth.Current != before {
			t.Fatal("paralysed adjacent monster attacked")
		}

		return
	}

	t.Fatal("Paralysis never affected the rat")
}

func TestDigOpensDuggableWallAndStopsAtTree(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_DIG")
	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	if err := g.levels[1].MoveActor(g.player, 6, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].SetCell(10, 1, terrain.Tree); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].SetCell(9, 1, terrain.Grate); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_DIG",
			DX:      1,
		}); err != nil {
			t.Fatal(err)
		}

		if g.levels[1].Cells()[1][8] == terrain.Floor {
			if got := g.levels[1].Cells()[1][9]; got != terrain.Floor {
				t.Fatalf("Dig stopped at diggable grate: %s", got)
			}

			if got := g.levels[1].Cells()[1][10]; got != terrain.Tree {
				t.Fatalf("Dig destroyed non-diggable tree: %s", got)
			}

			return
		}
	}

	t.Fatal("Dig never opened the rock wall")
}

func TestBeckoningPullsMonsterToNearestHabitablePathCell(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_BECKONING")
	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	skills, _ := g.stores.Skills.Get(g.player)

	skills.Entries = append(skills.Entries, character.Skill{
		ID:    "SK_TRANSLOCATIONS",
		Level: 27,
	})

	if _, err := g.stores.Skills.Set(g.player, *skills); err != nil {
		t.Fatal(err)
	}

	rat := ratID(t, g)
	var lastEvents []Event

	for attempt := 0; attempt < 8; attempt++ {
		events, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_BECKONING",
			DX:      3,
			Forced:  true,
		}, 10, "player")

		if err != nil {
			t.Fatal(err)
		}

		lastEvents = events

		position, _ := g.stores.Positions.Get(rat)

		if position.X == 2 && position.Y == 1 {
			return
		}
	}

	position, _ := g.stores.Positions.Get(rat)
	t.Fatalf("Beckoning never pulled the rat next to its caster: position=%+v events=%+v",
		position, lastEvents)
}

func TestBeckoningKeepsAquaticAndLavaCreaturesInHabitat(t *testing.T) {
	for _, tc := range []struct {
		name    string
		kind    string
		feature terrain.ID
	}{
		{
			name:    "water",
			kind:    "MONS_ELECTRIC_EEL",
			feature: terrain.ShallowWater,
		},

		{
			name:    "lava",
			kind:    "MONS_LAVA_SNAKE",
			feature: terrain.Lava,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newZapGame(t)
			grantZapForTest(t, g, "SPELL_BECKONING")
			attributes, _ := g.stores.Attributes.Get(g.player)

			attributes.Intelligence = 100

			skills, _ := g.stores.Skills.Get(g.player)

			skills.Entries = append(skills.Entries, character.Skill{
				ID:    "SK_TRANSLOCATIONS",
				Level: 27,
			})

			if _, err := g.stores.Skills.Set(g.player, *skills); err != nil {
				t.Fatal(err)
			}

			monster := ratID(t, g)
			actor, _ := g.stores.Actors.Get(monster)

			actor.KindID = tc.kind

			for _, x := range []int{
				3,
				4,
			} {
				if err := g.levels[1].SetCell(x, 1, tc.feature); err != nil {
					t.Fatal(err)
				}
			}

			for attempt := 0; attempt < 8; attempt++ {
				events, err := g.runAction(g.player, ecs.Intent{
					Kind:    ecs.IntentPlayerSpell,
					SpellID: "SPELL_BECKONING",
					DX:      3,
					Forced:  true,
				}, 10, "player")

				if err != nil {
					t.Fatal(err)
				}

				for _, event := range events {
					if strings.Contains(event.Text, "hurled suddenly forward") {
						position, _ := g.stores.Positions.Get(monster)

						if position.X != 3 || position.Y != 1 {
							t.Fatalf("Beckoning chose (%d,%d), want habitat at (3,1)",
								position.X, position.Y)
						}

						return
					}
				}
			}

			t.Fatal("Beckoning did not pull the monster onto valid habitat")
		})
	}
}

func TestAgonyTormentsLivingMonsterWithoutKilling(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_AGONY")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 12; attempt++ {
		result, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_AGONY",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent == 0 {
			t.Fatalf("Agony spent no time: %+v", result.Events)
		}

		health, _ = g.stores.Health.Get(rat)

		if health.Current < 100 {
			if health.Current != 51 {
				t.Fatalf("Agony left rat at %d HP, want 51", health.Current)
			}

			return
		}
	}

	t.Fatal("Agony never tormented the rat")
}

func TestDispelUndeadDamagesOnlyUndead(t *testing.T) {
	for _, tc := range []struct {
		name     string
		kind     string
		wantHurt bool
	}{
		{
			name: "living",
			kind: "MONS_RAT",
		},

		{
			name:     "undead",
			kind:     "MONS_ZOMBIE",
			wantHurt: true,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newZapGame(t)
			grantZapForTest(t, g, "SPELL_DISPEL_UNDEAD")
			rat := ratID(t, g)
			actor, _ := g.stores.Actors.Get(rat)

			actor.KindID = tc.kind

			health, _ := g.stores.Health.Get(rat)

			health.Current = 100
			health.Max = 100

			if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
				t.Fatal(err)
			}

			for attempt := 0; attempt < 5; attempt++ {
				result, err := g.Step(Command{
					Kind:    CommandForceCast,
					SpellID: "SPELL_DISPEL_UNDEAD",
					DX:      1,
				})

				if err != nil {
					t.Fatal(err)
				}

				if result.Spent == 0 {
					t.Fatalf("Dispel Undead spent no time: %+v", result.Events)
				}

				health, _ = g.stores.Health.Get(rat)

				if health.Current < 100 {
					if !tc.wantHurt {
						t.Fatal("Dispel Undead damaged a living rat")
					}

					return
				}
			}

			if tc.wantHurt {
				t.Fatal("Dispel Undead did not damage an undead target")
			}
		})
	}
}

func TestHailstormPummelsDistantButNotAdjacentMonster(t *testing.T) {
	for _, tc := range []struct {
		name     string
		x        int
		wantHurt bool
	}{
		{
			name:     "within ring",
			x:        4,
			wantHurt: true,
		},

		{
			name: "adjacent",
			x:    2,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newZapGame(t)
			grantZapForTest(t, g, "SPELL_HAILSTORM")
			rat := ratID(t, g)
			health, _ := g.stores.Health.Get(rat)

			health.Current = 100
			health.Max = 100
			var lastEvents []Event

			for attempt := 0; attempt < 4; attempt++ {
				if err := g.levels[1].MoveActor(rat, tc.x, 1); err != nil {
					t.Fatal(err)
				}

				result, err := g.Step(Command{
					Kind:    CommandForceCast,
					SpellID: "SPELL_HAILSTORM",
				})

				if err != nil {
					t.Fatal(err)
				}

				if result.Spent == 0 {
					t.Fatalf("Hailstorm spent no time: %+v", result.Events)
				}

				lastEvents = result.Events
				health, _ = g.stores.Health.Get(rat)

				if health.Current < 100 {
					if !tc.wantHurt {
						t.Fatal("adjacent rat was hit by Hailstorm")
					}

					return
				}
			}

			if tc.wantHurt {
				t.Fatalf("Hailstorm never damaged a monster in its ring: %+v", lastEvents)
			}
		})
	}
}

func TestInvokedSonicWaveDamagesVisibleMonster(t *testing.T) {
	g := newZapGame(t)
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	decision, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
		"spell_id": "SPELL_SONIC_WAVE",
		"power":    200,
	})

	if err != nil {
		t.Fatal(err)
	}

	if decision["invoked"] != true {
		t.Fatalf("Sonic Wave did not invoke: %+v", decision)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	health, _ = g.stores.Health.Get(rat)

	if health.Current >= 100 {
		t.Fatal("Sonic Wave did not damage a visible rat")
	}
}

func TestMindburstDamagesThinkingMonsterOnly(t *testing.T) {
	for _, tc := range []struct {
		name     string
		kind     string
		wantHurt bool
	}{
		{
			name:     "rat",
			kind:     "MONS_RAT",
			wantHurt: true,
		},

		{
			name: "zombie",
			kind: "MONS_ZOMBIE",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newZapGame(t)
			rat := ratID(t, g)
			actor, _ := g.stores.Actors.Get(rat)

			actor.KindID = tc.kind

			health, _ := g.stores.Health.Get(rat)

			health.Current = 100
			health.Max = 100

			for attempt := 0; attempt < 8; attempt++ {
				decision, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
					"spell_id": "SPELL_MINDBURST",
					"power":    100,
					"dx":       1,
				})

				if err != nil {
					t.Fatal(err)
				}

				if decision["invoked"] != true {
					t.Fatalf("Mindburst did not invoke: %+v", decision)
				}

				if err := g.scripts.ApplyPending(); err != nil {
					t.Fatal(err)
				}

				health, _ = g.stores.Health.Get(rat)

				if health.Current < 100 {
					if !tc.wantHurt {
						t.Fatal("Mindburst damaged a brainless zombie")
					}

					return
				}
			}

			if tc.wantHurt {
				t.Fatal("Mindburst never damaged the rat")
			}
		})
	}
}

func TestVampiricDrainingStealsAdjacentLivingHealth(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_VAMPIRIC_DRAINING")
	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 100
	ratHealth.Max = 100

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 25
	playerHealth.Max = 100

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_VAMPIRIC_DRAINING",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		ratHealth, _ = g.stores.Health.Get(rat)
		playerHealth, _ = g.stores.Health.Get(g.player)

		if ratHealth.Current < 100 && playerHealth.Current > 25 {
			return
		}
	}

	t.Fatal("Vampiric Draining did not transfer health")
}

func TestStingPoisonsLivingMonsterOnHit(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_STING")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_STING",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if state := g.scripts.Components()["projectile.poison"]; state.Has(rat) {
			return
		}
	}

	t.Fatal("Sting never poisoned the rat")
}

func TestStingStillHurtsPoisonImmuneMonster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_STING")
	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)

	actor.KindID = "MONS_ZOMBIE"

	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_STING",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if g.scripts.Components()["projectile.poison"].Has(rat) {
			t.Fatal("poison immune zombie gained poison")
		}

		health, _ = g.stores.Health.Get(rat)

		if health.Current < 100 {
			return
		}
	}

	t.Fatal("Sting never dealt its unresistible damage")
}

func TestStarburstFiresAlongCardinalRay(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_STARBURST")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	for attempt := 0; attempt < 8; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_STARBURST",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		health, _ = g.stores.Health.Get(rat)

		if health.Current < 100 {
			return
		}
	}

	t.Fatal("Starburst never burned the rat along its east ray")
}

func TestFireballExplodesAtAimedEmptyCell(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_FIREBALL")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	if err := g.levels[1].MoveActor(rat, 4, 2); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_FIREBALL",
			DX:      3,
		})

		if err != nil {
			t.Fatal(err)
		}

		health, _ = g.stores.Health.Get(rat)

		if health.Current < 100 {
			return
		}
	}

	t.Fatal("Fireball did not damage the rat next to its aimed cell")
}

func TestInvokedExplosionsSplashAdjacentMonster(t *testing.T) {
	for _, spellID := range []string{
		"SPELL_ICEBLAST",
		"SPELL_HURL_DAMNATION",
	} {
		t.Run(spellID, func(t *testing.T) {
			g := newZapGame(t)
			rat := ratID(t, g)
			health, _ := g.stores.Health.Get(rat)

			health.Current = 100
			health.Max = 100

			if err := g.levels[1].MoveActor(rat, 4, 2); err != nil {
				t.Fatal(err)
			}

			decision, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
				"spell_id": spellID,
				"power":    100,
				"dx":       3,
			})

			if err != nil {
				t.Fatal(err)
			}

			if decision["invoked"] != true {
				t.Fatalf("effect not invoked: %+v", decision)
			}

			if err := g.scripts.ApplyPending(); err != nil {
				t.Fatal(err)
			}

			health, _ = g.stores.Health.Get(rat)

			if health.Current >= 100 {
				t.Fatal("adjacent rat took no explosion damage")
			}
		})
	}
}

func TestFireballCanHurtItsCaster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_FIREBALL")
	health, _ := g.stores.Health.Get(g.player)

	health.Current = 100
	health.Max = 100

	for attempt := 0; attempt < 8; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_FIREBALL",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		health, _ = g.stores.Health.Get(g.player)

		if health.Current < 100 {
			return
		}
	}

	t.Fatal("nearby Fireball did not damage the caster")
}

func TestInvokedBoltsApplyTheirMonsterEffects(t *testing.T) {
	for _, tc := range []struct {
		id    string
		field string
	}{
		{
			id:    "SPELL_BOLT_OF_LIGHT",
			field: "blind_aut",
		},

		{
			id:    "SPELL_CORROSIVE_BOLT",
			field: "corrosion_aut",
		},
	} {
		t.Run(tc.id, func(t *testing.T) {
			g := newZapGame(t)
			rat := ratID(t, g)
			health, _ := g.stores.Health.Get(rat)

			health.Current = 1000
			health.Max = 1000

			for attempt := 0; attempt < 8; attempt++ {
				decision, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
					"spell_id": tc.id,
					"power":    200,
					"dx":       1,
				})

				if err != nil {
					t.Fatal(err)
				}

				if decision["invoked"] != true {
					t.Fatalf("effect not invoked: %+v", decision)
				}

				if err := g.scripts.ApplyPending(); err != nil {
					t.Fatal(err)
				}

				state, found := g.scripts.Components()["magic.monster_enchant"].Get(rat)

				if found {
					value, err := state.Get(tc.field)

					if err != nil {
						t.Fatal(err)
					}

					if value.(int64) > 0 {
						return
					}
				}
			}

			t.Fatalf("%s never applied %s", tc.id, tc.field)
		})
	}
}

func TestQuicksilverBoltDispelsMonsterSlow(t *testing.T) {
	g := newZapGame(t)
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 1000
	health.Max = 1000

	_, err := g.scripts.Components()["projectile.slow"].Set(rat, map[string]any{
		"base_speed":    int64(10),
		"remaining_aut": int64(100),
	})

	if err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		decision, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
			"spell_id": "SPELL_QUICKSILVER_BOLT",
			"power":    200,
			"dx":       1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if decision["invoked"] != true {
			t.Fatalf("Quicksilver Bolt not invoked: %+v", decision)
		}

		if err := g.scripts.ApplyPending(); err != nil {
			t.Fatal(err)
		}

		if !g.scripts.Components()["projectile.slow"].Has(rat) {
			return
		}
	}

	t.Fatal("Quicksilver Bolt never dispelled slow")
}

func TestStickyFlameBurnsAcrossMonsterActions(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_STICKY_FLAME")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_STICKY_FLAME",
			DX:      1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if g.scripts.Components()["zap.sticky_flame"].Has(rat) {
			break
		}
	}

	if !g.scripts.Components()["zap.sticky_flame"].Has(rat) {
		t.Fatal("Sticky Flame never coated the rat")
	}

	health, _ = g.stores.Health.Get(rat)
	before := health.Current

	for turn := 0; turn < 4; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		health, _ = g.stores.Health.Get(rat)

		if health.Current < before {
			return
		}
	}

	t.Fatal("Sticky Flame caused no damage on later monster actions")
}

func TestRefrigerationChillsVisibleMonster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_OZOCUBUS_REFRIGERATION")
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 100
	ratHealth.Max = 100

	for attempt := 0; attempt < 8; attempt++ {
		_, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_OZOCUBUS_REFRIGERATION",
		})

		if err != nil {
			t.Fatal(err)
		}

		ratHealth, _ = g.stores.Health.Get(rat)

		if ratHealth.Current < 100 {
			return
		}
	}

	t.Fatal("Refrigeration never damaged a visible rat")
}

func TestIgnitionExplodesAtVisibleHostile(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_IGNITION")
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 100
	ratHealth.Max = 100

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_IGNITION",
		}); err != nil {
			t.Fatal(err)
		}

		ratHealth, _ = g.stores.Health.Get(rat)

		if ratHealth.Current < 100 {
			return
		}
	}

	t.Fatal("Ignition never damaged the visible rat")
}

func TestNecrotiseRaisesDerivedSkeletonFromMarkedKill(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_NECROTISE")
	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 1

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_NECROTISE",
			DX:      3,
		}); err != nil {
			t.Fatal(err)
		}

		undead := g.scripts.Components()["magic.summon_undead"].Entities()

		if len(undead) == 0 {
			continue
		}

		if len(undead) != 1 {
			t.Fatalf("Necrotise raised %d skeletons", len(undead))
		}

		base, found := g.scripts.Components()["magic.summon_undead"].Get(undead[0])

		if !found {
			t.Fatal("raised skeleton has no base state")
		}

		kind, getErr := base.Get("base_kind_id")

		if getErr != nil {
			t.Fatal(getErr)
		}

		if kind != "MONS_RAT" {
			t.Fatalf("skeleton retained base kind %v, want rat", kind)
		}

		if corpses := g.stores.Corpses.Entities(); len(corpses) != 0 {
			t.Fatalf("Necrotise also left a corpse: %v", corpses)
		}

		return
	}

	t.Fatal("Necrotise did not raise its marked rat")
}

func TestInnerFlameMarkedDeathExplodesAndCreatesFireClouds(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_INNER_FLAME")
	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 100
	ratHealth.Max = 100

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: "SPELL_INNER_FLAME",
			DX:      1,
		}); err != nil {
			t.Fatal(err)
		}

		if g.scripts.Components()["zap.inner_flame"].Has(rat) {
			break
		}

		if attempt == 7 {
			t.Fatal("Inner Flame never marked the rat")
		}
	}

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 100
	playerHealth.Max = 100

	if err := g.levels[1].MoveActor(rat, 4, 1); err != nil {
		t.Fatal(err)
	}

	playerPosition, _ := g.stores.Positions.Get(g.player)
	ratPosition, _ := g.stores.Positions.Get(rat)

	ratHealth.Current = 0

	if _, err := g.runAction(g.player, ecs.Intent{
		Kind: ecs.IntentWait,
	}, 10, "player"); err != nil {
		t.Fatal(err)
	}

	playerHealth, _ = g.stores.Health.Get(g.player)

	if playerHealth.Current >= 100 {
		t.Fatalf("adjacent Inner Flame explosion did not hurt its caster: player=%+v rat=%+v",
			playerPosition, ratPosition)
	}

	if g.world.EntityExists(rat) {
		t.Fatal("Inner Flame victim survived death processing")
	}

	if got := len(g.scripts.Components()["world.cloud"].Entities()); got == 0 {
		t.Fatal("Inner Flame explosion created no fire clouds")
	}

	if corpses := g.stores.Corpses.Entities(); len(corpses) != 0 {
		t.Fatalf("exploding rat also left a corpse: %v", corpses)
	}
}

func TestFireCloudBurnsOccupantOnItsAction(t *testing.T) {
	g := newZapGame(t)
	position, _ := g.stores.Positions.Get(g.player)
	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 100
	playerHealth.Max = 100

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["world.cloud"].Set(entity, map[string]any{
		"kind_id":         "CLOUD_FIRE",
		"source_actor_id": uint64(g.player),
		"kill_category":   "KC_YOU",
		"killer_type":     "KILL_YOU_MISSILE",
		"level_id":        int64(position.LevelID),
		"x":               int64(position.X),
		"y":               int64(position.Y),
		"decay_aut":       int64(1000),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.runAction(g.player, ecs.Intent{
		Kind: ecs.IntentWait,
	}, 10, "player"); err != nil {
		t.Fatal(err)
	}

	playerHealth, _ = g.stores.Health.Get(g.player)

	if playerHealth.Current >= 100 {
		t.Fatal("fire cloud did not burn its occupant")
	}
}

func TestTeleportOtherMovesMonsterAfterDelayedStatus(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_TELEPORT_OTHER")
	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	rat := ratID(t, g)

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind:    ecs.IntentPlayerSpell,
			SpellID: "SPELL_TELEPORT_OTHER",
			DX:      3,
			Forced:  true,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		if g.scripts.Components()["zap.teleport"].Has(rat) {
			break
		}

		if attempt == 7 {
			t.Fatal("Teleport Other never marked the rat")
		}
	}

	for action := 0; action < 4; action++ {
		events, err := g.runAction(rat, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			if strings.Contains(event.Text, "disappears!") {
				position, _ := g.stores.Positions.Get(rat)

				if position.X == 4 && position.Y == 1 {
					t.Fatal("Teleport Other left rat at its starting cell")
				}

				if !g.levels[1].Walkable(position.X, position.Y) {
					t.Fatal("Teleport Other chose an impassable cell")
				}

				return
			}
		}
	}

	t.Fatal("delayed Teleport Other never moved the rat")
}

func TestSandblastStopsAtFourTiles(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_SANDBLAST")
	rat := ratID(t, g)
	before, _ := g.stores.Health.Get(rat)

	if err := g.levels[1].MoveActor(rat, 7, 1); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SANDBLAST",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	after, _ := g.stores.Health.Get(rat)

	if after.Current != before.Current {
		t.Fatalf("out-of-range rat took damage: %d to %d", before.Current, after.Current)
	}

	var dissipated bool

	for _, event := range result.Events {
		dissipated = dissipated ||
			strings.Contains(event.Text, "blast of sand dissipates")
	}

	if !dissipated {
		t.Fatalf("out-of-range sandblast had no miss event: %+v", result.Events)
	}
}
