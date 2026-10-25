package game

import (
	"reflect"
	"strings"
	"testing"

	"github.com/gravestench/akara"
)

func brandPracticeGameWithSeed(
	t *testing.T,
	seed uint64,
	jobID string,
	weaponKind string,
	brand string,
	monsterKind string,
) (*Game, akara.Entity) {
	t.Helper()

	startingWeapon := "WPN_RAPIER"

	if jobID != "JOB_FIGHTER" {
		startingWeapon = ""
	}

	g, err := newScenario(seed, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     jobID,
	}, startingWeapon, "Tester", ordinaryMonsterScenarioID)

	if err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		g.Close()
		t.Fatal(err)
	}

	weaponID := equipPlayerLauncher(t, g, weaponKind)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = brand

	monster := ratID(t, g)
	actor, _ := g.stores.Actors.Get(monster)

	actor.KindID = monsterKind
	actor.Speed = 1

	monsterHealth, _ := g.stores.Health.Get(monster)

	monsterHealth.Max = 1000
	monsterHealth.Current = 1000

	energy, _ := g.stores.MonsterEnergy.Get(monster)

	energy.Points = 0

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Max = 1000
	playerHealth.Current = 500

	return g, monster
}

func brandPracticeGame(
	t *testing.T,
	jobID string,
	weaponKind string,
	brand string,
	monsterKind string,
) (*Game, akara.Entity) {
	t.Helper()

	return brandPracticeGameWithSeed(t, 1, jobID, weaponKind,
		brand, monsterKind)
}

func TestPlayerMeleeBrandEffectFamilies(t *testing.T) {
	cases := []struct {
		name          string
		jobID         string
		weaponKind    string
		brand         string
		monsterKind   string
		message       string
		componentName string
	}{
		{
			name:        "freezing",
			jobID:       "JOB_FIGHTER",
			weaponKind:  "WPN_RAPIER",
			brand:       "SPWPN_FREEZING",
			monsterKind: "MONS_RAT",
			message:     "freezes the rat",
		},

		{
			name:        "electrocution",
			jobID:       "JOB_FIGHTER",
			weaponKind:  "WPN_RAPIER",
			brand:       "SPWPN_ELECTROCUTION",
			monsterKind: "MONS_RAT",
			message:     "Lightning courses through the rat",
		},

		{
			name:        "holy wrath",
			jobID:       "JOB_FIGHTER",
			weaponKind:  "WPN_RAPIER",
			brand:       "SPWPN_HOLY_WRATH",
			monsterKind: "MONS_WIGHT",
			message:     "wight convulses",
		},

		{
			name:          "venom",
			jobID:         "JOB_FIGHTER",
			weaponKind:    "WPN_RAPIER",
			brand:         "SPWPN_VENOM",
			monsterKind:   "MONS_RAT",
			componentName: "projectile.poison",
		},

		{
			name:        "vampirism",
			jobID:       "JOB_FIGHTER",
			weaponKind:  "WPN_RAPIER",
			brand:       "SPWPN_VAMPIRISM",
			monsterKind: "MONS_RAT",
			message:     "You feel better",
		},

		{
			name:        "pain",
			jobID:       "JOB_NECROMANCER",
			weaponKind:  "WPN_WHIP",
			brand:       "SPWPN_PAIN",
			monsterKind: "MONS_RAT",
			message:     "writhes in agony",
		},

		{
			name:          "draining",
			jobID:         "JOB_FIGHTER",
			weaponKind:    "WPN_RAPIER",
			brand:         "SPWPN_DRAINING",
			monsterKind:   "MONS_RAT",
			componentName: "magic.monster_drained",
		},

		{
			name:          "antimagic",
			jobID:         "JOB_FIGHTER",
			weaponKind:    "WPN_RAPIER",
			brand:         "SPWPN_ANTIMAGIC",
			monsterKind:   "MONS_ORC_WIZARD",
			componentName: "magic.monster_enfeeble",
		},

		{
			name:        "distortion",
			jobID:       "JOB_FIGHTER",
			weaponKind:  "WPN_RAPIER",
			brand:       "SPWPN_DISTORTION",
			monsterKind: "MONS_RAT",
			message:     "Space warps",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			g, monster := brandPracticeGame(t, tc.jobID, tc.weaponKind,
				tc.brand, tc.monsterKind)
			defer g.Close()

			for attempt := 0; attempt < 100; attempt++ {
				result, err := g.Step(Command{
					Kind: CommandMove,
					DX:   1,
				})

				if err != nil {
					t.Fatal(err)
				}

				if tc.componentName != "" &&
					g.scripts.Components()[tc.componentName].Has(monster) {
					return
				}

				for _, event := range result.Events {
					if strings.Contains(event.Text, tc.message) {
						return
					}
				}
			}

			t.Fatalf("%s did not produce its effect", tc.brand)
		})
	}
}

func TestVorpalPlayerMeleeAddsDamageToSameBaseHit(t *testing.T) {
	command := Command{
		Kind: CommandMove,
		DX:   1,
	}

	for seed := uint64(1); seed <= 30; seed++ {
		normal, normalRat := brandPracticeGameWithSeed(t, seed,
			"JOB_FIGHTER", "WPN_MORNINGSTAR", "", "MONS_RAT")
		vorpal, vorpalRat := brandPracticeGameWithSeed(t, seed,
			"JOB_FIGHTER", "WPN_MORNINGSTAR", "SPWPN_VORPAL", "MONS_RAT")

		_, normalErr := normal.Step(command)
		_, vorpalErr := vorpal.Step(command)

		if normalErr != nil {
			t.Fatalf("normal attack with seed %d: %v", seed, normalErr)
		}

		if vorpalErr != nil {
			t.Fatalf("vorpal attack with seed %d: %v", seed, vorpalErr)
		}

		normalHealth, _ := normal.stores.Health.Get(normalRat)
		vorpalHealth, _ := vorpal.stores.Health.Get(vorpalRat)
		normalHP := normalHealth.Current
		vorpalHP := vorpalHealth.Current
		normal.Close()
		vorpal.Close()

		if normalHP < 1000 {
			if vorpalHP >= normalHP {
				t.Fatalf("seed %d left normal HP %d, vorpal HP %d",
					seed, normalHP, vorpalHP)
			}

			return
		}
	}

	t.Fatal("no opening morningstar attack hit across thirty seeds")
}

func TestPlayerDistortionBanishesMonsterWithoutKillXP(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	weapon, _ := g.stores.Items.Get(playerMeleeWeapon(t, g))

	weapon.Ego = "SPWPN_DISTORTION"

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)
	originalMax := ratHealth.Max

	ratHealth.Max = 1000
	ratHealth.Current = 1000

	playerHealth, _ := g.stores.Health.Get(g.player)
	progression, _ := g.stores.Progression.Get(g.player)
	startingXP := progression.TotalXP

	for attempt := 0; attempt < 300; attempt++ {
		dx, dy := placePlayerBesideMonster(t, g, rat)

		playerHealth.Current = playerHealth.Max

		_, err := g.Step(Command{
			Kind: CommandMove,
			DX:   dx,
			DY:   dy,
		})

		if err != nil {
			t.Fatal(err)
		}

		position, found := g.stores.Positions.Get(rat)

		if !found {
			t.Fatal("distortion killed the practice monster before banishment")
		}

		if position.LevelID != abyssStorageID {
			continue
		}

		if !g.world.EntityExists(rat) || progression.TotalXP != startingXP {
			t.Fatal("banishment destroyed the monster or awarded kill XP")
		}

		ratHealth.Max = originalMax
		ratHealth.Current = originalMax

		snapshot := g.Snapshot()
		restored, err := Restore(snapshot)

		if err != nil {
			t.Fatal(err)
		}

		defer restored.Close()

		if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
			t.Fatal("banished monster changed across save and restore")
		}

		banishment := g.scripts.Components()["world.banishment"]

		if _, err := banishment.Set(rat, map[string]any{
			"origin_level_id": int64(0),
			"origin_x":        int64(1),
			"origin_y":        int64(1),
		}); err != nil {
			t.Fatal(err)
		}

		corrupt, err := Restore(g.Snapshot())

		if err == nil {
			corrupt.Close()
			t.Fatal("restore accepted invalid monster banishment origin")
		}

		return
	}

	t.Fatal("distortion never banished a monster")
}
