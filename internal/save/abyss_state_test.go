package save

import (
	"testing"

	"crawl/internal/terrain"
)

// A procedural state is saved beside the one mutable level. Rejecting a
// malformed queue before restore prevents the next morph from indexing
// outside the grid or silently changing the generated world.
func TestValidateAbyssState(t *testing.T) {
	valid := &AbyssStateRecord{
		BranchDepth:     2,
		MorphDepth:      100,
		WorldX:          13,
		WorldY:          17,
		TerrainSeed:     42,
		Phase:           0.25,
		BorrowedLevelID: 1,

		BorrowedLayout: [][]terrain.ID{
			{
				terrain.RockWall,
				terrain.RockWall,
				terrain.RockWall,
			},

			{
				terrain.RockWall,
				terrain.Floor,
				terrain.RockWall,
			},

			{
				terrain.RockWall,
				terrain.RockWall,
				terrain.RockWall,
			},
		},

		SampleQueue: []AbyssSampleRecord{
			{
				X:       1,
				Y:       1,
				Change:  101,
				Feature: terrain.Floor,
			},
		},

		ExitXP:         10,
		MinBranchDepth: 1,
	}

	if err := ValidateAbyssState(valid); err != nil {
		t.Fatalf("valid Abyss state rejected: %v", err)
	}

	cases := []struct {
		name   string
		change func(*AbyssStateRecord)
	}{
		{
			name: "branch depth",
			change: func(state *AbyssStateRecord) {
				state.BranchDepth = 8
			},
		},

		{
			name: "phase",
			change: func(state *AbyssStateRecord) {
				state.Phase = -1
			},
		},

		{
			name: "queue coordinate",
			change: func(state *AbyssStateRecord) {
				state.SampleQueue[0].X = 80
			},
		},

		{
			name: "borrowed row",
			change: func(state *AbyssStateRecord) {
				state.BorrowedLayout[1] = []terrain.ID{terrain.Floor}
			},
		},

		{
			name: "duplicate queue",
			change: func(state *AbyssStateRecord) {
				state.SampleQueue = append(state.SampleQueue,
					state.SampleQueue[0])
			},
		},

		{
			name: "duplicate transit slot",
			change: func(state *AbyssStateRecord) {
				state.Transit = []AbyssTransitRecord{
					{
						EntityID: 12,
						X:        1,
						Y:        1,
					},

					{
						EntityID: 13,
						X:        1,
						Y:        1,
					},
				}
			},
		},

		{
			name: "transit boundary",
			change: func(state *AbyssStateRecord) {
				state.Transit = []AbyssTransitRecord{
					{
						EntityID: 12,
						X:        0,
						Y:        1,
					},
				}
			},
		},
	}

	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			copy := *valid

			copy.SampleQueue = append([]AbyssSampleRecord(nil),
				valid.SampleQueue...)
			copy.BorrowedLayout = append([][]terrain.ID(nil),
				valid.BorrowedLayout...)

			test.change(&copy)

			if err := ValidateAbyssState(&copy); err == nil {
				t.Fatal("malformed Abyss state was accepted")
			}
		})
	}
}
