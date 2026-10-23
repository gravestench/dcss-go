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

// Stage and populate every authored Trove room through the production
// transaction. A parsed DES file alone cannot reveal a rejected item,
// blocked return arch, or a missing typed source effect.
func TestTroveAllSourceMapsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/trove")

	if err != nil {
		t.Fatal(err)
	}

	directory := os.Getenv("CRAWL_TROVE_SNAPSHOT_DIR")
	var index strings.Builder

	if directory != "" {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}

		index.WriteString("Treasure Trove source rooms, seed 88164 except source veto retries\n")
		index.WriteString("Coordinates are zero-based, origin at top left.\n")
		index.WriteString("Every exit returns to the exact outside test gate.\n\n")
	}

	count := 0

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")
		count++

		t.Run(id, func(t *testing.T) {
			var g *Game
			var stage *stagedLevel
			var outside point
			seed := uint64(88164)

			for attempt := 0; attempt < 24; attempt++ {
				g = newGeneratedTestGame(t, seed)

				if directory != "" {
					outside = placeTrovePortalForTest(t, g)
				}

				stage, err = g.stageGeneratedLevel(
					"world.generate_trove_level",
					map[string]any{
						"species_id":  "SP_HUMAN",
						"player_name": "Tester",
						"layout_id":   id,
					},
				)

				if err == nil {
					break
				}

				if id != "trove_library" ||
					!strings.Contains(err.Error(), "veto shared.library_eligible rejected placement") {
					t.Fatal(err)
				}

				seed++
			}

			if err != nil {
				t.Fatal("source library veto never admitted its rare exception: ", err)
			}

			defer func() {
				if err := stage.rollback(); err != nil {
					t.Error(err)
				}
			}()

			floor := g.levels[stage.levelID]

			if floor == nil || floor.BranchID != "BRANCH_TROVE" ||
				floor.VaultID() != id || len(floor.VaultRecords()) == 0 {
				t.Fatalf("Trove %s lost its source records", id)
			}

			var exits []point

			for y, row := range floor.Cells() {
				for x, cell := range row {
					if cell == terrain.ExitTrove {
						exits = append(exits, point{
							x: x,
							y: y,
						})
					}
				}
			}

			if len(exits) == 0 {
				t.Fatalf("Trove %s has no return arch", id)
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

			name := id + ".txt"
			body := formatLevelTextSnapshot(record, nil)
			var connections strings.Builder

			for _, exit := range exits {
				fmt.Fprintf(&connections,
					"Trove exit (%d,%d) -> Dungeon:1 (%d,%d), exact outside gate\n",
					exit.x, exit.y, outside.x, outside.y)
			}

			body += connections.String()

			if err := os.WriteFile(filepath.Join(directory, name),
				[]byte(body), 0o644); err != nil {
				t.Fatal(err)
			}

			fmt.Fprintf(&index, "%s  %s  seed: %d  return arches: %d\n",
				id, name, seed, len(exits))
			index.WriteString(connections.String())
		})
	}

	if count != 21 {
		t.Fatalf("expected 21 Trove reward maps, got %d", count)
	}

	if directory != "" {
		if err := os.WriteFile(filepath.Join(directory, "index.txt"),
			[]byte(index.String()), 0o644); err != nil {
			t.Fatal(err)
		}
	}
}
