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
)

// formatLevelTextSnapshot shows the complete generated grid, without player
// visibility or actor glyphs hiding the terrain used to connect floors.
func formatLevelTextSnapshot(
	level save.LevelRecord,
	levels map[int]save.LevelRecord,
) string {
	var out strings.Builder

	fmt.Fprintf(&out, "%s (level ID %d)\n", floorName(level), level.ID)

	if level.VaultID != "" {
		fmt.Fprintf(&out, "Vault: %s\n", level.VaultID)
	}

	fmt.Fprintf(&out, "Map: %d x %d (x right, y down)\n", mapWidth(level.Cells), len(level.Cells))

	for y, row := range level.Cells {
		fmt.Fprintf(&out, "%02d ", y)

		for _, feature := range row {
			out.WriteRune(terrain.Glyph(feature))
		}

		out.WriteByte('\n')
	}

	out.WriteString("\nConnections:\n")

	for _, line := range levelConnectionLines(level, levels) {
		fmt.Fprintf(&out, "  %s\n", line)
	}

	return out.String()
}

func mapWidth(cells [][]terrain.ID) int {
	if len(cells) == 0 {
		return 0
	}

	return len(cells[0])
}

func floorName(level save.LevelRecord) string {
	return fmt.Sprintf("%s:%d", branchName(level.BranchID), level.LocalDepth)
}

func branchName(id string) string {
	branch := strings.TrimPrefix(id, "BRANCH_")

	if branch == "DUNGEON" {
		return "Dungeon"
	}

	return branch
}

// Saved stair links, rather than matching glyphs by eye, carry the exact
// destination. A frontier link has no arrival coordinates until first entry.
func levelConnectionLines(
	level save.LevelRecord,
	levels map[int]save.LevelRecord,
) []string {
	stairs := append([]save.StairRecord(nil), level.Stairs...)

	sort.Slice(stairs, func(i, j int) bool {
		if stairs[i].Y != stairs[j].Y {
			return stairs[i].Y < stairs[j].Y
		}

		return stairs[i].X < stairs[j].X
	})

	lines := make([]string, 0, len(stairs))

	for _, stair := range stairs {
		feature := level.Cells[stair.Y][stair.X]
		origin := fmt.Sprintf("(%d,%d) %c", stair.X, stair.Y, terrain.Glyph(feature))
		lines = append(lines, fmt.Sprintf("%s -> %s", origin, stairDestination(stair, level, levels)))
	}

	return lines
}

func stairDestination(
	stair save.StairRecord,
	level save.LevelRecord,
	levels map[int]save.LevelRecord,
) string {
	if stair.Exit {
		return "outside the dungeon"
	}

	if stair.Unavailable != "" {
		return fmt.Sprintf("unavailable: %s", stair.Unavailable)
	}

	target, generated := levels[stair.ToLevelID]
	targetName := fmt.Sprintf("level ID %d", stair.ToLevelID)

	if generated {
		targetName = floorName(target)
	} else if stair.TargetBranchID != "" {
		targetName = fmt.Sprintf(
			"%s (level ID %d)",
			branchName(stair.TargetBranchID),
			stair.ToLevelID,
		)
	} else if level.BranchID == "BRANCH_DUNGEON" {
		targetName = fmt.Sprintf("Dungeon:%d", stair.ToLevelID)
	}

	if stair.Pending {
		return targetName + " (pending)"
	}

	return fmt.Sprintf("%s (%d,%d)", targetName, stair.ToX, stair.ToY)
}

// The exporter runs only when explicitly requested. Keeping its output
// outside the ordinary test path avoids rewriting checked-in examples while
// still letting anyone regenerate them from a real 15-floor test run.
func writeGeneratedDungeonTextSnapshots(
	snapshot save.Snapshot,
	directory string,
) error {
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return err
	}

	levels := make(map[int]save.LevelRecord, len(snapshot.Levels))

	for _, level := range snapshot.Levels {
		levels[level.ID] = level
	}

	var index strings.Builder

	fmt.Fprintf(&index, "Generated Dungeon, seed %d\n", snapshot.Seed)
	index.WriteString("Coordinates are zero-based: (x,y), origin at top left.\n")
	index.WriteString("A pending stair generates its destination on first entry.\n\n")

	for depth := 1; depth <= 15; depth++ {
		level, found := levels[depth]

		if !found ||
			level.BranchID != "BRANCH_DUNGEON" ||
			level.LocalDepth != depth {
			return fmt.Errorf("snapshot has no Dungeon:%d", depth)
		}

		filename := fmt.Sprintf("D-%02d.txt", depth)
		body := formatLevelTextSnapshot(level, levels)

		if err := os.WriteFile(filepath.Join(directory, filename), []byte(body), 0o644); err != nil {
			return err
		}

		fmt.Fprintf(&index, "%s  %s", floorName(level), filename)

		if level.VaultID != "" {
			fmt.Fprintf(&index, "  vault %s", level.VaultID)
		}

		index.WriteString("\n")

		for _, line := range levelConnectionLines(level, levels) {
			fmt.Fprintf(&index, "  %s\n", line)
		}

		if depth < 15 {
			index.WriteString("\n")
		}
	}

	return os.WriteFile(
		filepath.Join(directory, "index.txt"),
		[]byte(index.String()),
		0o644,
	)
}

// A changed destination or dropped pending marker must be visible to a
// human inspecting the exported map, even when the terrain glyph is the same.
func TestLevelTextSnapshotShowsTerrainAndStairDestinations(t *testing.T) {
	level := save.LevelRecord{
		ID:         2,
		BranchID:   "BRANCH_DUNGEON",
		LocalDepth: 2,
		Cells: [][]terrain.ID{
			{
				terrain.RockWall,
				terrain.StairsUp,
				terrain.Floor,
			},

			{
				terrain.Floor,
				terrain.StairsDown,
				terrain.RockWall,
			},
		},
		Stairs: []save.StairRecord{
			{
				X:         1,
				Y:         0,
				ToLevelID: 1,
				ToX:       2,
				ToY:       3,
			},

			{
				X:         1,
				Y:         1,
				ToLevelID: 3,
				Pending:   true,
			},
		},
	}

	got := formatLevelTextSnapshot(level, map[int]save.LevelRecord{
		1: {
			ID:         1,
			BranchID:   "BRANCH_DUNGEON",
			LocalDepth: 1,
		},
		2: level,
	})

	for _, want := range []string{
		"Dungeon:2",
		"#<.",
		".>#",
		"(1,0) < -> Dungeon:1 (2,3)",
		"(1,1) > -> Dungeon:3 (pending)",
	} {
		if !strings.Contains(got, want) {
			t.Errorf("snapshot missing %q:\n%s", want, got)
		}
	}
}
