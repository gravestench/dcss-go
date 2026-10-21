package game

import (
	"fmt"

	"crawl/internal/ecs"
	"crawl/internal/save"
)

const (
	panNewRegion = "new_region"
	panReturn    = "return"
	panAbyss     = "abyss"
	panBranchID  = "BRANCH_PANDEMONIUM"
)

// panPortal is a decoded Lua travel plan. Go checks only structural facts;
// the effective Lua mod chooses the source portal and next saved history.
type panPortal struct {
	operation   string
	retireID    int
	destination point
	toLevelID   int
	nextState   *save.PanStateRecord
	stage       *stagedLevel
	returnSite  *save.PanReturnRecord
}

// decodePanReturn reads one saved site without interpreting which portal
// should use it. Lua has already selected return versus Abyss semantics.
func decodePanReturn(value any) (*save.PanReturnRecord, error) {
	record, okay := value.(map[string]any)

	if !okay {
		return nil, fmt.Errorf("Lua Pan return site is not a record")
	}

	levelID, err := decisionInteger(record, "level_id")

	if err != nil {
		return nil, err
	}

	cell, err := luaScenarioPoint(record)

	if err != nil {
		return nil, err
	}

	return &save.PanReturnRecord{
		LevelID: levelID,
		X:       cell.x,
		Y:       cell.y,
	}, nil
}

// Decode the Lua-owned state into the ordinary save schema. Missing or
// malformed map IDs fail before staging can consume a new region.
func decodePanNextState(value any) (*save.PanStateRecord, error) {
	record, okay := value.(map[string]any)

	if !okay {
		return nil, fmt.Errorf("Lua Pan next state is not a record")
	}

	regionsSeen, err := decisionInteger(record, "regions_seen")

	if err != nil {
		return nil, err
	}

	activeID, err := decisionInteger(record, "active_level_id")

	if err != nil {
		return nil, err
	}

	values, err := luaScenarioList(record["vault_ids"], "Pan vault IDs")

	if err != nil {
		return nil, err
	}

	ids := make([]string, 0, len(values))

	for _, value := range values {
		id, okay := value.(string)

		if !okay || id == "" {
			return nil, fmt.Errorf("Lua Pan history has an invalid vault ID")
		}

		ids = append(ids, id)
	}

	state := &save.PanStateRecord{
		RegionsSeen:   regionsSeen,
		VaultIDs:      ids,
		ActiveLevelID: activeID,
	}

	if value, present := record["return_site"]; present {
		state.Return, err = decodePanReturn(value)

		if err != nil {
			return nil, err
		}
	}

	return state, nil
}

// Decode a destination cell after Lua's safe-landing policy has chosen it.
func decodePanDestination(value any) (int, point, error) {
	record, okay := value.(map[string]any)

	if !okay {
		return 0, point{}, fmt.Errorf("Lua Pan destination is not a record")
	}

	levelID, err := decisionInteger(record, "level_id")

	if err != nil {
		return 0, point{}, err
	}

	cell, err := luaScenarioPoint(record)

	return levelID, cell, err
}

// preparePanPortal stages a generated region beside the current one. All
// rejected plans roll back generation, population, and RNG before Step can
// spend time or change the saved portal stack.
func (g *Game) preparePanPortal(
	plan map[string]any,
	position *ecs.Position,
) (_ *panPortal, err error) {
	operation, okay := plan["operation"].(string)

	if !okay {
		return nil, fmt.Errorf("Lua Pan portal has no operation")
	}

	retireID, err := decisionInteger(plan, "retire_level_id")

	if err != nil {
		return nil, err
	}

	nextState, err := decodePanNextState(plan["next_state"])

	if err != nil {
		return nil, err
	}

	portal := &panPortal{
		operation: operation,
		retireID:  retireID,
		nextState: nextState,
	}

	defer func() {
		if err != nil {
			if portal.stage != nil {
				if rollbackErr := portal.stage.rollback(); rollbackErr != nil {
					err = fmt.Errorf("%w; rollback: %v", err, rollbackErr)
				}
			}
		}
	}()

	if retireID != 0 && retireID != position.LevelID {
		return nil, fmt.Errorf("Pan portal retires a different level")
	}

	switch operation {
	case panNewRegion:
		history, okay := plan["history"].(map[string]any)

		if !okay {
			return nil, fmt.Errorf("Lua Pan portal has no generation history")
		}

		portal.stage, err = g.stageGeneratedLevel(
			"world.generate_pan_region", history)

		if err != nil {
			return nil, err
		}

		portal.toLevelID = portal.stage.levelID
		portal.destination = portal.stage.entry

		if portal.toLevelID != nextState.ActiveLevelID ||
			g.levels[portal.toLevelID].BranchID != panBranchID {
			return nil, fmt.Errorf("Pan generator returned a different region")
		}

	case panReturn, panAbyss:
		portal.toLevelID, portal.destination, err =
			decodePanDestination(plan["destination"])

		if err != nil {
			return nil, err
		}

		if operation == panAbyss {
			portal.returnSite, err = decodePanReturn(plan["return_site"])

			if err != nil {
				return nil, err
			}
		}

	default:
		return nil, fmt.Errorf("unknown Pan portal operation %q", operation)
	}

	to := g.levels[portal.toLevelID]

	if to == nil || !to.Walkable(portal.destination.x,
		portal.destination.y) {
		return nil, fmt.Errorf("Pan portal destination is missing or blocked")
	}

	if _, occupied := to.ActorAt(portal.destination.x,
		portal.destination.y); occupied {
		return nil, fmt.Errorf("Pan portal destination is occupied")
	}

	probe := &Game{
		scenarioID: g.scenarioID,
		levels:     g.levels,
	}

	if err := probe.acceptPanState(nextState); err != nil {
		return nil, err
	}

	return portal, nil
}

// commitPanPortal lets Lua perform the player move and Abyss pointer update
// as one ECS transaction. Only after it succeeds does Go publish session
// history; the caller can then activate and retire the old level.
func (g *Game) commitPanPortal(portal *panPortal) (Event, error) {
	destination := map[string]any{
		"level_id": portal.toLevelID,
		"x":        portal.destination.x,
		"y":        portal.destination.y,
	}

	input := map[string]any{
		"operation":   portal.operation,
		"destination": destination,
	}

	if portal.returnSite != nil {
		input["return_site"] = map[string]any{
			"level_id": portal.returnSite.LevelID,
			"x":        portal.returnSite.X,
			"y":        portal.returnSite.Y,
		}
	}

	result, err := g.scripts.Policy("world.pan.commit_travel", input)

	if err != nil {
		g.scripts.DiscardPending()

		return Event{}, err
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return Event{}, err
	}

	g.panState = clonePanState(portal.nextState)

	if portal.stage != nil {
		portal.stage.commit()
	}

	message, _ := result["message"].(string)

	return Event{
		Kind: "stairs",
		Text: message,
	}, nil
}
