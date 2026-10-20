package game

import (
	"fmt"
	"sort"

	"crawl/internal/terrain"
)

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

// generateNextFloor installs a scheduled floor and its reciprocal stair
// links. A malformed mod policy rolls back grid/link changes before returning.
func (g *Game) generateNextFloor(parentID int, selected StairLink) ([]any, error) {
	parent := g.levels[parentID]
	levelID := selected.ToLevelID

	if parent == nil ||
		!selected.Pending ||
		levelID <= 0 ||
		g.levels[levelID] != nil {
		return nil, fmt.Errorf("invalid pending floor stair")
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
			return nil, fmt.Errorf("unscheduled branch entrance %s", branchID)
		}
	}

	player, found := g.stores.Players.Get(g.player)

	if !found {
		return nil, fmt.Errorf("Dungeon player has no identity")
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
	})

	if err != nil {
		return nil, err
	}

	record, ok := result["level"].(map[string]any)

	if !ok {
		return nil, fmt.Errorf("Lua next floor is not a level record")
	}

	returnedID, err := decisionInteger(record, "id")

	if err != nil {
		return nil, err
	}

	if returnedID != levelID || record["branch_id"] != branchID {
		return nil, fmt.Errorf("Lua next floor has the wrong branch or ID")
	}

	returnedDepth, err := decisionInteger(record, "local_depth")

	if err != nil || returnedDepth != localDepth {
		return nil, fmt.Errorf("Lua next floor has the wrong local depth")
	}

	entry, err := luaScenarioPoint(result["entry"])

	if err != nil {
		return nil, err
	}

	patches, err := luaScenarioList(result["parent_links"], "parent links")

	if err != nil {
		return nil, err
	}

	items, err := luaScenarioList(result["starting_items"], "starting items")

	if err != nil {
		return nil, err
	}

	// Keep the old parent intact if a mod returns a malformed floor or patch.
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

		delete(g.levels, levelID)
		parent.terrain = oldCells
		parent.remembered = oldRemembered
		parent.stairs = oldLinks
	}()

	_, _, links, err := g.decodeLuaLevelRecords([]any{record}, g.stores.Positions)

	if err != nil {
		return nil, err
	}

	if g.levels[levelID] == nil || len(links) != 1 {
		return nil, fmt.Errorf("Lua next floor has the wrong ID")
	}

	for _, value := range links[levelID] {
		link, decodeErr := luaScenarioStair(value)

		if decodeErr != nil {
			return nil, decodeErr
		}

		if err := g.levels[levelID].AddStairLink(link); err != nil {
			return nil, err
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
		if childLink.ToLevelID != parentID || childLink.Pending {
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

	return items, nil
}
