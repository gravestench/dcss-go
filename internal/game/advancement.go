package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// advancementSystem applies XP earned by deathSystem after the kill has been
// resolved. The player's components own the resulting level, stats, and vitals.
type advancementSystem struct {
	player akara.Entity

	progression  *akara.Store[ecs.Progression]
	attributes   *akara.Store[ecs.Attributes]
	skills       *akara.Store[ecs.Skills]
	health       *akara.Store[ecs.Health]
	magic        *akara.Store[ecs.Magic]
	regeneration *akara.Store[ecs.Regeneration]

	species content.SpeciesDef
	rng     *RNGStreams
	turn    *TurnContext
}

func newAdvancementSystem(g *Game) (*advancementSystem, error) {
	species, err := g.catalog.Species("SP_HUMAN")

	if err != nil {
		return nil, err
	}

	s := g.stores

	return &advancementSystem{
		player: g.player,

		progression:  s.Progression,
		attributes:   s.Attributes,
		skills:       s.Skills,
		health:       s.Health,
		magic:        s.Magic,
		regeneration: s.Regeneration,

		species: species,
		rng:     g.rng,
		turn:    &g.turn,
	}, nil
}

func (s *advancementSystem) Update(_ *akara.World, _ time.Duration) error {
	return s.advance()
}

func (s *advancementSystem) advance() error {
	progress, found := s.progression.Get(s.player)

	if !found ||
		progress.Level < 1 || progress.Level > character.HumanMaxLevel {
		return fmt.Errorf("player has invalid advancement state")
	}

	if progress.PendingStatLevel != 0 {
		return nil
	}

	for progress.Level < character.HumanMaxLevel {
		nextLevel := progress.Level + 1
		needed, _ := character.HumanExperienceNeeded(nextLevel)

		if progress.TotalXP < needed {
			break
		}

		if character.HumanNeedsManualStat(nextLevel) {
			progress.PendingStatLevel = nextLevel
			s.turn.Events = append(s.turn.Events, Event{
				Kind: "stat-choice",
				Text: "Your experience leads to an increase in your attributes!",
			})

			break
		}

		if err := s.applyLevel(nextLevel); err != nil {
			return err
		}
	}

	return nil
}

func (s *advancementSystem) applyLevel(level int) error {
	progress, _ := s.progression.Get(s.player)
	attributes, hasAttributes := s.attributes.Get(s.player)
	skills, hasSkills := s.skills.Get(s.player)

	health, hasHealth := s.health.Get(s.player)
	magic, hasMagic := s.magic.Get(s.player)
	regeneration, hasRegeneration := s.regeneration.Get(s.player)

	if !hasAttributes ||
		!hasSkills ||
		!hasHealth ||
		!hasMagic ||
		!hasRegeneration ||
		health.Max <= 0 || magic.Max < 0 {
		return fmt.Errorf("player lacks advancement components")
	}

	nextHP, err := character.HumanMaxHP(level, s.species, skills.Entries)

	if err != nil {
		return err
	}

	nextMP, err := character.HumanMaxMP(level, s.species)

	if err != nil {
		return err
	}

	// species_stat_gain follows player.cc:level_change. Human gains one of
	// Strength, Intelligence, or Dexterity every fourth XL.
	if s.species.LevelUpStatFrequency > 0 &&
		len(s.species.LevelUpStats) > 0 &&
		level%s.species.LevelUpStatFrequency == 0 {
		index, err := s.rng.Intn("level", len(s.species.LevelUpStats))

		if err != nil {
			return err
		}

		if err := increaseStat(attributes, s.species.LevelUpStats[index], 1); err != nil {
			return err
		}
	}

	rescaleHealth(health, regeneration, nextHP)

	if magic.Max > 0 {
		magic.Current = magic.Current * nextMP / magic.Max
	} else {
		magic.Current = nextMP
	}

	magic.Max = nextMP
	progress.Level = level

	message := fmt.Sprintf("You have reached level %d!", level)

	if level == character.HumanMaxLevel {
		message = "You have reached level 27, the final one!"
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "level-up",
		Text: message,
	})

	return nil
}

func increaseStat(attributes *ecs.Attributes, id string, amount int) error {
	switch id {
	case "str":
		attributes.Strength += amount

	case "int":
		attributes.Intelligence += amount

	case "dex":
		attributes.Dexterity += amount

	default:
		return fmt.Errorf("unsupported level-up stat %s", id)
	}

	return nil
}

// ChooseStat completes the source's pre-level-up prompt without spending aut.
func (g *Game) ChooseStat(id string) (StepResult, error) {
	progress, found := g.stores.Progression.Get(g.player)

	if !found || progress.PendingStatLevel != progress.Level+1 {
		return StepResult{}, fmt.Errorf("no stat choice is pending")
	}

	attributes, found := g.stores.Attributes.Get(g.player)

	if !found {
		return StepResult{}, fmt.Errorf("player has no attributes")
	}

	if id != "str" &&
		id != "int" && id != "dex" {
		return g.noTime("Choose Strength, Intelligence, or Dexterity."), nil
	}

	playerTurn, found := g.stores.PlayerTurn.Get(g.player)

	if !found || playerTurn.NextAut < int64(g.currentAut) {
		return StepResult{}, fmt.Errorf("player has no pending turn clock")
	}

	turnCost := Aut(playerTurn.NextAut) - g.currentAut
	startAut := g.currentAut

	if err := increaseStat(attributes, id, 2); err != nil {
		return StepResult{}, err
	}

	nextLevel := progress.PendingStatLevel
	progress.PendingStatLevel = 0
	g.turn.Events = nil

	if err := g.advancement.applyLevel(nextLevel); err != nil {
		return StepResult{}, err
	}

	if err := g.advancement.advance(); err != nil {
		return StepResult{}, err
	}

	events := append([]Event(nil), g.turn.Events...)

	for _, event := range events {
		g.messages = append(g.messages, event.Text)
	}

	if turnCost > 0 {
		return g.finishTurn(startAut, turnCost, events)
	}

	return StepResult{
		Events: events,
		View:   g.View(),
	}, nil
}
