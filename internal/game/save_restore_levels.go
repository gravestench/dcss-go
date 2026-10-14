package game

import (
	"fmt"

	"dcrawl-go/internal/save"
)

func (g *Game) restoreLevels(records []save.LevelRecord, currentAut int64) error {
	for _, record := range records {
		if _, duplicate := g.levels[record.ID]; duplicate {
			return fmt.Errorf("duplicate level %d", record.ID)
		}

		level, levelErr := NewLevel(record.ID, record.Rows, g.stores.Positions)

		if levelErr != nil {
			return levelErr
		}

		level.initialMonsters = record.InitialMonsters

		if knownErr := level.LoadKnownRows(record.Known); knownErr != nil {
			return knownErr
		}

		for _, savedLink := range record.Stairs {
			if linkErr := level.AddStairLink(StairLink{
				X:           savedLink.X,
				Y:           savedLink.Y,
				ToLevelID:   savedLink.ToLevelID,
				ToX:         savedLink.ToX,
				ToY:         savedLink.ToY,
				Unavailable: savedLink.Unavailable,
			}); linkErr != nil {
				return linkErr
			}
		}

		g.levels[record.ID] = level

		if record.AwaySinceAut != nil {
			if *record.AwaySinceAut < 0 || *record.AwaySinceAut > currentAut {
				return fmt.Errorf("invalid level %d away clock", record.ID)
			}

			awaySince := Aut(*record.AwaySinceAut)
			level.awaySinceAut = &awaySince
		}
	}

	if err := validateStairLinks(g.levels); err != nil {
		return err
	}

	if err := validateScenarioLevels(g.levels, g.scenarioID); err != nil {
		return err
	}

	return nil
}
