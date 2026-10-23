package game

import (
	"fmt"
	"sort"

	"crawl/internal/terrain"
)

// A policy may stage one floor or a related bundle. Population remains a
// separate step so a failed actor/item placement rolls back with travel.
type nextFloorResult struct {
	items   []any
	entries map[int]point
}

// Prior successful map IDs let Lua reconstruct run-wide uniqueness without
// saving a second copy of every source tag or consulting the C++ checkout.
func (g *Game) priorVaultIDs() []any {
	depths := make([]int, 0, len(g.levels))

	for depth := range g.levels {
		depths = append(depths, depth)
	}

	sort.Ints(depths)
	ids := []any{}

	for _, depth := range depths {
		for _, id := range g.levels[depth].VaultIDs() {
			ids = append(ids, id)
		}
	}

	return ids
}

// liveParentRecord sends only facts the Lua stair policy needs. In particular,
// exploration and authored vault cells come from the current Level, because
// actors and terrain may have changed since this floor was first generated.
func liveParentRecord(parent *Level) map[string]any {
	seen := []any{}

	for y, row := range parent.SeenCells() {
		for x, visible := range row {
			if visible {
				seen = append(seen, map[string]any{
					"x": x,
					"y": y,
				})
			}
		}
	}

	protected := map[string]any{}

	for _, record := range parent.vaultRecords {
		protected[fmt.Sprintf("%d:%d", record.X, record.Y)] = true
	}

	stairs := []any{}

	for _, link := range parent.StairLinks() {
		stairs = append(stairs, map[string]any{
			"x":                link.X,
			"y":                link.Y,
			"pending":          link.Pending,
			"to_level_id":      link.ToLevelID,
			"target_branch_id": link.TargetBranchID,
		})
	}

	return map[string]any{
		"id":          parent.ID,
		"branch_id":   parent.BranchID,
		"local_depth": parent.LocalDepth,
		"width":       parent.width,
		"height":      len(parent.terrain),
		"seen":        seen,
		"protected":   protected,
		"stairs":      stairs,
	}
}

// installParentLinks resolves existing exits and adds safe extra departures
// when the child's authored vault has more up stairs than its parent.
func installParentLinks(parent *Level, depth int, values []any) error {
	for _, value := range values {
		patch, ok := value.(map[string]any)

		if !ok {
			return fmt.Errorf("Lua parent stair patch is not a record")
		}

		from, err := luaScenarioPoint(patch)

		if err != nil {
			return err
		}

		toX, err := decisionInteger(patch, "to_x")

		if err != nil {
			return err
		}

		toY, err := decisionInteger(patch, "to_y")

		if err != nil {
			return err
		}

		created, ok := patch["new"].(bool)

		if !ok {
			return fmt.Errorf("Lua parent stair patch has no new flag")
		}

		if !created {
			if err := parent.ResolveStairLink(from.x, from.y, toX, toY); err != nil {
				return err
			}

			continue
		}

		feature, ok := patch["feature"].(string)

		if !ok || terrain.ID(feature) != terrain.StairsDown {
			return fmt.Errorf("Lua parent stair patch has invalid feature")
		}

		if !parent.inBounds(from.x, from.y) ||
			parent.terrain[from.y][from.x] != terrain.Floor {
			return fmt.Errorf("Lua parent stair patch is not on open floor")
		}

		if _, occupied := parent.ActorAt(from.x, from.y); occupied {
			return fmt.Errorf("Lua parent stair patch overlaps an actor")
		}

		for _, record := range parent.vaultRecords {
			if record.X == from.x && record.Y == from.y {
				return fmt.Errorf("Lua parent stair patch overlaps an authored vault cell")
			}
		}

		if err := parent.SetCell(from.x, from.y, terrain.ID(feature)); err != nil {
			return err
		}

		if err := parent.AddStairLink(StairLink{
			X:         from.x,
			Y:         from.y,
			ToLevelID: depth,
			ToX:       toX,
			ToY:       toY,
		}); err != nil {
			return err
		}
	}

	return nil
}

// nextFloorRecords keeps the legacy single-level policy contract and the new
// bundle contract behind one validation point. Every staged ID must belong
// to the scheduled branch before any Level or ECS store is changed.
func (g *Game) nextFloorRecords(
	result map[string]any,
	branchID string,
	localDepth int,
	levelID int,
) ([]any, error) {
	var records []any

	if bundled, present := result["levels"]; present {
		var err error
		records, err = luaScenarioList(bundled, "next levels")

		if err != nil {
			return nil, err
		}

		if len(records) == 0 {
			return nil, fmt.Errorf("Lua next floor has no levels")
		}
	} else {
		if result["level"] == nil {
			return nil, fmt.Errorf("Lua next floor is not a level record")
		}

		records = []any{result["level"]}
	}

	for index, value := range records {
		record, ok := value.(map[string]any)

		if !ok {
			return nil, fmt.Errorf("Lua next floor %d is not a level record", index)
		}

		returnedID, err := decisionInteger(record, "id")

		if err != nil {
			return nil, err
		}

		if returnedID != levelID+index || record["branch_id"] != branchID {
			return nil, fmt.Errorf("Lua next floor has the wrong branch or ID")
		}

		returnedDepth, err := decisionInteger(record, "local_depth")

		if err != nil {
			return nil, err
		}

		if returnedDepth != localDepth+index {
			return nil, fmt.Errorf("Lua next floor has the wrong local depth")
		}

		if g.levels[returnedID] != nil {
			return nil, fmt.Errorf("Lua next floor %d already exists", returnedID)
		}
	}

	return records, nil
}

// stageNextFloorRecords installs decoded grids and links together. Restore
// the parent's terrain and pending stair if any modded child or patch is bad.
func (g *Game) stageNextFloorRecords(
	parent *Level,
	selected StairLink,
	records []any,
	entry point,
	patches []any,
) (map[int]point, error) {
	levelID := selected.ToLevelID
	oldCells := parent.Cells()
	oldRemembered := append([]terrain.ID(nil), parent.remembered...)
	oldLinks := make(map[point]StairLink, len(parent.stairs))

	for location, link := range parent.stairs {
		oldLinks[location] = link
	}

	installed := false

	defer func() {
		if installed {
			return
		}

		for index := range records {
			delete(g.levels, levelID+index)
		}

		parent.terrain = oldCells
		parent.remembered = oldRemembered
		parent.stairs = oldLinks
	}()

	entries, _, links, err := g.decodeLuaLevelRecords(records, g.stores.Positions)

	if err != nil {
		return nil, err
	}

	if len(links) != len(records) {
		return nil, fmt.Errorf("Lua next floor has the wrong level count")
	}

	for index := range records {
		id := levelID + index

		if g.levels[id] == nil {
			return nil, fmt.Errorf("Lua next floor %d was not installed", id)
		}

		for _, value := range links[id] {
			link, decodeErr := luaScenarioStair(value)

			if decodeErr != nil {
				return nil, decodeErr
			}

			if err := g.levels[id].AddStairLink(link); err != nil {
				return nil, err
			}
		}
	}

	if err := installParentLinks(parent, levelID, patches); err != nil {
		return nil, err
	}

	resolved, found := parent.StairAt(selected.X, selected.Y)

	if !found ||
		resolved.Pending ||
		resolved.ToX != entry.x ||
		resolved.ToY != entry.y {
		return nil, fmt.Errorf("Lua next floor did not pair the selected stair")
	}

	if err := validateStairLinks(g.levels); err != nil {
		return nil, err
	}

	for _, childLink := range g.levels[levelID].StairLinks() {
		if childLink.ToLevelID != parent.ID || childLink.Pending {
			continue
		}

		back, exists := parent.StairAt(childLink.ToX, childLink.ToY)

		if !exists ||
			back.Pending ||
			back.ToLevelID != levelID ||
			back.ToX != childLink.X ||
			back.ToY != childLink.Y {
			return nil, fmt.Errorf("Lua next floor has an unpaired up stair")
		}
	}

	installed = true

	return entries, nil
}

// generateNextFloor asks Lua for the next floor or bundle, then installs it
// as one transaction. Population follows under the caller's ECS checkpoint.
func (g *Game) generateNextFloor(parentID int, selected StairLink) (nextFloorResult, error) {
	parent := g.levels[parentID]
	levelID := selected.ToLevelID

	if parent == nil ||
		!selected.Pending ||
		levelID <= 0 ||
		g.levels[levelID] != nil {
		return nextFloorResult{}, fmt.Errorf("invalid pending floor stair")
	}

	branchID := parent.BranchID
	localDepth := parent.LocalDepth + 1

	if selected.TargetBranchID != "" {
		branchID = selected.TargetBranchID
		localDepth = 1
		found := false

		for _, entry := range g.branchSchedule.Entries {
			if entry.BranchID == branchID &&
				entry.ParentID == parent.BranchID &&
				entry.ParentDepth == parent.LocalDepth {
				found = true
				break
			}
		}

		if !found {
			return nextFloorResult{}, fmt.Errorf("unscheduled branch entrance %s", branchID)
		}
	}

	player, found := g.stores.Players.Get(g.player)

	if !found {
		return nextFloorResult{}, fmt.Errorf("Dungeon player has no identity")
	}

	result, err := g.scripts.Policy("world.generate_next_floor", map[string]any{
		"branch_id":         branchID,
		"local_depth":       localDepth,
		"level_id":          levelID,
		"player_species_id": player.SpeciesID,
		"player_name":       player.Name,
		"from_x":            selected.X,
		"from_y":            selected.Y,
		"parent":            liveParentRecord(parent),
		"prior_vault_ids":   g.priorVaultIDs(),
		"branch_schedule":   luaBranchSchedule(g.branchSchedule),
		"temple_plan":       luaTemplePlan(g.templePlan),
	})

	if err != nil {
		return nextFloorResult{}, err
	}

	records, err := g.nextFloorRecords(result, branchID, localDepth, levelID)

	if err != nil {
		return nextFloorResult{}, err
	}

	entry, err := luaScenarioPoint(result["entry"])

	if err != nil {
		return nextFloorResult{}, err
	}

	patches, err := luaScenarioList(result["parent_links"], "parent links")

	if err != nil {
		return nextFloorResult{}, err
	}

	items, err := luaScenarioList(result["starting_items"], "starting items")

	if err != nil {
		return nextFloorResult{}, err
	}

	entries, err := g.stageNextFloorRecords(parent, selected, records, entry, patches)

	if err != nil {
		return nextFloorResult{}, err
	}

	return nextFloorResult{
		items:   items,
		entries: entries,
	}, nil
}
