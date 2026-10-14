package populationimport

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
)

var populationRow = regexp.MustCompile(
	`^\s*\{\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(\d+)\s*,` +
		`\s*(FLAT|SEMI|PEAK|RISE|FALL)\s*,\s*(MONS_[A-Z0-9_]+)` +
		`\s*\}\s*,?\s*(?://.*)?$`,
)

func parseDungeonRows(source []byte) ([]content.DungeonPopEntry, error) {
	lines := strings.Split(string(source), "\n")
	foundTable, foundDungeon := false, false
	var rows []content.DungeonPopEntry

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		if !foundTable {
			foundTable = strings.Contains(line, "static const vector<pop_entry> population[]")
			continue
		}

		if !foundDungeon {
			if strings.HasPrefix(trimmed, "{ // Dungeon") {
				foundDungeon = true
			}

			continue
		}

		if trimmed == "}," {
			if len(rows) == 0 {
				return nil, fmt.Errorf("Dungeon population is empty")
			}

			return rows, nil
		}

		if trimmed == "" || strings.HasPrefix(trimmed, "//") {
			continue
		}

		match := populationRow.FindStringSubmatch(line)

		if match == nil {
			return nil, fmt.Errorf("unparsed Dungeon population line %d: %q", i+1, line)
		}

		minDepth, minErr := strconv.Atoi(match[1])
		maxDepth, maxErr := strconv.Atoi(match[2])
		rarity, rarityErr := strconv.Atoi(match[3])

		if minErr != nil ||
			maxErr != nil ||
			rarityErr != nil {
			return nil, fmt.Errorf("invalid Dungeon population number at line %d", i+1)
		}

		rows = append(rows, content.DungeonPopEntry{
			MinDepth:   minDepth,
			MaxDepth:   maxDepth,
			Rarity:     rarity,
			Curve:      match[4],
			MonsterID:  match[5],
			SourceLine: i + 1,
		})
	}

	return nil, fmt.Errorf("pinned Dungeon population table or closing delimiter is missing")
}
