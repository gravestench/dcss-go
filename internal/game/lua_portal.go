package game

import (
	"fmt"

	"crawl/internal/ecs"
)

// luaPortal is the generic transaction for a mod-defined one-floor portal.
// Go verifies grid and actor facts; Lua owns the gate, map choice, saved
// component state, messages, and return semantics.
type luaPortal struct {
	stage        *stagedLevel
	operation    string
	commitPolicy string
	source       point
	sourceID     int
	toLevelID    int
	destination  point
	retireID     int
	payload      map[string]any
}

// A prepared plan must name the cell the player actually stands on. This
// prevents an earlier Lua decision from moving the wrong portal later.
func portalSource(plan map[string]any, position *ecs.Position) (int, point, error) {
	site, err := decodePortalReturn(plan["source"])

	if err != nil {
		return 0, point{}, err
	}

	if site.LevelID != position.LevelID ||
		site.X != position.X ||
		site.Y != position.Y {
		return 0, point{}, fmt.Errorf("Lua portal source differs from the actor")
	}

	return site.LevelID, point{
		x: site.X,
		y: site.Y,
	}, nil
}

// Staging is optional: a first visit generates a floor, while an exit
// names an existing one. Both paths validate the landing before time passes.
func (g *Game) prepareLuaPortal(
	plan map[string]any,
	position *ecs.Position,
) (_ *luaPortal, err error) {
	portal := &luaPortal{}

	portal.operation, _ = plan["operation"].(string)
	portal.commitPolicy, _ = plan["commit_policy"].(string)
	portal.payload, _ = plan["payload"].(map[string]any)

	if portal.operation == "" || portal.commitPolicy == "" {
		return nil, fmt.Errorf("Lua portal has no operation or commit policy")
	}

	portal.sourceID, portal.source, err = portalSource(plan, position)

	if err != nil {
		return nil, err
	}

	if value, present := plan["retire_level_id"]; present {
		portal.retireID, err = decisionInteger(
			map[string]any{"retire_level_id": value}, "retire_level_id")

		if err != nil {
			return nil, fmt.Errorf("Lua portal has invalid retired level: %w", err)
		}

		if portal.retireID != position.LevelID {
			return nil, fmt.Errorf("Lua portal retires a different source level")
		}
	}

	defer func() {
		if err != nil &&
			portal.stage != nil {
			if rollbackErr := portal.stage.rollback(); rollbackErr != nil {
				err = fmt.Errorf("%w; rollback: %v", err, rollbackErr)
			}
		}
	}()

	if policyID, generating := plan["generate_policy"].(string); generating {
		input, okay := plan["generation_input"].(map[string]any)

		if !okay ||
			policyID == "" ||
			portal.retireID != 0 {
			return nil, fmt.Errorf("Lua portal has invalid generation input")
		}

		portal.stage, err = g.stageGeneratedLevel(policyID, input)

		if err != nil {
			return nil, err
		}

		portal.toLevelID = portal.stage.levelID
		portal.destination = portal.stage.entry

		expectedID, decodeErr := decisionInteger(plan, "expected_level_id")
		expectedBranch, okay := plan["expected_branch_id"].(string)
		level := g.levels[portal.toLevelID]

		if decodeErr != nil ||
			!okay ||
			expectedBranch == "" ||
			level == nil ||
			portal.toLevelID != expectedID ||
			level.BranchID != expectedBranch {
			return nil, fmt.Errorf("Lua portal generated another floor identity")
		}
	} else {
		portal.toLevelID, portal.destination, err =
			decodePortalDestination(plan["destination"])

		if err != nil {
			return nil, err
		}
	}

	to := g.levels[portal.toLevelID]

	if to == nil || !to.Walkable(portal.destination.x,
		portal.destination.y) {
		return nil, fmt.Errorf("Lua portal destination is missing or blocked")
	}

	if _, occupied := to.ActorAt(portal.destination.x,
		portal.destination.y); occupied {
		return nil, fmt.Errorf("Lua portal destination is occupied")
	}

	return portal, nil
}

// The optional stage remains reversible until the Lua ECS move and all
// component writes succeed. The outer command later retires an old floor.
func (portal *luaPortal) staged() *stagedLevel {
	return portal.stage
}

func (portal *luaPortal) retiredLevelID() int {
	return portal.retireID
}

func (portal *luaPortal) commit(g *Game) (Event, error) {
	level := g.levels[portal.toLevelID]
	input := map[string]any{
		"operation": portal.operation,
		"source": map[string]any{
			"level_id": portal.sourceID,
			"x":        portal.source.x,
			"y":        portal.source.y,
		},

		"destination": map[string]any{
			"level_id": portal.toLevelID,
			"x":        portal.destination.x,
			"y":        portal.destination.y,
		},
		"vault_id": level.VaultID(),
		"payload":  portal.payload,
	}

	if portal.stage != nil {
		input["generation_output"] = portal.stage.portalData
	}

	result, err := g.scripts.Policy(portal.commitPolicy, input)

	if err != nil {
		g.scripts.DiscardPending()

		return Event{}, err
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return Event{}, err
	}

	if portal.stage != nil {
		portal.stage.commit()
	}

	message, _ := result["message"].(string)

	return Event{
		Kind: "stairs",
		Text: message,
	}, nil
}
