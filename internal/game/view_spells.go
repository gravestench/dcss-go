package game

import "github.com/gravestench/akara"

// fillSpellView exposes durable ECS spell identity and slots to Lua menu
// policy. Names, restrictions, and formatting remain in the effective mod.
func (g *Game) fillSpellView(view *View) {
	components := g.scripts.Components()
	records := components["character.spell"]
	casting := components["character.spellcasting"]

	if records == nil || casting == nil {
		return
	}

	for _, entity := range records.Entities() {
		record, found := records.Get(entity)

		if !found {
			continue
		}

		owner, err := record.Get("owner")

		if err != nil {
			panic(err)
		}

		if owner != akara.Entity(g.player) {
			continue
		}

		id, err := record.Get("spell_id")

		if err != nil {
			panic(err)
		}

		library, err := record.Get("in_library")

		if err != nil {
			panic(err)
		}

		known, err := record.Get("known_slot")

		if err != nil {
			panic(err)
		}

		letter, err := record.Get("letter_slot")

		if err != nil {
			panic(err)
		}

		view.Spells = append(view.Spells, SpellView{
			ID:         id.(string),
			InLibrary:  library.(bool),
			KnownSlot:  int(known.(int64)),
			LetterSlot: int(letter.(int64)),
		})
	}

	state, found := casting.Get(g.player)

	if !found {
		return
	}

	last, err := state.Get("last_spell_id")

	if err != nil {
		panic(err)
	}

	view.LastSpellID = last.(string)

	learning, err := state.Get("learning_spell_id")

	if err != nil {
		panic(err)
	}

	remaining, err := state.Get("learning_remaining")

	if err != nil {
		panic(err)
	}

	view.LearningSpellID = learning.(string)
	view.LearningRemaining = int(remaining.(int64))
}
