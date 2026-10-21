package game

import (
	"fmt"

	"crawl/internal/ecs"
	"crawl/internal/save"
)

const (
	hellEnter  = "enter"
	hellReturn = "return"
)

// hellPortal is one prepared ECS move plus the next saved return site.
// A generated Vestibule is staged beside the active floor until commit.
type hellPortal struct {
	operation   string
	toLevelID   int
	destination point
	nextState   *save.HellStateRecord
	stage       *stagedLevel
}

// prepareHellPortal validates Lua's plan, generates the Vestibule only on
// first entry, and checks every landing before the action can spend time.
func (g *Game) prepareHellPortal(
	plan map[string]any,
	position *ecs.Position,
) (_ *hellPortal, err error) {
	operation, okay := plan["operation"].(string)

	if !okay {
		return nil, fmt.Errorf("Lua Hell portal has no operation")
	}

	portal := &hellPortal{operation: operation}

	defer func() {
		if err != nil &&
			portal.stage != nil {
			if rollbackErr := portal.stage.rollback(); rollbackErr != nil {
				err = fmt.Errorf("%w; rollback: %v", err, rollbackErr)
			}
		}
	}()

	switch operation {
	case hellEnter:
		returnSite, decodeErr := decodePortalReturn(plan["return_site"])

		if decodeErr != nil {
			return nil, decodeErr
		}

		if returnSite.LevelID != position.LevelID ||
			returnSite.X != position.X ||
			returnSite.Y != position.Y {
			return nil, fmt.Errorf("Hell entry return site differs from the gate")
		}

		if g.hellState == nil {
			portal.stage, err = g.stageGeneratedLevel(
				"world.generate_hell_vestibule", map[string]any{
					"prior_vault_ids": g.priorVaultIDs(),
				})

			if err != nil {
				return nil, err
			}

			portal.toLevelID = portal.stage.levelID
			portal.destination = portal.stage.entry
			portal.nextState = &save.HellStateRecord{
				VestibuleLevelID: portal.toLevelID,
				EntryX:           portal.stage.authoredEntry.x,
				EntryY:           portal.stage.authoredEntry.y,
				Return:           returnSite,
			}
		} else {
			if position.LevelID == g.hellState.VestibuleLevelID {
				return nil, fmt.Errorf("Hell entry is already in the Vestibule")
			}

			portal.toLevelID, portal.destination, err =
				decodePortalDestination(plan["destination"])

			if err != nil {
				return nil, err
			}

			if portal.toLevelID != g.hellState.VestibuleLevelID {
				return nil, fmt.Errorf("Hell reentry names another level")
			}

			portal.nextState = cloneHellState(g.hellState)
			portal.nextState.Return = returnSite
		}

	case hellReturn:
		if g.hellState == nil ||
			position.LevelID != g.hellState.VestibuleLevelID {
			return nil, fmt.Errorf("Hell exit has no active Vestibule")
		}

		portal.toLevelID, portal.destination, err =
			decodePortalDestination(plan["destination"])

		if err != nil {
			return nil, err
		}

		if portal.toLevelID != g.hellState.Return.LevelID {
			return nil, fmt.Errorf("Hell exit names another outside level")
		}

		portal.nextState = cloneHellState(g.hellState)

	default:
		return nil, fmt.Errorf("unknown Hell operation %q", operation)
	}

	to := g.levels[portal.toLevelID]

	if to == nil || !to.Walkable(portal.destination.x,
		portal.destination.y) {
		return nil, fmt.Errorf("Hell portal destination is missing or blocked")
	}

	if _, occupied := to.ActorAt(portal.destination.x,
		portal.destination.y); occupied {
		return nil, fmt.Errorf("Hell portal destination is occupied")
	}

	probe := &Game{
		scenarioID: g.scenarioID,
		levels:     g.levels,
	}

	if err := probe.acceptHellState(portal.nextState); err != nil {
		return nil, err
	}

	if portal.stage != nil {
		if err := g.validateScenarioLevels(g.panState,
			portal.nextState); err != nil {
			return nil, err
		}
	}

	return portal, nil
}

// staged exposes the optional new floor to the command rollback boundary.
func (portal *hellPortal) staged() *stagedLevel {
	return portal.stage
}

// retiredLevelID is zero because Hell floors persist after every visit.
func (portal *hellPortal) retiredLevelID() int {
	return 0
}

// commit asks Lua to move the player through ECS, then publishes the saved
// return site only after that move and its queued effects have succeeded.
func (portal *hellPortal) commit(g *Game) (Event, error) {
	result, err := g.scripts.Policy("world.hell.commit_travel",
		map[string]any{
			"operation": portal.operation,
			"destination": map[string]any{
				"level_id": portal.toLevelID,
				"x":        portal.destination.x,
				"y":        portal.destination.y,
			},
		})

	if err != nil {
		g.scripts.DiscardPending()

		return Event{}, err
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return Event{}, err
	}

	g.hellState = cloneHellState(portal.nextState)

	if portal.stage != nil {
		portal.stage.commit()
	}

	message, _ := result["message"].(string)

	return Event{
		Kind: "stairs",
		Text: message,
	}, nil
}
