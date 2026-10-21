package game

import (
	"slices"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Descend through the actual Hell portal command on each saved level. This
// exercises the rootless travel policy, staging, source map, population,
// and save validator together at the first full-size Hell floor.
func hellEndRun(t *testing.T, gate terrain.ID) (*Game, *Level, int) {
	t.Helper()

	g := newGeneratedTestGame(t, 8317)
	placePortalForTest(t, g, terrain.EnterHell)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max

	health.Max = 100000
	health.Current = health.Max

	placePortalForTest(t, g, gate)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]

	for level.LocalDepth < 7 {
		var stair point
		found := false

		for y, row := range level.Cells() {
			for x, feature := range row {
				if feature == terrain.StairsDown {
					stair = point{
						x: x,
						y: y,
					}

					found = true
					break
				}
			}

			if found {
				break
			}
		}

		if !found {
			t.Fatalf("%s:%d has no descent", level.BranchID,
				level.LocalDepth)
		}

		if blocker, occupied := level.ActorAt(stair.x, stair.y); occupied {
			moved := false

			for y, row := range level.Cells() {
				for x, feature := range row {
					if feature != terrain.Floor {
						continue
					}

					if _, taken := level.ActorAt(x, y); taken {
						continue
					}

					if err := level.MoveActor(blocker, x, y); err != nil {
						t.Fatal(err)
					}

					moved = true
					break
				}

				if moved {
					break
				}
			}

			if !moved {
				t.Fatal("Hell floor has no free cell for stair blocker")
			}
		}

		if err := level.MoveActor(g.player, stair.x, stair.y); err != nil {
			t.Fatal(err)
		}

		previous := level
		// Ordinary Hell monsters may sing while the traversal helper moves
		// between floors. Clear that combat state before testing the stairs.
		g.scripts.Components()["character.player_mesmerism"].Remove(g.player)
		result, err := g.Step(Command{Kind: CommandDownstairs})

		if err != nil {
			t.Fatalf("%s:%d descent: %v", level.BranchID,
				level.LocalDepth, err)
		}

		position, _ = g.stores.Positions.Get(g.player)
		level = g.levels[position.LevelID]

		if level == previous {
			t.Fatalf("%s:%d descent stayed on floor: spent %d, events %v",
				previous.BranchID, previous.LocalDepth, result.Spent,
				result.Events)
		}
	}

	return g, level, originalMax
}

// Each source ending must produce one historical rune site and retain its
// selected primary map after save/restore. The live rune can later be picked
// up, so the record is the durable check here.
func TestHellSeventhFloorEndings(t *testing.T) {
	cases := []struct {
		name   string
		gate   terrain.ID
		escape terrain.ID
		branch string
		runeID string
		bossID string
	}{
		{
			name:   "Dis",
			gate:   terrain.EnterDis,
			escape: terrain.ExitDis,
			branch: "BRANCH_DIS",
			runeID: "RUNE_DIS",
			bossID: "MONS_DISPATER",
		},

		{
			name:   "Geh",
			gate:   terrain.EnterGehenna,
			escape: terrain.ExitGehenna,
			branch: "BRANCH_GEHENNA",
			runeID: "RUNE_GEHENNA",
			bossID: "MONS_ASMODEUS",
		},

		{
			name:   "Coc",
			gate:   terrain.EnterCocytus,
			escape: terrain.ExitCocytus,
			branch: "BRANCH_COCYTUS",
			runeID: "RUNE_COCYTUS",
			bossID: "MONS_ANTAEUS",
		},

		{
			name:   "Tar",
			gate:   terrain.EnterTartarus,
			escape: terrain.ExitTartarus,
			branch: "BRANCH_TARTARUS",
			runeID: "RUNE_TARTARUS",
			bossID: "MONS_ERESHKIGAL",
		},
	}

	for _, selected := range cases {
		t.Run(selected.name, func(t *testing.T) {
			g, end, originalMax := hellEndRun(t, selected.gate)

			if end.BranchID != selected.branch ||
				end.LocalDepth != 7 ||
				end.width != 80 ||
				len(end.terrain) != 70 ||
				end.VaultID() == "" ||
				!slices.Contains(end.VaultIDs(), end.VaultID()) {
				t.Fatalf("invalid %s ending %s:%d vault %q ids %v",
					selected.name, end.BranchID, end.LocalDepth,
					end.VaultID(), end.VaultIDs())
			}

			runes := 0
			bosses := 0
			down := 0
			exits := 0

			for _, record := range end.VaultRecords() {
				if runeRecord(record, selected.runeID) {
					runes++
				}

				if record.Kind == vault.KindMonster {
					for _, argument := range record.Arguments {
						if argument.Name == "kind_id" &&
							argument.String == selected.bossID {
							bosses++
						}
					}
				}
			}

			for _, row := range end.Cells() {
				for _, feature := range row {
					if feature == terrain.StairsDown {
						down++
					}

					if feature == selected.escape {
						exits++
					}
				}
			}

			if runes != 1 ||
				bosses != 1 ||
				down != 0 ||
				exits == 0 {
				t.Fatalf("%s ending: runes %d, monster records %d, down %d, exits %d",
					selected.name, runes, bosses, down, exits)
			}

			resetHellTestHealth(g, originalMax, originalMax)

			restored, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatalf("%s end failed restore: %v", selected.name, err)
			}

			_ = restored.Close()
		})
	}
}
