package content

import "fmt"

type MonsterDef struct {
	ID         string
	Name       string
	Glyph      rune
	Speed      int
	BaseDamage int
	ScenarioHP int
}

type ItemDef struct {
	ID    string
	Name  string
	Glyph rune
}

type PlayerDef struct {
	SpeciesID  string
	JobID      string
	ScenarioHP int
	Speed      int
	BaseDamage int
}

// Catalog owns immutable definitions for one run. Its maps are private.
type Catalog struct {
	version        int
	sourceRevision string
	monsters       map[string]MonsterDef
	items          map[string]ItemDef
	species        map[string]SpeciesDef
	player         PlayerDef
}

func (c Catalog) Version() int { return c.version }

func (c Catalog) SourceRevision() string { return c.sourceRevision }

func (c Catalog) Player() PlayerDef { return c.player }

func (c Catalog) Monster(id string) (MonsterDef, error) {
	definition, found := c.monsters[id]
	if !found {
		return MonsterDef{}, fmt.Errorf("unknown monster ID %q", id)
	}
	return definition, nil
}

func (c Catalog) Item(id string) (ItemDef, error) {
	definition, found := c.items[id]
	if !found {
		return ItemDef{}, fmt.Errorf("unknown item ID %q", id)
	}
	return definition, nil
}

func (c Catalog) Validate() error {
	if c.version <= 0 || c.sourceRevision == "" {
		return fmt.Errorf("catalog has no version or source revision")
	}
	if c.player.SpeciesID == "" || c.player.JobID == "" || c.player.ScenarioHP <= 0 || c.player.Speed <= 0 {
		return fmt.Errorf("catalog has an invalid player fixture")
	}
	if len(c.species) > 0 {
		if _, found := c.species[c.player.SpeciesID]; !found {
			return fmt.Errorf("catalog has no player species %q", c.player.SpeciesID)
		}
		for id, species := range c.species {
			if species.ID != id {
				return fmt.Errorf("mismatched species key %q", id)
			}
			if err := species.validate(); err != nil {
				return err
			}
		}
	}
	for id, monster := range c.monsters {
		if id == "" || monster.ID != id || monster.Name == "" || monster.Glyph == 0 || monster.Speed <= 0 || monster.ScenarioHP <= 0 {
			return fmt.Errorf("invalid monster definition %q", id)
		}
	}
	for id, item := range c.items {
		if id == "" || item.ID != id || item.Name == "" || item.Glyph == 0 {
			return fmt.Errorf("invalid item definition %q", id)
		}
	}
	return nil
}
