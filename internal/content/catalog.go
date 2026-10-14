package content

import "fmt"

type PlayerDef struct {
	SpeciesID string
	JobID     string
	Speed     int
}

// Catalog owns immutable definitions for one run. Its maps are private.
type Catalog struct {
	version           int
	sourceRevision    string
	monsters          map[string]MonsterDef
	spells            map[string]SpellDef
	spellOrder        []string
	branches          map[string]BranchDef
	branchOrder       []string
	dungeonPopulation []DungeonPopEntry
	items             map[string]ItemDef
	itemIdentities    map[string]ItemIdentity
	species           map[string]SpeciesDef
	jobs              map[string]JobDef
	startingGear      map[string][]StartingGrant
	presentation      PresentationArtifact
	player            PlayerDef
}

func (c Catalog) Version() int {
	return c.version
}

func (c Catalog) SourceRevision() string {
	return c.sourceRevision
}

func (c Catalog) Player() PlayerDef {
	return c.player
}

func (c Catalog) Monster(id string) (MonsterDef, error) {
	definition, found := c.monsters[id]
	if !found {
		return MonsterDef{}, fmt.Errorf("unknown monster ID %q", id)
	}
	if definition.Status != MonsterDefined {
		return MonsterDef{}, fmt.Errorf("monster ID %q is %s and cannot be instantiated", id, definition.Status)
	}
	return definition.clone(), nil
}

func (c Catalog) Spell(id string) (SpellDef, error) {
	definition, found := c.spells[id]
	if !found {
		return SpellDef{}, fmt.Errorf("unknown spell ID %q", id)
	}
	if definition.Status != SpellDefined {
		return SpellDef{}, fmt.Errorf("spell ID %q is %s and cannot be cast", id, definition.Status)
	}
	return definition.clone(), nil
}

func (c Catalog) SpellStatus(id string) (SpellStatus, error) {
	definition, found := c.spells[id]
	if !found {
		return "", fmt.Errorf("unknown spell ID %q", id)
	}
	return definition.Status, nil
}

func (c Catalog) SpellIDs() []string {
	return append([]string(nil), c.spellOrder...)
}

func (c Catalog) Branch(id string) (BranchDef, error) {
	definition, found := c.branches[id]
	if !found {
		return BranchDef{}, fmt.Errorf("unknown branch ID %q", id)
	}
	return definition.clone(), nil
}

func (c Catalog) BranchIDs() []string {
	return append([]string(nil), c.branchOrder...)
}

func (c Catalog) Item(id string) (ItemDef, error) {
	definition, found := c.items[id]
	if !found {
		return ItemDef{}, fmt.Errorf("unknown item ID %q", id)
	}
	return definition.clone(), nil
}

func (c Catalog) Validate() error {
	if c.version <= 0 || c.sourceRevision == "" {
		return fmt.Errorf("catalog has no version or source revision")
	}
	if c.player.SpeciesID == "" || c.player.JobID == "" || c.player.Speed <= 0 {
		return fmt.Errorf("catalog has an invalid player fixture")
	}
	for _, row := range c.dungeonPopulation {
		if err := row.validate(); err != nil {
			return err
		}
		if _, found := c.monsters[row.MonsterID]; !found {
			return fmt.Errorf("Dungeon population references missing monster %s", row.MonsterID)
		}
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
	if len(c.jobs) > 0 {
		if _, found := c.jobs[c.player.JobID]; !found {
			return fmt.Errorf("catalog has no player job %q", c.player.JobID)
		}
		for id, job := range c.jobs {
			if job.ID != id {
				return fmt.Errorf("mismatched job key %q", id)
			}
			if err := job.validate(); err != nil {
				return err
			}
		}
	}
	for id, monster := range c.monsters {
		if id == "" || monster.ID != id || monster.validate() != nil {
			return fmt.Errorf("invalid monster definition %q", id)
		}
	}
	if len(c.spells) != len(c.spellOrder) {
		return fmt.Errorf("spell catalog and order disagree")
	}
	for i, id := range c.spellOrder {
		spell, found := c.spells[id]
		if !found || spell.NumericID != i || spell.validate() != nil {
			return fmt.Errorf("invalid spell definition %s", id)
		}
	}
	if len(c.branches) != len(c.branchOrder) {
		return fmt.Errorf("branch catalog and order disagree")
	}
	for i, id := range c.branchOrder {
		branch, found := c.branches[id]
		if !found || branch.NumericID != i || branch.validate() != nil {
			return fmt.Errorf("invalid branch definition %s", id)
		}
		if branch.ParentID != "NUM_BRANCHES" {
			if _, found := c.branches[branch.ParentID]; !found {
				return fmt.Errorf("branch %s has unknown parent %s", id, branch.ParentID)
			}
		}
	}
	for id, item := range c.items {
		if id == "" || item.ID != id || item.validate() != nil {
			return fmt.Errorf("invalid item definition %q", id)
		}
	}
	if c.presentation.SchemaVersion != 0 {
		if err := c.presentation.validate(c); err != nil {
			return err
		}
	}
	return nil
}
