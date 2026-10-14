package game

import "fmt"

// activateLevel applies supported return-time effects. Inactive monsters keep
// their energy while the player is away. Crawl updates a returned level once
// instead of giving its monsters ordinary turns off-level
// (files.cc:2185; timed-effects.cc:680-755).
func (g *Game) activateLevel(level *Level, now Aut) error {
	if level.awaySinceAut != nil {
		elapsed := now - *level.awaySinceAut

		if elapsed < 0 {
			return fmt.Errorf("level %d away clock exceeds current time", level.ID)
		}

		if err := g.runWorldPolicy("world.age_corpses", map[string]any{
			"level_id": level.ID,
			"elapsed":  int(elapsed),
		}); err != nil {
			return err
		}

		if err := g.runWorldPolicy("world.catchup_monsters", map[string]any{
			"level_id": level.ID,
			"turns":    int(elapsed / 10),
		}); err != nil {
			return err
		}
	}

	level.awaySinceAut = nil

	return nil
}

func (g *Game) runWorldPolicy(name string, input map[string]any) error {
	if _, err := g.scripts.Policy(name, input); err != nil {
		return err
	}

	return g.scripts.ApplyPending()
}
