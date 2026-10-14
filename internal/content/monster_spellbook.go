package content

import "fmt"

// MonsterSpellSlot is immutable source content, never a live cast.
type MonsterSpellSlot struct {
	SpellID   string `json:"spell_id"`
	Frequency int    `json:"frequency"`
	FlagID    string `json:"flag_id"`
}

type MonsterSpellbook struct {
	ID         string             `json:"id"`
	SourceLine int                `json:"source_line"`
	Slots      []MonsterSpellSlot `json:"slots"`
}

type MonsterSpellbookArtifact struct {
	SchemaVersion  int                `json:"schema_version"`
	SourceRevision string             `json:"source_revision"`
	SourcePath     string             `json:"source_path"`
	SourceSHA256   string             `json:"source_sha256"`
	Books          []MonsterSpellbook `json:"books"`
}

func (a MonsterSpellbookArtifact) Validate() error {
	if a.SchemaVersion != 1 ||
		a.SourceRevision == "" ||
		a.SourcePath != "crawl-ref/source/mon-spell.h" ||
		len(a.SourceSHA256) != 64 ||
		len(a.Books) == 0 {
		return fmt.Errorf("invalid monster spellbook artifact metadata")
	}

	previous := ""

	for _, book := range a.Books {
		if book.ID <= previous ||
			book.SourceLine <= 0 ||
			len(book.Slots) == 0 {
			return fmt.Errorf("invalid monster spellbook %q", book.ID)
		}

		previous = book.ID

		for _, slot := range book.Slots {
			if slot.SpellID == "" ||
				slot.Frequency < 1 ||
				slot.Frequency > 200 ||
				slot.FlagID != "MON_SPELL_NATURAL" {
				return fmt.Errorf("invalid %s monster spell slot", book.ID)
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

	return append([]MonsterSpellSlot(nil), book.Slots...), nil
}
