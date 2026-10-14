package content

import (
	"bytes"
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
)

//go:embed generated/species.json
var defaultSpeciesJSON []byte

//go:embed generated/jobs.json
var defaultJobsJSON []byte

//go:embed generated/starting-gear.json
var defaultStartingGearJSON []byte

//go:embed generated/items.json
var defaultItemsJSON []byte

//go:embed generated/item-identities.json
var defaultItemIdentitiesJSON []byte

//go:embed generated/presentation.json
var defaultPresentationJSON []byte

//go:embed generated/monsters.json
var defaultMonsterJSON []byte

//go:embed generated/monster-vocabulary.json
var defaultMonsterVocabularyJSON []byte

//go:embed generated/spells.json
var defaultSpellJSON []byte

//go:embed generated/branches.json
var defaultBranchJSON []byte

//go:embed generated/dungeon-population.json
var defaultDungeonPopulationJSON []byte

// LoadDefault builds a fresh catalog from the checked-in source-traced artifacts.
func LoadDefault() (Catalog, error) {
	catalog, err := loadDefault(defaultSpeciesJSON, defaultJobsJSON, defaultItemsJSON, defaultItemIdentitiesJSON, defaultStartingGearJSON, defaultPresentationJSON, defaultMonsterJSON)
	if err != nil {
		return Catalog{}, err
	}
	catalog, err = attachDefaultSpells(catalog, defaultSpellJSON)
	if err != nil {
		return Catalog{}, err
	}
	catalog, err = attachDefaultBranches(catalog, defaultBranchJSON)
	if err != nil {
		return Catalog{}, err
	}
	return attachDefaultDungeonPopulation(catalog, defaultDungeonPopulationJSON)
}

// LoadDefinitionsForImport reads committed gameplay definitions without needing
// the presentation artifact that the refresh tool is about to regenerate.
func LoadDefinitionsForImport() (Catalog, error) {
	catalog, err := loadDefault(defaultSpeciesJSON, defaultJobsJSON, defaultItemsJSON, defaultItemIdentitiesJSON, defaultStartingGearJSON, nil, defaultMonsterJSON)
	if err != nil {
		return Catalog{}, err
	}
	catalog, err = attachDefaultSpells(catalog, defaultSpellJSON)
	if err != nil {
		return Catalog{}, err
	}
	catalog, err = attachDefaultBranches(catalog, defaultBranchJSON)
	if err != nil {
		return Catalog{}, err
	}
	return attachDefaultDungeonPopulation(catalog, defaultDungeonPopulationJSON)
}

func attachDefaultDungeonPopulation(catalog Catalog, data []byte) (Catalog, error) {
	const pinnedArtifactSHA256 = "d37becdb7daa03d0e02f1b9ca5e3c42d875022ba623d71721082fb64c640fe7b"
	hash := sha256.Sum256(data)
	if hex.EncodeToString(hash[:]) != pinnedArtifactSHA256 {
		return Catalog{}, fmt.Errorf("Dungeon population differs from pinned content")
	}
	var artifact DungeonPopulationArtifact
	if err := decodeArtifact(data, "Dungeon population", &artifact); err != nil {
		return Catalog{}, err
	}
	if err := artifact.Validate(); err != nil {
		return Catalog{}, err
	}
	if artifact.SourceRevision != catalog.SourceRevision() || len(artifact.Rows) != 125 || len(artifact.SourceFiles) != 3 {
		return Catalog{}, fmt.Errorf("Dungeon population has incomplete pinned coverage")
	}
	paths, err := validSourceFiles(artifact.SourceFiles, "Dungeon population")
	if err != nil {
		return Catalog{}, err
	}
	for _, name := range []string{"mon-pick-data.h", "random-pick.h", "tag-version.h"} {
		if _, found := paths["crawl-ref/source/"+name]; !found {
			return Catalog{}, fmt.Errorf("Dungeon population lacks source %s", name)
		}
	}
	for _, row := range artifact.Rows {
		if _, err := catalog.Monster(row.MonsterID); err != nil {
			return Catalog{}, fmt.Errorf("Dungeon population row %d: %w", row.SourceLine, err)
		}
	}
	catalog.dungeonPopulation = append([]DungeonPopEntry(nil), artifact.Rows...)
	if err := catalog.Validate(); err != nil {
		return Catalog{}, err
	}
	return catalog, nil
}

func attachDefaultBranches(catalog Catalog, data []byte) (Catalog, error) {
	const pinnedArtifactSHA256 = "8ad8a4b914012c631bdf2a8f2637466fcbc47a5d76d540f810fdf6f93b15a656"
	hash := sha256.Sum256(data)
	if hex.EncodeToString(hash[:]) != pinnedArtifactSHA256 {
		return Catalog{}, fmt.Errorf("branch catalog differs from pinned content")
	}
	var artifact BranchArtifact
	if err := decodeArtifact(data, "branches", &artifact); err != nil {
		return Catalog{}, err
	}
	if err := artifact.Validate(); err != nil {
		return Catalog{}, err
	}
	if artifact.SourceRevision != catalog.SourceRevision() || len(artifact.Branches) != 38 {
		return Catalog{}, fmt.Errorf("branch catalog has incomplete pinned coverage")
	}
	paths, err := validSourceFiles(artifact.SourceFiles, "branch")
	if err != nil {
		return Catalog{}, err
	}
	for _, name := range []string{"tag-version.h", "branch-type.h", "branch-data.h"} {
		if _, found := paths["crawl-ref/source/"+name]; !found {
			return Catalog{}, fmt.Errorf("branch catalog lacks source %s", name)
		}
	}
	catalog.branches = make(map[string]BranchDef, len(artifact.Branches))
	for _, branch := range artifact.Branches {
		catalog.branches[branch.ID] = branch.clone()
		catalog.branchOrder = append(catalog.branchOrder, branch.ID)
	}
	if err := catalog.Validate(); err != nil {
		return Catalog{}, err
	}
	return catalog, nil
}

func attachDefaultSpells(catalog Catalog, data []byte) (Catalog, error) {
	var artifact SpellArtifact
	if err := decodeArtifact(data, "spells", &artifact); err != nil {
		return Catalog{}, err
	}
	if err := artifact.Validate(); err != nil {
		return Catalog{}, err
	}
	if artifact.SourceRevision != catalog.SourceRevision() || len(artifact.Spells) != 403 || len(artifact.SourceFiles) != 6 {
		return Catalog{}, fmt.Errorf("spell catalog has incomplete pinned coverage")
	}
	statusCounts := map[SpellStatus]int{}
	for _, spell := range artifact.Spells {
		statusCounts[spell.Status]++
	}
	if statusCounts[SpellDefined] != 316 || statusCounts[SpellRemoved] != 86 || statusCounts[SpellSentinel] != 1 {
		return Catalog{}, fmt.Errorf("spell catalog has incorrect status partition")
	}
	paths, err := validSourceFiles(artifact.SourceFiles, "spell")
	if err != nil {
		return Catalog{}, err
	}
	identityHash, sourceHash := sha256.New(), sha256.New()
	for _, spell := range artifact.Spells {
		_, _ = fmt.Fprintf(identityHash, "%d:%s:%s\n", spell.NumericID, spell.ID, spell.Status)
	}
	for _, file := range artifact.SourceFiles {
		_, _ = fmt.Fprintf(sourceHash, "%s:%s\n", file.Path, file.SHA256)
	}
	const pinnedIdentities = "6246d8bef43a5201f5f1010c6be0baddacd23be041bf08a598bf3a1b9817d1ed"
	const pinnedSources = "643fd960be29d053774c841f2970f5e32de898c8da826a37292e3c4ca6a486ec"
	if hex.EncodeToString(identityHash.Sum(nil)) != pinnedIdentities || hex.EncodeToString(sourceHash.Sum(nil)) != pinnedSources {
		return Catalog{}, fmt.Errorf("spell catalog differs from pinned identities, statuses, or source hashes")
	}
	for _, name := range []string{"tag-version.h", "spell-type.h", "spl-data.h", "spl-util.cc", "spl-util.h", "spl-cast.h"} {
		if _, found := paths["crawl-ref/source/"+name]; !found {
			return Catalog{}, fmt.Errorf("spell catalog lacks source %s", name)
		}
	}
	catalog.spells = make(map[string]SpellDef, len(artifact.Spells))
	for _, spell := range artifact.Spells {
		catalog.spells[spell.ID] = spell.clone()
		catalog.spellOrder = append(catalog.spellOrder, spell.ID)
	}
	if err := catalog.Validate(); err != nil {
		return Catalog{}, err
	}
	return catalog, nil
}

// LoadItemsForImport reads only the committed item pair, so the starting-gear
// refresh does not depend on the older gear artifact it is replacing.
func LoadItemsForImport() (Catalog, error) {
	catalog, _, err := loadItemPair(defaultItemsJSON, defaultItemIdentitiesJSON)
	return catalog, err
}

func loadItemPair(itemData, identityData []byte) (Catalog, map[string]string, error) {
	var manifest ItemIdentityManifest
	if err := decodeArtifact(identityData, "item identities", &manifest); err != nil {
		return Catalog{}, nil, err
	}
	var artifact ItemArtifact
	if err := decodeArtifact(itemData, "items", &artifact); err != nil {
		return Catalog{}, nil, err
	}
	if artifact.SourceRevision != sourceRevision || manifest.SourceRevision != sourceRevision {
		return Catalog{}, nil, fmt.Errorf("item source revision differs from pinned revision")
	}
	if len(manifest.Identities) != 408 || len(artifact.Items) != 368 || len(manifest.Aliases) != 10 {
		return Catalog{}, nil, fmt.Errorf("item catalog has incomplete identity or definition coverage")
	}
	if err := artifact.Validate(manifest); err != nil {
		return Catalog{}, nil, err
	}
	files, err := validSourceFiles(artifact.SourceFiles, "item")
	if err != nil {
		return Catalog{}, nil, err
	}
	catalog := Catalog{
		items:          make(map[string]ItemDef, len(artifact.Items)),
		itemIdentities: make(map[string]ItemIdentity, len(manifest.Identities)),
	}
	for _, identity := range manifest.Identities {
		catalog.itemIdentities[identity.ID] = identity
	}
	for _, item := range artifact.Items {
		catalog.items[item.ID] = item.clone()
	}
	return catalog, files, nil
}

func decodeArtifact(data []byte, name string, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return fmt.Errorf("decode %s artifact: %w", name, err)
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF {
		return fmt.Errorf("decode %s artifact: trailing data", name)
	}
	return nil
}

func validSourceFiles(files []JobSourceFile, name string) (map[string]string, error) {
	paths := make(map[string]string, len(files))
	previous := ""
	for _, file := range files {
		if file.Path <= previous || len(file.SHA256) != 64 {
			return nil, fmt.Errorf("invalid or unsorted %s source file %q", name, file.Path)
		}
		if _, err := hex.DecodeString(file.SHA256); err != nil {
			return nil, fmt.Errorf("invalid %s source hash for %s: %w", name, file.Path, err)
		}
		paths[file.Path] = file.SHA256
		previous = file.Path
	}
	return paths, nil
}

func loadDefault(speciesData, jobData, itemData, identityData, gearData, presentationData, monsterData []byte) (Catalog, error) {
	var artifact SpeciesArtifact
	if err := decodeArtifact(speciesData, "species", &artifact); err != nil {
		return Catalog{}, err
	}
	if artifact.SchemaVersion != 1 || artifact.SourceRevision != sourceRevision || artifact.TagMajorVersion != 34 {
		return Catalog{}, fmt.Errorf("unsupported species artifact schema/revision/tag")
	}
	if len(artifact.Species) != 43 || len(artifact.SourceFiles) != 46 {
		return Catalog{}, fmt.Errorf("species artifact has incomplete records or provenance")
	}
	if err := artifact.Validate(); err != nil {
		return Catalog{}, err
	}
	speciesFiles := make([]JobSourceFile, 0, len(artifact.SourceFiles))
	for _, file := range artifact.SourceFiles {
		speciesFiles = append(speciesFiles, JobSourceFile{
			Path:   file.Path,
			SHA256: file.SHA256,
		})
	}
	hashedPaths, err := validSourceFiles(speciesFiles, "species")
	if err != nil {
		return Catalog{}, err
	}
	catalog := scenarioCatalog()
	catalog.species = make(map[string]SpeciesDef, len(artifact.Species))
	previous := ""
	for _, species := range artifact.Species {
		if _, found := hashedPaths[species.SourcePath]; species.ID <= previous || !found {
			return Catalog{}, fmt.Errorf("invalid order or source path for species %s", species.ID)
		}
		catalog.species[species.ID] = species
		previous = species.ID
	}
	var jobs JobArtifact
	if err := decodeArtifact(jobData, "job", &jobs); err != nil {
		return Catalog{}, err
	}
	if jobs.SchemaVersion != 1 || jobs.SourceRevision != artifact.SourceRevision || jobs.TagMajorVersion != artifact.TagMajorVersion {
		return Catalog{}, fmt.Errorf("unsupported or mismatched job artifact schema/revision/tag")
	}
	if len(jobs.Jobs) != 31 || len(jobs.SourceFiles) != 6 {
		return Catalog{}, fmt.Errorf("job artifact has incomplete records or provenance")
	}
	if err := jobs.Validate(); err != nil {
		return Catalog{}, err
	}
	jobPaths, err := validSourceFiles(jobs.SourceFiles, "job")
	if err != nil {
		return Catalog{}, err
	}
	for path, hash := range jobPaths {
		if speciesHash, shared := hashedPaths[path]; shared && speciesHash != hash {
			return Catalog{}, fmt.Errorf("shared source hash differs for %s", path)
		}
	}
	catalog.jobs = make(map[string]JobDef, len(jobs.Jobs))
	previous = ""
	for _, job := range jobs.Jobs {
		if _, found := jobPaths[job.SourcePath]; job.ID <= previous || !found {
			return Catalog{}, fmt.Errorf("invalid order or source path for job %s", job.ID)
		}
		for _, speciesID := range job.RecommendedSpecies {
			if _, ok := catalog.species[speciesID]; !ok {
				return Catalog{}, fmt.Errorf("job %s recommends missing species %s", job.ID, speciesID)
			}
		}
		catalog.jobs[job.ID] = job
		previous = job.ID
	}
	for _, species := range catalog.species {
		for _, jobID := range species.RecommendedJobs {
			if _, ok := catalog.jobs[jobID]; !ok {
				return Catalog{}, fmt.Errorf("species %s recommends missing job %s", species.ID, jobID)
			}
		}
	}
	itemCatalog, itemPaths, err := loadItemPair(itemData, identityData)
	if err != nil {
		return Catalog{}, err
	}
	for path, hash := range itemPaths {
		if prior, shared := hashedPaths[path]; shared && prior != hash {
			return Catalog{}, fmt.Errorf("shared species/item source hash differs for %s", path)
		}
		if prior, shared := jobPaths[path]; shared && prior != hash {
			return Catalog{}, fmt.Errorf("shared job/item source hash differs for %s", path)
		}
	}
	catalog.items, catalog.itemIdentities = itemCatalog.items, itemCatalog.itemIdentities
	var gear StartingGearArtifact
	if err := decodeArtifact(gearData, "starting gear", &gear); err != nil {
		return Catalog{}, err
	}
	if gear.SchemaVersion != 2 || gear.SourceRevision != artifact.SourceRevision || gear.TagMajorVersion != artifact.TagMajorVersion {
		return Catalog{}, fmt.Errorf("unsupported or mismatched starting gear artifact schema/revision/tag")
	}
	if len(gear.Jobs) != 25 || len(gear.SourceFiles) != 14 {
		return Catalog{}, fmt.Errorf("starting gear artifact has incomplete records or provenance")
	}
	if err := gear.Validate(catalog); err != nil {
		return Catalog{}, err
	}
	gearPaths, err := validSourceFiles(gear.SourceFiles, "starting gear")
	if err != nil {
		return Catalog{}, err
	}
	for path, hash := range gearPaths {
		if speciesHash, shared := hashedPaths[path]; shared && speciesHash != hash {
			return Catalog{}, fmt.Errorf("shared species/gear source hash differs for %s", path)
		}
		if jobHash, shared := jobPaths[path]; shared && jobHash != hash {
			return Catalog{}, fmt.Errorf("shared job/gear source hash differs for %s", path)
		}
		if itemHash, shared := itemPaths[path]; shared && itemHash != hash {
			return Catalog{}, fmt.Errorf("shared item/gear source hash differs for %s", path)
		}
	}
	for path := range jobPaths {
		if _, found := gearPaths[path]; !found {
			return Catalog{}, fmt.Errorf("starting gear artifact lacks job source %s", path)
		}
	}
	for _, id := range []string{"POT_CURING", "WPN_SHORT_SWORD", "WPN_MACE", "WPN_HAND_AXE", "WPN_SPEAR", "WPN_FALCHION", "WPN_QUARTERSTAFF", "WPN_RAPIER", "WPN_FLAIL", "WPN_WAR_AXE", "WPN_TRIDENT", "WPN_LONG_SWORD"} {
		if _, found := catalog.items[id]; !found {
			return Catalog{}, fmt.Errorf("item catalog lacks required item kind %s", id)
		}
	}
	if _, found := catalog.items["WPN_UNARMED"]; found {
		return Catalog{}, fmt.Errorf("unarmed choice must not be an item kind")
	}
	catalog.startingGear = make(map[string][]StartingGrant, len(gear.Jobs))
	previous = ""
	for _, entry := range gear.Jobs {
		if entry.JobID <= previous {
			return Catalog{}, fmt.Errorf("starting gear jobs are not sorted by ID")
		}
		job, found := catalog.jobs[entry.JobID]
		if !found || !job.Selectable || len(entry.Grants) != len(job.Equipment) {
			return Catalog{}, fmt.Errorf("starting gear job %s disagrees with committed jobs", entry.JobID)
		}
		for i, grant := range entry.Grants {
			if grant.Raw != job.Equipment[i] {
				return Catalog{}, fmt.Errorf("starting gear job %s grant %d raw spec/order differs from jobs", entry.JobID, i)
			}
		}
		catalog.startingGear[entry.JobID] = append([]StartingGrant(nil), entry.Grants...)
		previous = entry.JobID
	}
	for id, job := range catalog.jobs {
		_, found := catalog.startingGear[id]
		if job.Selectable != found {
			return Catalog{}, fmt.Errorf("starting gear coverage differs for job %s", id)
		}
	}
	var monsters MonsterArtifact
	if err := decodeArtifact(monsterData, "monster", &monsters); err != nil {
		return Catalog{}, err
	}
	if monsters.SchemaVersion != 1 || monsters.SourceRevision != artifact.SourceRevision || monsters.TagMajorVersion != artifact.TagMajorVersion {
		return Catalog{}, fmt.Errorf("unsupported or mismatched monster artifact schema/revision/tag")
	}
	if len(monsters.Monsters) != 700 || len(monsters.SourceFiles) != 11 {
		return Catalog{}, fmt.Errorf("monster artifact has incomplete records or provenance")
	}
	if err := monsters.Validate(); err != nil {
		return Catalog{}, err
	}
	var vocabulary MonsterVocabulary
	if err := decodeArtifact(defaultMonsterVocabularyJSON, "monster vocabulary", &vocabulary); err != nil {
		return Catalog{}, err
	}
	if err := vocabulary.ValidateArtifact(monsters); err != nil {
		return Catalog{}, err
	}
	monsterPaths, err := validSourceFiles(monsters.SourceFiles, "monster")
	if err != nil {
		return Catalog{}, err
	}
	for _, name := range []string{"colour.h", "defines.h", "mon-data.h", "mon-enum.h", "mon-flags.h", "mon-holy-type.h", "mon-mst.h", "mon-util.h", "monster-type.h", "size-type.h", "tag-version.h"} {
		if _, found := monsterPaths["crawl-ref/source/"+name]; !found {
			return Catalog{}, fmt.Errorf("monster artifact lacks source %s", name)
		}
	}
	for path, hash := range monsterPaths {
		for _, previous := range []map[string]string{hashedPaths, jobPaths, itemPaths, gearPaths} {
			if known, shared := previous[path]; shared && known != hash {
				return Catalog{}, fmt.Errorf("shared monster source hash differs for %s", path)
			}
		}
	}
	catalog.monsters = make(map[string]MonsterDef, len(monsters.Monsters))
	counts := map[MonsterStatus]int{}
	for _, monster := range monsters.Monsters {
		if _, found := monsterPaths[monster.SourcePath]; !found {
			return Catalog{}, fmt.Errorf("monster %s lacks source provenance", monster.ID)
		}
		counts[monster.Status]++
		catalog.monsters[monster.ID] = monster.clone()
	}
	if counts[MonsterDefined] != 562 || counts[MonsterRemoved] != 120 || counts[MonsterEnumOnly] != 18 {
		return Catalog{}, fmt.Errorf("monster artifact has wrong status partition")
	}
	for _, monster := range monsters.Monsters {
		if monster.Status == MonsterDefined {
			if _, found := catalog.monsters[monster.GenusID]; !found {
				return Catalog{}, fmt.Errorf("monster %s has unknown genus %s", monster.ID, monster.GenusID)
			}
			if _, found := catalog.monsters[monster.SpeciesID]; !found {
				return Catalog{}, fmt.Errorf("monster %s has unknown species %s", monster.ID, monster.SpeciesID)
			}
		}
	}
	if len(presentationData) > 0 {
		var presentation PresentationArtifact
		if err := decodeArtifact(presentationData, "presentation", &presentation); err != nil {
			return Catalog{}, err
		}
		if err := presentation.validate(catalog); err != nil {
			return Catalog{}, err
		}
		presentationPaths, err := validSourceFiles(presentation.SourceFiles, "presentation")
		if err != nil {
			return Catalog{}, err
		}
		for path, hash := range presentationPaths {
			if previous, shared := hashedPaths[path]; shared && previous != hash {
				return Catalog{}, fmt.Errorf("shared species/presentation source hash differs for %s", path)
			}
			if previous, shared := jobPaths[path]; shared && previous != hash {
				return Catalog{}, fmt.Errorf("shared job/presentation source hash differs for %s", path)
			}
			if previous, shared := gearPaths[path]; shared && previous != hash {
				return Catalog{}, fmt.Errorf("shared gear/presentation source hash differs for %s", path)
			}
		}
		catalog.presentation = presentation
	}
	if err := catalog.Validate(); err != nil {
		return Catalog{}, err
	}
	return catalog, nil
}
