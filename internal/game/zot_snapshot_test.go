package game

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"crawl/internal/save"
)

// Export the actual route that the Zot integration test traveled. The
// index shows each stair target while each floor file keeps its full text
// map, so a reader can follow the gate through the Hall of Zot.
func writeZotRouteTextSnapshots(snapshot save.Snapshot, directory string) error {
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return err
	}

	levels := make(map[int]save.LevelRecord, len(snapshot.Levels))
	var route []save.LevelRecord

	for _, level := range snapshot.Levels {
		levels[level.ID] = level

		if level.BranchID == "BRANCH_DEPTHS" && level.LocalDepth == 4 {
			route = append(route, level)
		}
	}

	for depth := 1; depth <= 5; depth++ {
		found := false

		for _, level := range snapshot.Levels {
			if level.BranchID == "BRANCH_ZOT" &&
				level.LocalDepth == depth {
				route = append(route, level)
				found = true

				break
			}
		}

		if !found {
			return fmt.Errorf("Zot text snapshot has no floor %d", depth)
		}
	}

	if len(route) != 6 {
		return fmt.Errorf("Zot text snapshot lacks the Depths:4 gate")
	}

	var index strings.Builder

	fmt.Fprintf(&index, "Depths:4 to Zot:5, seed %d\n", snapshot.Seed)
	index.WriteString("Coordinates are zero-based; stair targets name linked floors.\n\n")

	for indexInRoute, level := range route {
		name := fmt.Sprintf("%s-%02d.txt", level.BranchID, level.LocalDepth)
		body := formatLevelTextSnapshot(level, levels)

		if err := os.WriteFile(filepath.Join(directory, name),
			[]byte(body), 0o644); err != nil {
			return err
		}

		fmt.Fprintf(&index, "%s  %s\n", floorName(level), name)

		for _, line := range levelConnectionLines(level, levels) {
			fmt.Fprintf(&index, "  %s\n", line)
		}

		if indexInRoute < len(route)-1 {
			index.WriteString("\n")
		}
	}

	return os.WriteFile(filepath.Join(directory, "index.txt"),
		[]byte(index.String()), 0o644)
}
