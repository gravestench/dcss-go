package game

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/save"
	"crawl/internal/terrain"
)

// Each source child and saved difficulty must survive the actual staging
// and population path. The optional text export uses these same floors.
func TestIceCaveAllSourceMapsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/ice_cave")

	if err != nil {
		t.Fatal(err)
	}

	count := 0
	directory := os.Getenv("CRAWL_ICE_CAVE_SNAPSHOT_DIR")
	var index strings.Builder
	var hardBaseline save.Snapshot

	if directory != "" {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}

		index.WriteString("Ice Cave source layouts, seed 88164\n")
		index.WriteString("Coordinates are zero-based: (x,y), origin at top left.\n")
		index.WriteString("Easy uses a Dungeon:1 test gate; hard uses a Dungeon:14 gate.\n")
		index.WriteString("Live entrances spawn from D:11.\n\n")

		// Keep one real D:14 prefix and restore it for each hard map.
		// Replaying thirteen floor generations per map adds no coverage.
		baseline := newGeneratedTestGame(t, 88164)
		descendGeneratedTo(t, baseline, 14)
		hardBaseline = baseline.Snapshot()
	}

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")
		count++

		for _, hard := range []bool{false, true} {
			variant := "easy"

			if hard {
				variant = "hard"
			}

			t.Run(id+"/"+variant, func(t *testing.T) {
				// A fresh session keeps unique artefacts from a prior source
				// map from excluding this independently requested variant.
				var g *Game

				if hard && directory != "" {
					g, err = Restore(hardBaseline)

					if err != nil {
						t.Fatal(err)
					}

					t.Cleanup(func() {
						_ = g.Close()
					})
				} else {
					g = newGeneratedTestGame(t, 88164)
				}

				var returnSite point
				originDepth := 1

				if directory != "" {
					returnSite = placeIceCavePortalForTest(t, g, hard)

					if hard {
						originDepth = 14
					}
				}

				stage, err := g.stageGeneratedLevel(
					"world.generate_ice_cave_level",
					map[string]any{
						"species_id":  "SP_HUMAN",
						"player_name": "Tester",
						"layout_id":   id,
						"hard":        hard,
					},
				)

				if err != nil {
					t.Fatal(err)
				}

				defer func() {
					if err := stage.rollback(); err != nil {
						t.Error(err)
					}
				}()

				floor := g.levels[stage.levelID]

				if floor == nil ||
					floor.BranchID != "BRANCH_ICE_CAVE" ||
					floor.VaultID() != id ||
					len(floor.VaultRecords()) == 0 {
					t.Fatalf("populated Ice Cave %s lost source records", id)
				}

				var exits []point

				for y, row := range floor.Cells() {
					for x, cell := range row {
						if cell != terrain.ExitIceCave {
							continue
						}

						exits = append(exits, point{
							x: x,
							y: y,
						})
					}
				}

				if len(exits) == 0 {
					t.Fatalf("populated Ice Cave %s has no return exit", id)
				}

				if directory == "" {
					return
				}

				var record save.LevelRecord

				for _, candidate := range g.Snapshot().Levels {
					if candidate.ID == floor.ID {
						record = candidate
						break
					}
				}

				body := formatLevelTextSnapshot(record, nil)
				name := id + "_" + variant + ".txt"
				var connections strings.Builder

				for _, exit := range exits {
					fmt.Fprintf(&connections,
						"Ice Cave exit (%d,%d) -> Dungeon:%d (%d,%d), exact outside gate\n",
						exit.x, exit.y, originDepth,
						returnSite.x, returnSite.y)
				}

				body += connections.String()

				if err := os.WriteFile(filepath.Join(directory, name),
					[]byte(body), 0o644); err != nil {
					t.Fatal(err)
				}

				fmt.Fprintf(&index, "%s  %s\n%s", variant, name,
					connections.String())
			})
		}
	}

	if count != 11 {
		t.Fatalf("expected 11 source Ice Cave layouts, got %d", count)
	}

	if directory != "" {
		if err := os.WriteFile(filepath.Join(directory, "index.txt"),
			[]byte(index.String()), 0o644); err != nil {
			t.Fatal(err)
		}
	}
}
