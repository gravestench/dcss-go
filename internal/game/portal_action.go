package game

import (
	"fmt"

	"crawl/internal/ecs"
)

// portalAction is the transport kernel's shared transaction boundary.
// Lua chooses gate semantics; each session domain owns its saved history.
type portalAction interface {
	staged() *stagedLevel
	retiredLevelID() int
	commit(*Game) (Event, error)
}

// preparePortal dispatches only saved session domains, never individual
// terrain or content IDs. The domain's Lua policy already chose the gate.
func (g *Game) preparePortal(
	plan map[string]any,
	position *ecs.Position,
) (portalAction, error) {
	domain, okay := plan["domain"].(string)

	if !okay {
		return nil, fmt.Errorf("Lua portal has no session domain")
	}

	switch domain {
	case "pan":
		portal, err := g.preparePanPortal(plan, position)

		if err != nil {
			return nil, err
		}

		return portal, nil

	case "hell":
		portal, err := g.prepareHellPortal(plan, position)

		if err != nil {
			return nil, err
		}

		return portal, nil

	case "lua":
		portal, err := g.prepareLuaPortal(plan, position)

		if err != nil {
			return nil, err
		}

		return portal, nil

	default:
		return nil, fmt.Errorf("unknown Lua portal domain %q", domain)
	}
}

// Pan replaces one region, so its staged floor and retired ID belong to
// its existing transport transaction.
func (portal *panPortal) staged() *stagedLevel {
	return portal.stage
}

func (portal *panPortal) retiredLevelID() int {
	return portal.retireID
}

func (portal *panPortal) commit(g *Game) (Event, error) {
	return g.commitPanPortal(portal)
}
