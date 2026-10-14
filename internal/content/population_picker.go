package content

import "fmt"

type weightedDungeonMonster struct {
	id     string
	weight int
}

// DungeonMonsterPool is one depth's source-ordered, immutable selection table.
// The caller owns the RNG and supplies a roll in [0, TotalWeight()).
type DungeonMonsterPool struct {
	rows  []weightedDungeonMonster
	total int
}

// DungeonMonsterPool applies the source picker's depth and veto filters before
// summing row weights. Duplicate monster IDs remain separate rows.
func (c Catalog) DungeonMonsterPool(depth int, veto func(string) bool) DungeonMonsterPool {
	var pool DungeonMonsterPool

	for _, row := range c.dungeonPopulation {
		if depth < row.MinDepth || depth > row.MaxDepth || veto != nil && veto(row.MonsterID) {
			continue
		}

		weight := row.WeightAtDepth(depth)

		if weight <= 0 {
			continue
		}

		pool.rows = append(pool.rows, weightedDungeonMonster{
			id:     row.MonsterID,
			weight: weight,
		})
		pool.total += weight
	}

	return pool
}

func (p DungeonMonsterPool) TotalWeight() int {
	return p.total
}

// Pick maps a caller-owned random roll to the first source row containing it.
// An empty pool returns the source picker's no-monster result without a draw.
func (p DungeonMonsterPool) Pick(roll int) (string, error) {
	if p.total == 0 {
		return "", nil
	}

	if roll < 0 || roll >= p.total {
		return "", fmt.Errorf("Dungeon monster roll %d outside [0,%d)", roll, p.total)
	}

	for _, row := range p.rows {
		if roll < row.weight {
			return row.id, nil
		}

		roll -= row.weight
	}

	return "", fmt.Errorf("Dungeon monster pool has inconsistent total weight")
}
