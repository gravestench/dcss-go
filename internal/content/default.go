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

//go:embed generated/monster-spellbooks.json
var defaultMonsterSpellbookJSON []byte

//go:embed generated/branches.json
var defaultBranchJSON []byte

//go:embed generated/dungeon-population.json
var defaultDungeonPopulationJSON []byte

// LoadDefault builds a fresh catalog from the checked-in source-traced artifacts.
func LoadDefault() (Catalog, error) {
	catalog, err := loadDefault(
		defaultSpeciesJSON,
		defaultJobsJSON,
		defaultItemsJSON,
		defaultItemIdentitiesJSON,
		defaultStartingGearJSON,
		defaultPresentationJSON,
		defaultMonsterJSON,
	)

	if err != nil {
		return Catalog{}, err
	}

	catalog, err = attachDefaultSpells(catalog, defaultSpellJSON)

	if err != nil {
		return Catalog{}, err
	}

	catalog, err = attachDefaultMonsterSpellbooks(catalog, defaultMonsterSpellbookJSON)

	if err != nil {
		return Catalog{}, err
	}

	catalog, err = attachDefaultBranches(catalog, defaultBranchJSON)

	if err != nil {
		return Catalog{}, err
	}

	return attachDefaultDungeonPopulation(catalog, defaultDungeonPopulationJSON)
}

// LoadDefaultSpells gives content refresh tools the committed spell identities
// without requiring any other catalog category to load successfully.
func LoadDefaultSpells() (Catalog, error) {
	return attachDefaultSpells(scenarioCatalog(), defaultSpellJSON)
}

// LoadDefinitionsForImport reads committed gameplay definitions without needing
// the presentation artifact that the refresh tool is about to regenerate.
func LoadDefinitionsForImport() (Catalog, error) {
	catalog, err := loadDefault(
		defaultSpeciesJSON,
		defaultJobsJSON,
		defaultItemsJSON,
		defaultItemIdentitiesJSON,
		defaultStartingGearJSON,
		nil,
		defaultMonsterJSON,
	)

	if err != nil {
		return Catalog{}, err
	}

	catalog, err = attachDefaultSpells(catalog, defaultSpellJSON)

	if err != nil {
		return Catalog{}, err
	}

	catalog, err = attachDefaultMonsterSpellbooks(catalog, defaultMonsterSpellbookJSON)

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

	if artifact.SourceRevision != catalog.SourceRevision() ||
		len(artifact.Rows) != 125 || len(artifact.SourceFiles) != 3 {
		return Catalog{}, fmt.Errorf("Dungeon population has incomplete pinned coverage")
	}

	paths, err := validSourceFiles(artifact.SourceFiles, "Dungeon population")

	if err != nil {
		return Catalog{}, err
	}

	for _, name := range []string{
		"mon-pick-data.h",
		"random-pick.h",
		"tag-version.h",
	} {
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

	if artifact.SourceRevision != catalog.SourceRevision() ||
		len(artifact.Branches) != 38 {
		return Catalog{}, fmt.Errorf("branch catalog has incomplete pinned coverage")
	}

	paths, err := validSourceFiles(artifact.SourceFiles, "branch")

	if err != nil {
		return Catalog{}, err
	}

	for _, name := range []string{
		"tag-version.h",
		"branch-type.h",
		"branch-data.h",
	} {
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

	if artifact.SourceRevision != catalog.SourceRevision() ||
		len(artifact.Spells) != 403 ||
		len(artifact.SourceFiles) != 6 {
		return Catalog{}, fmt.Errorf("spell catalog has incomplete pinned coverage")
	}

	statusCounts := map[SpellStatus]int{}

	for _, spell := range artifact.Spells {
		statusCounts[spell.Status]++
	}

	if statusCounts[SpellDefined] != 316 ||
		statusCounts[SpellRemoved] != 86 || statusCounts[SpellSentinel] != 1 {
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

	if hex.EncodeToString(identityHash.Sum(nil)) != pinnedIdentities ||
		hex.EncodeToString(sourceHash.Sum(nil)) != pinnedSources {
		return Catalog{}, fmt.Errorf(
			"spell catalog differs from pinned identities, statuses, or source hashes",
		)
	}

	for _, name := range []string{
		"tag-version.h",
		"spell-type.h",
		"spl-data.h",
		"spl-util.cc",
		"spl-util.h",
		"spl-cast.h",
	} {
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

func attachDefaultMonsterSpellbooks(catalog Catalog, data []byte) (Catalog, error) {
	var artifact MonsterSpellbookArtifact

	if err := decodeArtifact(data, "monster spellbooks", &artifact); err != nil {
		return Catalog{}, err
	}

	if err := artifact.Validate(); err != nil {
		return Catalog{}, err
	}

	if artifact.SourceRevision != catalog.SourceRevision() ||
		len(artifact.Books) != 285 {
		return Catalog{}, fmt.Errorf("monster spellbooks differ from pinned source")
	}

	paths, err := validSourceFiles(artifact.SourceFiles, "monster spellbooks")

	if err != nil {
		return Catalog{}, err
	}

	if paths["crawl-ref/source/externs.h"] !=
		"6a1f394df9a93e6a411680a1ca6a69524bc29259c16cc2e9850ee0aac168a211" ||
		paths["crawl-ref/source/mon-mst.h"] !=
			"d73ad1c8ad8fbd4c82a1f56847c193ffbdd41f617f1b77f98969a1e4fe98f800" ||
		paths["crawl-ref/source/mon-spell.h"] !=
			"ee46cb6314b5464dd617975eb064e271af3448ed4494486d3de3b2c7fef84021" {
		return Catalog{}, fmt.Errorf("monster spellbooks have unexpected source files")
	}

	catalog.monsterSpellbooks = make(map[string]MonsterSpellbook, len(artifact.Books))

	for _, book := range artifact.Books {
		slots := make([]MonsterSpellSlot, len(book.Slots))

		for index, slot := range book.Slots {
			slots[index] = slot
			slots[index].Flags = append([]string(nil), slot.Flags...)
		}

		book.Slots = slots
		catalog.monsterSpellbooks[book.ID] = book
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

	if artifact.SourceRevision != sourceRevision ||
		manifest.SourceRevision != sourceRevision {
		return Catalog{}, nil, fmt.Errorf("item source revision differs from pinned revision")
	}

	if len(manifest.Identities) != 408 ||
		len(artifact.Items) != 368 || len(manifest.Aliases) != 10 {
		return Catalog{}, nil, fmt.Errorf(
			"item catalog has incomplete identity or definition coverage",
		)
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

func loadDefault(
	speciesData, jobData, itemData, identityData []byte,
	gearData, presentationData, monsterData []byte,
) (Catalog, error) {
	loader := defaultCatalogLoader{catalog: scenarioCatalog()}

	if err := loader.loadSpecies(speciesData); err != nil {
		return Catalog{}, err
	}

	if err := loader.loadJobs(jobData); err != nil {
		return Catalog{}, err
	}

	if err := loader.loadItems(itemData, identityData); err != nil {
		return Catalog{}, err
	}

	if err := loader.loadGear(gearData); err != nil {
		return Catalog{}, err
	}

	if err := loader.loadMonsters(monsterData); err != nil {
		return Catalog{}, err
	}

	if err := loader.loadPresentation(presentationData); err != nil {
		return Catalog{}, err
	}

	if err := loader.catalog.Validate(); err != nil {
		return Catalog{}, err
	}

	return loader.catalog, nil
}
