package content

import "testing"

func TestDungeonMonsterPoolPreservesSourceRowsAndBoundaries(t *testing.T) {
	c := Catalog{
		dungeonPopulation: []DungeonPopEntry{
			{
				MinDepth:  1,
				MaxDepth:  3,
				Rarity:    2,
				Curve:     "FLAT",
				MonsterID: "MONS_RAT",
			},
			{
				MinDepth:  2,
				MaxDepth:  4,
				Rarity:    3,
				Curve:     "RISE",
				MonsterID: "MONS_QUOKKA",
			},
			{
				MinDepth:  2,
				MaxDepth:  4,
				Rarity:    1,
				Curve:     "FALL",
				MonsterID: "MONS_RAT",
			},
		},
	}
	pool := c.DungeonMonsterPool(2, nil)
	first, second, third := 2*2520, 3*2520/3, 3*2520/3
	if got, want := pool.TotalWeight(), first+second+third; got != want {
		t.Fatalf("total = %d, want %d", got, want)
	}

	for _, tc := range []struct {
		roll int
		want string
	}{
		{
			roll: 0,
			want: "MONS_RAT",
		},
		{
			roll: first - 1,
			want: "MONS_RAT",
		},
		{
			roll: first,
			want: "MONS_QUOKKA",
		},
		{
			roll: first + second - 1,
			want: "MONS_QUOKKA",
		},
		{
			roll: first + second,
			want: "MONS_RAT",
		},
		{
			roll: pool.TotalWeight() - 1,
			want: "MONS_RAT",
		},
	} {
		got, err := pool.Pick(tc.roll)
		if err != nil || got != tc.want {
			t.Fatalf("roll %d = %q, %v; want %q", tc.roll, got, err, tc.want)
		}
	}

	for _, roll := range []int{-1, pool.TotalWeight()} {
		if _, err := pool.Pick(roll); err == nil {
			t.Fatalf("out-of-range roll %d accepted", roll)
		}
	}
}

func TestDungeonMonsterPoolVetoAndEmpty(t *testing.T) {
	c := Catalog{
		dungeonPopulation: []DungeonPopEntry{
			{
				MinDepth:  1,
				MaxDepth:  2,
				Rarity:    2,
				Curve:     "FLAT",
				MonsterID: "MONS_RAT",
			},
			{
				MinDepth:  1,
				MaxDepth:  2,
				Rarity:    3,
				Curve:     "FLAT",
				MonsterID: "MONS_QUOKKA",
			},
			{
				MinDepth:  1,
				MaxDepth:  2,
				Rarity:    1,
				Curve:     "FLAT",
				MonsterID: "MONS_RAT",
			},
		},
	}
	pool := c.DungeonMonsterPool(1, func(id string) bool {
		return id == "MONS_RAT"
	})
	if pool.TotalWeight() != 3*2520 {
		t.Fatalf("vetoed total = %d", pool.TotalWeight())
	}

	if got, err := pool.Pick(pool.TotalWeight() - 1); err != nil || got != "MONS_QUOKKA" {
		t.Fatalf("vetoed pick = %q, %v", got, err)
	}

	for _, empty := range []DungeonMonsterPool{
		c.DungeonMonsterPool(3, nil),
		c.DungeonMonsterPool(1, func(string) bool {
			return true
		}),
	} {
		if empty.TotalWeight() != 0 {
			t.Fatalf("empty total = %d", empty.TotalWeight())
		}

		if got, err := empty.Pick(0); err != nil || got != "" {
			t.Fatalf("empty pick = %q, %v", got, err)
		}
	}
}

func TestDefaultDungeonMonsterPoolUsesPinnedD1Rows(t *testing.T) {
	c, err := LoadDefault()
	if err != nil {
		t.Fatal(err)
	}

	pool := c.DungeonMonsterPool(1, nil)
	for _, tc := range []struct {
		roll int
		want string
	}{
		{
			roll: 0,
			want: "MONS_BAT",
		},
		{
			roll: 1000*2520 - 1,
			want: "MONS_BAT",
		},
		{
			roll: 1000 * 2520,
			want: "MONS_RAT",
		},
	} {
		got, err := pool.Pick(tc.roll)
		if err != nil || got != tc.want {
			t.Fatalf("D:1 roll %d = %q, %v; want %q", tc.roll, got, err, tc.want)
		}
	}
}
