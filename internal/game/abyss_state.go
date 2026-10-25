package game

import (
	"fmt"

	"crawl/internal/save"
	"crawl/internal/terrain"
)

// These positive IDs sit above ordinary branch floors. Keep them aligned
// with constants/abyss.lua, which owns Lua generation and save validation.
const abyssStorageID = 1000000000

const abyssTransitID = 1000000001

const abyssBranchID = "BRANCH_ABYSS"

// A saved Abyss state contains nested terrain and queue slices. Copy every
// level so a Snapshot consumer cannot alter the live next-shift outcome.
func cloneAbyssState(source *save.AbyssStateRecord) *save.AbyssStateRecord {
	if source == nil {
		return nil
	}

	copy := *source

	copy.BorrowedLayout = make([][]terrain.ID, len(source.BorrowedLayout))

	for index, row := range source.BorrowedLayout {
		copy.BorrowedLayout[index] = append([]terrain.ID(nil), row...)
	}

	copy.SampleQueue = append([]save.AbyssSampleRecord(nil),
		source.SampleQueue...)
	copy.SelectedMapIDs = append([]string(nil),
		source.SelectedMapIDs...)
	copy.Transit = append([]save.AbyssTransitRecord(nil),
		source.Transit...)

	if source.ReturnSite != nil {
		site := *source.ReturnSite

		copy.ReturnSite = &site
	}

	return &copy
}

// Structural validation happens before state reaches the session. The
// The borrowed terrain is a complete saved copy. Its source level may
// have been a temporary realm retired after entry, so only its identity
// and the active Abyss owner need a live-level cross-check.
func (g *Game) acceptAbyssState(source *save.AbyssStateRecord) error {
	if source == nil {
		g.abyssState = nil

		return nil
	}

	if err := save.ValidateAbyssState(source); err != nil {
		return err
	}

	level := g.levels[abyssStorageID]
	reserve := g.levels[abyssTransitID]

	if level == nil ||
		reserve == nil ||
		reserve.BranchID != abyssBranchID ||
		level.BranchID != abyssBranchID ||
		level.LocalDepth != source.BranchDepth ||
		level.width != 80 ||
		len(level.terrain) != 70 ||
		source.BorrowedLevelID == abyssStorageID {
		return fmt.Errorf("saved Abyss level or borrowed floor is invalid")
	}

	if source.ReturnSite != nil {
		site := source.ReturnSite
		outside := g.levels[site.LevelID]

		if outside == nil ||
			!outside.inBounds(site.X, site.Y) ||
			site.LevelID == abyssStorageID ||
			site.LevelID == abyssTransitID {
			return fmt.Errorf("saved Abyss return site is invalid")
		}
	}

	g.abyssState = cloneAbyssState(source)

	return nil
}

// Save policy needs the branch clock to validate level ownership. A
// later gameplay command receives a deep copy of the complete state.
func luaAbyssState(source *save.AbyssStateRecord) map[string]any {
	if source == nil {
		return nil
	}

	return map[string]any{
		"branch_depth": source.BranchDepth,
	}
}

// The saved ledger and the inert ECS region must describe exactly the same
// actors. This catches a forged missing body, duplicate reserve slot, or
// parked actor omitted from the ledger before play can resume.
func (g *Game) validateAbyssTransitPlacement() error {
	reserve := g.levels[abyssTransitID]

	if reserve == nil {
		return fmt.Errorf("Abyss transit region is missing")
	}

	tracked := make(map[uint64]bool)

	if g.abyssState != nil {
		for _, record := range g.abyssState.Transit {
			actor, found := reserve.ActorAt(record.X, record.Y)

			if !found || uint64(actor) != record.EntityID {
				return fmt.Errorf("Abyss transit actor %d is not parked", record.EntityID)
			}

			if _, found := g.stores.AI.Get(actor); !found {
				return fmt.Errorf("Abyss transit entity %d has no AI", record.EntityID)
			}

			tracked[record.EntityID] = true
		}
	}

	for _, actors := range reserve.actors {
		for _, actor := range actors {
			if !tracked[uint64(actor)] {
				return fmt.Errorf("untracked Abyss transit actor %d", actor)
			}
		}
	}

	return nil
}
