package game

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"crawl/internal/save"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Every parent layout must populate through the same staged transaction
// used by entry. This catches authored monsters, rewards, and nested links
// that a parser-only test cannot inspect.
func TestGauntletAllParentLayoutsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/gauntlet")

	if err != nil {
		t.Fatal(err)
	}

	directory := os.Getenv("CRAWL_GAUNTLET_SNAPSHOT_DIR")
	var index strings.Builder
	count := 0

	if directory != "" {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}

		index.WriteString("Gauntlet parent layouts, seed 99144\n")
		index.WriteString("Coordinates are zero-based; all floors are 80 by 70.\n\n")
	}

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")

		if file.IsDir() || !strings.HasSuffix(file.Name(), ".des") {
			continue
		}

		count++
		t.Run(id, func(t *testing.T) {
			source, err := os.ReadFile(filepath.Join(
				"../modfs/builtin/vaults/gauntlet", file.Name()))

			if err != nil {
				t.Fatal(err)
			}

			mapStart := strings.Index(string(source), "\nMAP\n")
			mapEnd := strings.Index(string(source), "\nENDMAP")

			if mapStart < 0 || mapEnd <= mapStart {
				t.Fatalf("missing parent MAP in %s", file.Name())
			}

			parentArches := strings.Count(
				string(source)[mapStart:mapEnd], "<")
			g := newGeneratedTestGame(t, 99144)
			stage, err := g.stageGeneratedLevel(
				"world.generate_gauntlet_level",
				map[string]any{
					"species_id":  "SP_HUMAN",
					"player_name": "Tester",
					"layout_id":   id,
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
				floor.BranchID != "BRANCH_GAUNTLET" ||
				floor.VaultID() != id ||
				len(floor.VaultIDs()) < 3 {
				t.Fatalf("incomplete Gauntlet floor for %s", id)
			}

			exits := 0

			for _, row := range floor.Cells() {
				for _, feature := range row {
					if feature == terrain.ExitGauntlet {
						exits++
					}
				}
			}

			if exits != parentArches+1 {
				t.Fatalf("Gauntlet %s has %d arches; parent has %d and boss room must add one",
					id, exits, parentArches)
			}

			links := gauntletLinkSnapshot(floor.VaultRecords())

			if len(links) == 0 {
				t.Fatalf("Gauntlet %s has no resolved transporter route", id)
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
			body += "Source parent: " + id + "\n"
			body += "Nested maps: " + strings.Join(floor.VaultIDs()[1:], ", ") + "\n"
			body += fmt.Sprintf("Return arches: %d\n", exits)
			body += "Transporter routes:\n" + strings.Join(links, "\n") + "\n"

			if err := os.WriteFile(filepath.Join(directory, id+".txt"),
				[]byte(body), 0o644); err != nil {
				t.Fatal(err)
			}

			fmt.Fprintf(&index, "%s: %d nested maps, %d routes, %d exits\n",
				id, len(floor.VaultIDs())-1, len(links), exits)
		})
	}

	if count != 10 {
		t.Fatalf("expected ten source parent layouts, got %d", count)
	}

	if directory != "" {
		if err := os.WriteFile(filepath.Join(directory, "index.txt"),
			[]byte(index.String()), 0o644); err != nil {
			t.Fatal(err)
		}
	}
}

// Source records keep explicit target coordinates so the text snapshots
// show actual routes, including links across nested arena boundaries.
func gauntletLinkSnapshot(records []vault.Record) []string {
	var links []string

	for _, record := range records {
		if record.Kind != vault.KindMarker ||
			!strings.HasPrefix(record.Identity, "lua:transp_loc(") {
			continue
		}

		var x string
		var y string

		for _, argument := range record.Arguments {
			switch argument.Name {
			case "transporter_destination_x":
				x = argument.String

			case "transporter_destination_y":
				y = argument.String
			}
		}

		links = append(links, fmt.Sprintf("  %s (%d,%d) -> (%s,%s)",
			record.Identity, record.X, record.Y, x, y))
	}

	sort.Strings(links)

	return links
}
