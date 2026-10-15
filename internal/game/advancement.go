package game

import "fmt"

// ChooseStat completes the source's pre-level-up prompt without spending aut.
func (g *Game) ChooseStat(id string) (StepResult, error) {
	playerTurn, found := g.stores.PlayerTurn.Get(g.player)

	if !found || playerTurn.NextAut < int64(g.currentAut) {
		return StepResult{}, fmt.Errorf("player has no pending turn clock")
	}

	turnCost := Aut(playerTurn.NextAut) - g.currentAut
	startAut := g.currentAut

	g.turn.Events = nil

	decision, err := g.scripts.Policy("character.choose_stat", map[string]any{
		"stat": id,
	})

	if err != nil {
		return StepResult{}, err
	}

	if message, found := decision["message"].(string); found {
		return g.noTime(message), nil
	}

	if changed, _ := decision["chosen"].(bool); !changed {
		return StepResult{}, fmt.Errorf("Lua stat choice returned no decision")
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return StepResult{}, err
	}

	events := append([]Event(nil), g.turn.Events...)

	for _, event := range events {
		g.messages = append(g.messages, event.Text)
	}

	// A large XP award can cross several stat-choice levels at once. Keep
	// the spent turn paused until the final choice has been made.
	if progress, found := g.stores.Progression.Get(g.player); found &&
		progress.PendingStatLevel != 0 {
		if err := g.refreshVisibility(); err != nil {
			return StepResult{}, err
		}

		return StepResult{
			Spent:  turnCost,
			Events: events,
			View:   g.View(),
		}, nil
	}

	if turnCost > 0 {
		return g.finishTurn(startAut, turnCost, events)
	}

	return StepResult{
		Events: events,
		View:   g.View(),
	}, nil
}
