package game

import (
	"strconv"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/save"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// Every patron uses the real terminal choice and the same saved Akara item.
// The two area effects run only after the forced confirmation spends a turn.
func TestDivineWeaponCapstonesCommitAndRestore(t *testing.T) {
	cases := []struct {
		name    string
		god     string
		ability string
		brand   string
	}{
		{
			name:    "Shining One",
			god:     "GOD_SHINING_ONE",
			ability: "ABIL_TSO_BLESS_WEAPON",
			brand:   "SPWPN_HOLY_WRATH",
		},

		{
			name:    "Kikubaaqudgha",
			god:     "GOD_KIKUBAAQUDGHA",
			ability: "ABIL_KIKU_BLESS_WEAPON",
			brand:   "SPWPN_PAIN",
		},

		{
			name:    "Lugonu",
			god:     "GOD_LUGONU",
			ability: "ABIL_LUGONU_BLESS_WEAPON",
			brand:   "SPWPN_DISTORTION",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			g, err := NewDungeonGame(1, "SP_HUMAN", "JOB_ABYSSAL_KNIGHT", "WPN_HAND_AXE", "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()

			if _, err := g.scripts.Components()["religion.worship"].Set(g.player, map[string]any{
				"god_id": tc.god,
				"piety":  int64(200),
			}); err != nil {
				t.Fatal(err)
			}

			command := Command{
				Kind:      CommandAbility,
				AbilityID: tc.ability,
			}

			choice, err := g.Step(command)

			if err != nil {
				t.Fatal(err)
			}

			if choice.Spent != 0 ||
				choice.Selection == nil ||
				len(choice.Selection.Options) == 0 {
				t.Fatalf("selection: %+v", choice)
			}

			command.TargetID = choice.Selection.Options[0].ID

			selectedID, err := strconv.ParseUint(command.TargetID, 10, 64)

			if err != nil {
				t.Fatal(err)
			}

			weapon := akara.Entity(selectedID)

			position, _ := g.stores.Positions.Get(g.player)
			level := g.levels[position.LevelID]
			beforeHealth, _ := g.stores.Health.Get(g.player)
			initialHP := beforeHealth.Current
			var lich akara.Entity
			var lichX int
			var lichY int

			if tc.god == "GOD_SHINING_ONE" {
				lich, lichX, lichY = spawnCapstoneLich(t, g, position.LevelID)

				if err := level.SetCell(lichX, lichY, terrain.BloodFountain); err != nil {
					t.Fatal(err)
				}

				if err := level.SetCellBlood(position.X, position.Y, true); err != nil {
					t.Fatal(err)
				}
			}

			confirmation, err := g.Step(command)

			if err != nil {
				t.Fatal(err)
			}

			if confirmation.Spent != 0 || confirmation.Confirmation == "" {
				t.Fatalf("confirmation: %+v", confirmation)
			}

			pending, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatalf("pending restore: %v", err)
			}

			pending.Close()

			command.Forced = true

			result, err := g.Step(command)

			if err != nil {
				t.Fatal(err)
			}

			item, ok := g.stores.Items.Get(weapon)

			if result.Spent != 10 ||
				!ok ||
				item.Ego != tc.brand {
				t.Fatalf("commit spent %d, item %+v", result.Spent, item)
			}

			if tc.god == "GOD_SHINING_ONE" {
				bloody, _ := level.CellBlood(position.X, position.Y)

				if bloody {
					t.Fatal("holy word did not cleanse source cell")
				}

				if level.terrain[lichY][lichX] != terrain.BlueFountain {
					t.Fatal("holy word did not cleanse blood fountain")
				}

				lichHealth, _ := g.stores.Health.Get(lich)

				if lichHealth == nil || lichHealth.Current >= 100 {
					t.Fatal("holy word did not damage an undead target")
				}

				status, found := g.scripts.Components()["magic.monster_enfeeble"].Get(lich)

				if !found {
					t.Fatal("holy word did not daze an undead survivor")
				}

				dazed, err := status.Get("dazed_aut")

				if err != nil {
					t.Fatal(err)
				}

				if dazed.(int64) <= 0 {
					t.Fatalf("holy word daze = %v, %v", dazed, err)
				}
			}

			if tc.god == "GOD_KIKUBAAQUDGHA" {
				afterHealth, _ := g.stores.Health.Get(g.player)

				if afterHealth.Current >= initialHP {
					t.Fatal("pain blessing did not torment its caster")
				}

				bloodied := 0

				for y := position.Y - 2; y <= position.Y+2; y++ {
					for x := position.X - 2; x <= position.X+2; x++ {
						bloody, found := level.CellBlood(x, y)

						if found &&
							level.terrain[y][x] == terrain.Floor &&
							bloody {
							bloodied++
						}
					}
				}

				if bloodied == 0 {
					t.Fatal("pain blessing placed no blood marks")
				}
			}

			finished, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatalf("committed restore: %v", err)
			}

			defer finished.Close()

			if finished.scripts.Components()["religion.weapon_bless_choice"].Has(finished.player) {
				t.Fatal("committed capstone left a pending item")
			}
		})
	}
}

// Put one durable undead target in clear sight. Its 100 HP keeps a source
// 3d15 plus power bonus hit from killing it before the daze can be observed.
func spawnCapstoneLich(t *testing.T, g *Game, levelID int) (akara.Entity, int, int) {
	t.Helper()
	level := g.levels[levelID]
	position, _ := g.stores.Positions.Get(g.player)
	definition, err := testCatalog(t).Monster("MONS_ANCIENT_LICH")

	if err != nil {
		t.Fatal(err)
	}

	for dy := -3; dy <= 3; dy++ {
		for dx := -3; dx <= 3; dx++ {
			x := position.X + dx
			y := position.Y + dy

			if !level.inBounds(x, y) ||
				!level.ClearProjectilePath(position.X, position.Y, x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			lich, err := g.world.CreateEntity()

			if err != nil {
				t.Fatal(err)
			}

			actor := ecs.Actor{
				KindID: "MONS_ANCIENT_LICH",
				Speed:  definition.Speed,
			}

			if _, err := g.stores.Actors.Set(lich, actor); err != nil {
				t.Fatal(err)
			}

			health := ecs.Health{
				Current: 100,
				Max:     100,
			}

			if _, err := g.stores.Health.Set(lich, health); err != nil {
				t.Fatal(err)
			}

			if _, err := g.stores.AI.Set(lich, ecs.MonsterAI{Behavior: "wander"}); err != nil {
				t.Fatal(err)
			}

			if _, err := g.stores.MonsterEnergy.Set(lich, ecs.MonsterEnergy{}); err != nil {
				t.Fatal(err)
			}

			if _, err := g.stores.Combat.Set(lich, ecs.Combatant{}); err != nil {
				t.Fatal(err)
			}

			if err := level.PlaceActor(lich, x, y); err != nil {
				t.Fatal(err)
			}

			return lich, x, y

		}
	}

	t.Fatal("no nearby clear floor for holy word test")

	return 0, 0, 0
}

// Blood is a level property and must survive a save independently of
// the underlying feature. Holy cleansing can then clear it by coordinate.
func TestSavedBloodCellRoundTrip(t *testing.T) {
	g, err := NewDungeonGame(1, "SP_HUMAN", "JOB_FIGHTER", "WPN_LONG_SWORD", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]

	if err := level.SetCellBlood(position.X, position.Y, true); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()

	if snapshot.Version != save.Version {
		t.Fatalf("save version %d", snapshot.Version)
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	bloody, ok := restored.levels[position.LevelID].CellBlood(position.X, position.Y)

	if !ok || !bloody {
		t.Fatal("restored floor lost its blood mark")
	}
}

// The two Kiku menu rows represent one lifetime decision. Either action
// removes the other, even after the committed state has been restored.
func TestKikuCapstoneChoicesExcludeEachOther(t *testing.T) {
	for _, spellsFirst := range []bool{true, false} {
		name := "weapon first"

		if spellsFirst {
			name = "spells first"
		}

		t.Run(name, func(t *testing.T) {
			g, err := NewDungeonGame(1, "SP_HUMAN", "JOB_ABYSSAL_KNIGHT", "WPN_HAND_AXE", "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()

			if _, err := g.scripts.Components()["religion.worship"].Set(g.player, map[string]any{
				"god_id": "GOD_KIKUBAAQUDGHA",
				"piety":  int64(200),
			}); err != nil {
				t.Fatal(err)
			}

			if spellsFirst {
				command := Command{
					Kind:      CommandAbility,
					AbilityID: "ABIL_KIKU_GIFT_CAPSTONE_SPELLS",
				}

				prompt, err := g.Step(command)

				if err != nil {
					t.Fatal(err)
				}

				if prompt.Spent != 0 || prompt.Confirmation == "" {
					t.Fatalf("spell prompt: %+v", prompt)
				}

				command.Forced = true

				result, err := g.Step(command)

				if err != nil {
					t.Fatal(err)
				}

				if result.Spent != 10 {
					t.Fatalf("spell gift spent %d", result.Spent)
				}

				if !playerSpellRecords(t, g)["SPELL_HAUNT"].InLibrary {
					t.Fatal("forbidden knowledge omitted Haunt")
				}
			} else {
				command := Command{
					Kind:      CommandAbility,
					AbilityID: "ABIL_KIKU_BLESS_WEAPON",
				}

				prompt, err := g.Step(command)

				if err != nil {
					t.Fatal(err)
				}

				if prompt.Selection == nil || len(prompt.Selection.Options) == 0 {
					t.Fatalf("weapon prompt: %+v", prompt)
				}

				command.TargetID = prompt.Selection.Options[0].ID

				if _, err := g.Step(command); err != nil {
					t.Fatal(err)
				}

				command.Forced = true

				if _, err := g.Step(command); err != nil {
					t.Fatal(err)
				}
			}

			restored, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatal(err)
			}

			defer restored.Close()

			other := "ABIL_KIKU_GIFT_CAPSTONE_SPELLS"

			if spellsFirst {
				other = "ABIL_KIKU_BLESS_WEAPON"
			}

			denied, err := restored.Step(Command{
				Kind:      CommandAbility,
				AbilityID: other,
			})

			if err != nil {
				t.Fatal(err)
			}

			if denied.Spent != 0 ||
				denied.Selection != nil ||
				denied.Confirmation != "" {
				t.Fatalf("other Kiku capstone remained available: %+v", denied)
			}
		})
	}
}
