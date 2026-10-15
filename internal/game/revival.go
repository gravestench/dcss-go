package game

import "fmt"

// resumePendingRevival gives Lua the same pre-input boundary used by DCSS.
// Go knows only that a dead player may have a Lua-owned revival policy.
func (g *Game) resumePendingRevival() ([]Event, error) {
	if !g.playerDead() {
		return nil, nil
	}

	g.turn = TurnContext{Actor: g.player}
	g.scripts.BeginAction()

	decision, err := g.scripts.Policy("character.revive_pending", nil)

	if err != nil {
		g.scripts.DiscardPending()

		return nil, fmt.Errorf("revival policy: %w", err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return nil, fmt.Errorf("apply revival: %w", err)
	}

	if decision["revived"] != true {
		return nil, nil
	}

	events := append([]Event(nil), g.turn.Events...)

	for _, event := range events {
		g.messages = append(g.messages, event.Text)
	}

	if err := g.refreshVisibility(); err != nil {
		return nil, err
	}

	return events, nil
}
