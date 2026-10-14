package content

import "fmt"

// MonsterSpellSlot is immutable source content, never a live cast.
type MonsterSpellSlot struct {
	SpellID    string   `json:"spell_id"`
	SourceLine int      `json:"source_line"`
	Frequency  int      `json:"frequency"`
	Flags      []string `json:"flags"`
}

type MonsterSpellbook struct {
	ID         string             `json:"id"`
	SourceLine int                `json:"source_line"`
	Slots      []MonsterSpellSlot `json:"slots"`
}

type MonsterSpellbookArtifact struct {
	SchemaVersion  int                `json:"schema_version"`
	SourceRevision string             `json:"source_revision"`
	SourceFiles    []JobSourceFile    `json:"source_files"`
	Books          []MonsterSpellbook `json:"books"`
}

func (a MonsterSpellbookArtifact) Validate() error {
	if a.SchemaVersion != 2 ||
		a.SourceRevision == "" ||
		len(a.SourceFiles) != 3 ||
		len(a.Books) == 0 {
		return fmt.Errorf("invalid monster spellbook artifact metadata")
	}

	seen := make(map[string]bool, len(a.Books))

	for _, book := range a.Books {
		if book.ID == "" ||
			seen[book.ID] ||
			book.SourceLine <= 0 ||
			len(book.Slots) == 0 {
			return fmt.Errorf("invalid monster spellbook %q", book.ID)
		}

		seen[book.ID] = true

		for _, slot := range book.Slots {
			if slot.SpellID == "" ||
				slot.SourceLine < book.SourceLine ||
				slot.Frequency < 1 ||
				slot.Frequency > 200 ||
				len(slot.Flags) == 0 {
				return fmt.Errorf("invalid %s monster spell slot", book.ID)
			}

			flagSet := make(map[string]bool, len(slot.Flags))

			for _, flag := range slot.Flags {
				if !validMonsterSpellFlag(flag) || flagSet[flag] {
					return fmt.Errorf("invalid %s monster spell flag %q", book.ID, flag)
				}

				flagSet[flag] = true
			}
		}
	}

	return nil
}

func (c Catalog) MonsterSpellbook(id string) ([]MonsterSpellSlot, error) {
	book, found := c.monsterSpellbooks[id]

	if !found {
		return nil, fmt.Errorf("unknown monster spellbook %q", id)
	}

	slots := make([]MonsterSpellSlot, len(book.Slots))

	for index, slot := range book.Slots {
		slots[index] = slot
		slots[index].Flags = append([]string(nil), slot.Flags...)
	}

	return slots, nil
}

func validMonsterSpellFlag(flag string) bool {
	switch flag {
	case "MON_SPELL_NATURAL",
		"MON_SPELL_NO_FLAGS",
		"MON_SPELL_MAGICAL",
		"MON_SPELL_VOCAL",
		"MON_SPELL_WIZARD",
		"MON_SPELL_PRIEST",
		"MON_SPELL_BREATH",
		"MON_SPELL_NO_SILENT",
		"MON_SPELL_INSTANT",
		"MON_SPELL_NOISY",
		"MON_SPELL_SHORT_RANGE",
		"MON_SPELL_LONG_RANGE",
		"MON_SPELL_EMERGENCY",
		"MON_SPELL_EVOKE":
		return true
	}

	return false
}
