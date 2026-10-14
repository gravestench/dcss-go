package content

import (
	"strings"
	"testing"
)

func TestCommittedDungeonPopulationCoverageAndCopies(t *testing.T) {
	catalog, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	rows := catalog.DungeonPopulation()

	if len(rows) != 125 || rows[0].MonsterID != "MONS_BAT" || rows[len(rows)-1].MonsterID != "MONS_IRON_DRAGON" {
		t.Fatalf("Dungeon population has %d rows, first %+v, last %+v", len(rows), rows[0], rows[len(rows)-1])
	}

	ratRows, quokkaRows := 0, 0

	for _, row := range rows {
		switch row.MonsterID {
		case "MONS_RAT":
			ratRows++

			if row.WeightAtDepth(1) != 2520000 {
				t.Fatalf("D:1 rat weight = %d", row.WeightAtDepth(1))
			}
		case "MONS_QUOKKA":
			quokkaRows++
		}
	}

	if ratRows != 1 || quokkaRows != 2 {
		t.Fatalf("rat rows %d, quokka rows %d", ratRows, quokkaRows)
	}

	rows[0].MonsterID = "MONS_BOGUS"

	if catalog.DungeonPopulation()[0].MonsterID != "MONS_BAT" {
		t.Fatal("population rows alias catalog")
	}
}

func TestCommittedDungeonPopulationRejectsSameCountSubstitution(t *testing.T) {
	altered := strings.Replace(string(defaultDungeonPopulationJSON), `"MONS_RAT"`, `"MONS_BAT"`, 1)

	if _, err := attachDefaultDungeonPopulation(scenarioCatalog(), []byte(altered)); err == nil {
		t.Fatal("accepted changed Dungeon population bytes")
	}
}
