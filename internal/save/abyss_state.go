package save

import (
	"fmt"
	"math"

	"crawl/internal/terrain"
)

const (
	abyssWidth  = 80
	abyssHeight = 70
	abyssBottom = 7
)

// AbyssStateRecord is the independent moving-window clock and history.
// The level record owns the visible grid; this record fixes its procedural
// world coordinate so restore never samples a different region.
type AbyssStateRecord struct {
	BranchDepth int     `json:"branch_depth"`
	MorphDepth  uint64  `json:"morph_depth"`
	Phase       float64 `json:"phase"`
	WorldX      int64   `json:"world_x"`
	WorldY      int64   `json:"world_y"`
	TerrainSeed uint32  `json:"terrain_seed"`
	ShiftCount  int     `json:"shift_count"`

	BorrowedLevelID int                 `json:"borrowed_level_id"`
	BorrowedLayout  [][]terrain.ID      `json:"borrowed_layout"`
	SampleQueue     []AbyssSampleRecord `json:"sample_queue"`

	ExitXP         int               `json:"exit_xp"`
	ExitSpawned    bool              `json:"exit_spawned"`
	MinBranchDepth int               `json:"min_branch_depth"`
	PocketStart    bool              `json:"pocket_start"`
	ReturnSite     *ReturnSiteRecord `json:"return_site,omitempty"`

	SelectedMapIDs []string             `json:"selected_map_ids"`
	Transit        []AbyssTransitRecord `json:"transit"`
}

// Each saved sample is an interior coordinate and the depth at which
// its current candidate terrain is next eligible to morph.
type AbyssSampleRecord struct {
	X       int        `json:"x"`
	Y       int        `json:"y"`
	Change  uint64     `json:"change"`
	Feature terrain.ID `json:"feature"`
}

// A transiting actor remains owned by Akara on the inert reserve level.
// Its saved ID and reserve coordinate prevent a duplicate return.
type AbyssTransitRecord struct {
	EntityID uint64 `json:"entity_id"`
	X        int    `json:"x"`
	Y        int    `json:"y"`
}

// ValidateAbyssState rejects a malformed procedural record before the
// game exposes a restored run. Cross-checks against live ECS and level
// ownership are the session's responsibility.
func ValidateAbyssState(state *AbyssStateRecord) error {
	if state == nil {
		return nil
	}

	if state.BranchDepth < 1 ||
		state.BranchDepth > abyssBottom ||
		state.MinBranchDepth < 1 ||
		state.MinBranchDepth > state.BranchDepth {
		return fmt.Errorf("Abyss branch depth is invalid")
	}

	if state.MorphDepth > math.MaxUint32 ||
		math.IsNaN(state.Phase) ||
		math.IsInf(state.Phase, 0) ||
		state.Phase < 0 ||
		state.Phase > math.Pi ||
		state.WorldX < math.MinInt32 ||
		state.WorldX > math.MaxInt32 ||
		state.WorldY < math.MinInt32 ||
		state.WorldY > math.MaxInt32 ||
		state.ShiftCount < 0 {
		return fmt.Errorf("Abyss procedural coordinate or clock is invalid")
	}

	if state.BorrowedLevelID < 1 ||
		len(state.BorrowedLayout) < 3 ||
		len(state.BorrowedLayout) > abyssHeight ||
		len(state.BorrowedLayout[0]) < 3 ||
		len(state.BorrowedLayout[0]) > abyssWidth {
		return fmt.Errorf("Abyss borrowed floor is invalid")
	}

	width := len(state.BorrowedLayout[0])

	for y, row := range state.BorrowedLayout {
		if len(row) != width {
			return fmt.Errorf("Abyss borrowed row %d has inconsistent width", y)
		}

		for x, feature := range row {
			if feature != terrain.Unseen && !terrain.Valid(feature) {
				return fmt.Errorf("Abyss borrowed cell (%d,%d) is invalid", x, y)
			}
		}
	}

	if state.ExitXP < 0 {
		return fmt.Errorf("Abyss exit XP clock is invalid")
	}

	if state.ReturnSite != nil &&
		(state.ReturnSite.LevelID < 1 ||
			state.ReturnSite.X < 0 ||
			state.ReturnSite.Y < 0) {
		return fmt.Errorf("Abyss return site is invalid")
	}

	if state.PocketStart &&
		(state.ReturnSite == nil || state.ReturnSite.LevelID != 1) {
		return fmt.Errorf("pocket Abyss has no D:1 return site")
	}

	if err := validateAbyssQueue(state); err != nil {
		return err
	}

	seenTransit := make(map[uint64]bool, len(state.Transit))
	seenTransitCells := make(map[int]bool, len(state.Transit))

	for _, actor := range state.Transit {
		cell := actor.Y*abyssWidth + actor.X

		if actor.EntityID == 0 ||
			seenTransit[actor.EntityID] ||
			seenTransitCells[cell] ||
			actor.X < 1 ||
			actor.X >= abyssWidth-1 ||
			actor.Y < 1 ||
			actor.Y >= abyssHeight-1 {
			return fmt.Errorf("Abyss transit actor is invalid")
		}

		seenTransit[actor.EntityID] = true
		seenTransitCells[cell] = true
	}

	for _, id := range state.SelectedMapIDs {
		if id == "" {
			return fmt.Errorf("Abyss selected map ID is empty")
		}
	}

	return nil
}

// The queue must be a stable permutation of distinct interior cells.
// Its sorted order is part of deterministic save and next-turn replay.
func validateAbyssQueue(state *AbyssStateRecord) error {
	seen := make(map[int]bool, len(state.SampleQueue))
	var previous AbyssSampleRecord

	for index, sample := range state.SampleQueue {
		key := sample.Y*abyssWidth + sample.X

		if sample.X < 1 ||
			sample.X >= abyssWidth-1 ||
			sample.Y < 1 ||
			sample.Y >= abyssHeight-1 ||
			sample.Change < state.MorphDepth ||
			!terrain.Valid(sample.Feature) ||
			seen[key] {
			return fmt.Errorf("Abyss sample queue entry %d is invalid", index)
		}

		if index > 0 &&
			(sample.Change < previous.Change ||
				(sample.Change == previous.Change &&
					(sample.Y < previous.Y ||
						(sample.Y == previous.Y &&
							sample.X < previous.X)))) {
			return fmt.Errorf("Abyss sample queue is not ordered")
		}

		seen[key] = true
		previous = sample
	}

	return nil
}
