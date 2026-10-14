package content

import "fmt"

// defaultCatalogLoader keeps provenance and catalog assembly together while
// committed artifacts are checked in dependency order.
type defaultCatalogLoader struct {
	catalog Catalog

	speciesArtifact SpeciesArtifact

	speciesPaths map[string]string
	jobPaths     map[string]string
	itemPaths    map[string]string
	gearPaths    map[string]string
}

func (l *defaultCatalogLoader) loadSpecies(speciesData []byte) error {
	var artifact SpeciesArtifact

	if err := decodeArtifact(speciesData, "species", &artifact); err != nil {
		return err
	}

	if artifact.SchemaVersion != 1 ||
		artifact.SourceRevision != sourceRevision || artifact.TagMajorVersion != 34 {
		return fmt.Errorf("unsupported species artifact schema/revision/tag")
	}

	if len(artifact.Species) != 43 || len(artifact.SourceFiles) != 46 {
		return fmt.Errorf("species artifact has incomplete records or provenance")
	}

	if err := artifact.Validate(); err != nil {
		return err
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
		return err
	}

	catalog := &l.catalog
	catalog.species = make(map[string]SpeciesDef, len(artifact.Species))
	previous := ""

	for _, species := range artifact.Species {
		if _, found := hashedPaths[species.SourcePath]; species.ID <= previous ||
			!found {
			return fmt.Errorf("invalid order or source path for species %s", species.ID)
		}

		catalog.species[species.ID] = species
		previous = species.ID
	}

	l.speciesArtifact = artifact
	l.speciesPaths = hashedPaths

	return nil
}

func (l *defaultCatalogLoader) loadJobs(jobData []byte) error {
	artifact := l.speciesArtifact
	hashedPaths := l.speciesPaths
	catalog := &l.catalog
	previous := ""

	var jobs JobArtifact

	if err := decodeArtifact(jobData, "job", &jobs); err != nil {
		return err
	}

	if jobs.SchemaVersion != 1 ||
		jobs.SourceRevision != artifact.SourceRevision ||
		jobs.TagMajorVersion != artifact.TagMajorVersion {
		return fmt.Errorf("unsupported or mismatched job artifact schema/revision/tag")
	}

	if len(jobs.Jobs) != 31 || len(jobs.SourceFiles) != 6 {
		return fmt.Errorf("job artifact has incomplete records or provenance")
	}

	if err := jobs.Validate(); err != nil {
		return err
	}

	jobPaths, err := validSourceFiles(jobs.SourceFiles, "job")

	if err != nil {
		return err
	}

	for path, hash := range jobPaths {
		if speciesHash, shared := hashedPaths[path]; shared && speciesHash != hash {
			return fmt.Errorf("shared source hash differs for %s", path)
		}
	}

	catalog.jobs = make(map[string]JobDef, len(jobs.Jobs))
	previous = ""

	for _, job := range jobs.Jobs {
		if _, found := jobPaths[job.SourcePath]; job.ID <= previous || !found {
			return fmt.Errorf("invalid order or source path for job %s", job.ID)
		}

		for _, speciesID := range job.RecommendedSpecies {
			if _, ok := catalog.species[speciesID]; !ok {
				return fmt.Errorf("job %s recommends missing species %s", job.ID, speciesID)
			}
		}

		catalog.jobs[job.ID] = job
		previous = job.ID
	}

	for _, species := range catalog.species {
		for _, jobID := range species.RecommendedJobs {
			if _, ok := catalog.jobs[jobID]; !ok {
				return fmt.Errorf("species %s recommends missing job %s", species.ID, jobID)
			}
		}
	}

	l.jobPaths = jobPaths

	return nil
}

func (l *defaultCatalogLoader) loadItems(itemData, identityData []byte) error {
	hashedPaths := l.speciesPaths
	jobPaths := l.jobPaths
	catalog := &l.catalog

	itemCatalog, itemPaths, err := loadItemPair(itemData, identityData)

	if err != nil {
		return err
	}

	for path, hash := range itemPaths {
		if prior, shared := hashedPaths[path]; shared && prior != hash {
			return fmt.Errorf("shared species/item source hash differs for %s", path)
		}

		if prior, shared := jobPaths[path]; shared && prior != hash {
			return fmt.Errorf("shared job/item source hash differs for %s", path)
		}
	}

	catalog.items = itemCatalog.items
	catalog.itemIdentities = itemCatalog.itemIdentities

	l.itemPaths = itemPaths

	return nil
}

func (l *defaultCatalogLoader) loadGear(gearData []byte) error {
	var gear StartingGearArtifact

	if err := decodeArtifact(gearData, "starting gear", &gear); err != nil {
		return err
	}

	if gear.SchemaVersion != 2 ||
		gear.SourceRevision != l.speciesArtifact.SourceRevision ||
		gear.TagMajorVersion != l.speciesArtifact.TagMajorVersion {
		return fmt.Errorf("unsupported or mismatched starting gear artifact schema/revision/tag")
	}

	if len(gear.Jobs) != 25 || len(gear.SourceFiles) != 14 {
		return fmt.Errorf("starting gear artifact has incomplete records or provenance")
	}

	if err := gear.Validate(l.catalog); err != nil {
		return err
	}

	gearPaths, err := l.validateGearSources(gear.SourceFiles)

	if err != nil {
		return err
	}

	if err := l.installGear(gear.Jobs); err != nil {
		return err
	}

	l.gearPaths = gearPaths

	return nil
}

func (l *defaultCatalogLoader) validateGearSources(
	files []JobSourceFile,
) (map[string]string, error) {
	gearPaths, err := validSourceFiles(files, "starting gear")

	if err != nil {
		return nil, err
	}

	for path, hash := range gearPaths {
		if speciesHash, shared := l.speciesPaths[path]; shared &&
			speciesHash != hash {
			return nil, fmt.Errorf("shared species/gear source hash differs for %s", path)
		}

		if jobHash, shared := l.jobPaths[path]; shared && jobHash != hash {
			return nil, fmt.Errorf("shared job/gear source hash differs for %s", path)
		}

		if itemHash, shared := l.itemPaths[path]; shared && itemHash != hash {
			return nil, fmt.Errorf("shared item/gear source hash differs for %s", path)
		}
	}

	for path := range l.jobPaths {
		if _, found := gearPaths[path]; !found {
			return nil, fmt.Errorf("starting gear artifact lacks job source %s", path)
		}
	}

	return gearPaths, nil
}

func (l *defaultCatalogLoader) installGear(entries []JobStartingGear) error {
	catalog := &l.catalog

	for _, id := range []string{
		"POT_CURING",
		"WPN_SHORT_SWORD",
		"WPN_MACE",
		"WPN_HAND_AXE",
		"WPN_SPEAR",
		"WPN_FALCHION",
		"WPN_QUARTERSTAFF",
		"WPN_RAPIER",
		"WPN_FLAIL",
		"WPN_WAR_AXE",
		"WPN_TRIDENT",
		"WPN_LONG_SWORD",
	} {
		if _, found := catalog.items[id]; !found {
			return fmt.Errorf("item catalog lacks required item kind %s", id)
		}
	}

	if _, found := catalog.items["WPN_UNARMED"]; found {
		return fmt.Errorf("unarmed choice must not be an item kind")
	}

	catalog.startingGear = make(map[string][]StartingGrant, len(entries))
	previous := ""

	for _, entry := range entries {
		if entry.JobID <= previous {
			return fmt.Errorf("starting gear jobs are not sorted by ID")
		}

		job, found := catalog.jobs[entry.JobID]

		if !found ||
			!job.Selectable || len(entry.Grants) != len(job.Equipment) {
			return fmt.Errorf("starting gear job %s disagrees with committed jobs", entry.JobID)
		}

		for i, grant := range entry.Grants {
			if grant.Raw != job.Equipment[i] {
				return fmt.Errorf("starting gear job %s grant %d raw spec/order differs from jobs",
					entry.JobID, i)
			}
		}

		catalog.startingGear[entry.JobID] = append([]StartingGrant(nil), entry.Grants...)
		previous = entry.JobID
	}

	for id, job := range catalog.jobs {
		_, found := catalog.startingGear[id]

		if job.Selectable != found {
			return fmt.Errorf("starting gear coverage differs for job %s", id)
		}
	}

	return nil
}

func (l *defaultCatalogLoader) loadMonsters(monsterData []byte) error {
	var monsters MonsterArtifact

	if err := decodeArtifact(monsterData, "monster", &monsters); err != nil {
		return err
	}

	if monsters.SchemaVersion != 1 ||
		monsters.SourceRevision != l.speciesArtifact.SourceRevision ||
		monsters.TagMajorVersion != l.speciesArtifact.TagMajorVersion {
		return fmt.Errorf("unsupported or mismatched monster artifact schema/revision/tag")
	}

	if len(monsters.Monsters) != 700 || len(monsters.SourceFiles) != 11 {
		return fmt.Errorf("monster artifact has incomplete records or provenance")
	}

	if err := monsters.Validate(); err != nil {
		return err
	}

	var vocabulary MonsterVocabulary

	if err := decodeArtifact(defaultMonsterVocabularyJSON,
		"monster vocabulary", &vocabulary); err != nil {
		return err
	}

	if err := vocabulary.ValidateArtifact(monsters); err != nil {
		return err
	}

	monsterPaths, err := l.validateMonsterSources(monsters.SourceFiles)

	if err != nil {
		return err
	}

	return l.installMonsters(monsters.Monsters, monsterPaths)
}

func (l *defaultCatalogLoader) validateMonsterSources(
	files []JobSourceFile,
) (map[string]string, error) {
	monsterPaths, err := validSourceFiles(files, "monster")

	if err != nil {
		return nil, err
	}

	for _, name := range []string{
		"colour.h",
		"defines.h",
		"mon-data.h",
		"mon-enum.h",
		"mon-flags.h",
		"mon-holy-type.h",
		"mon-mst.h",
		"mon-util.h",
		"monster-type.h",
		"size-type.h",
		"tag-version.h",
	} {
		if _, found := monsterPaths["crawl-ref/source/"+name]; !found {
			return nil, fmt.Errorf("monster artifact lacks source %s", name)
		}
	}

	for path, hash := range monsterPaths {
		for _, previous := range []map[string]string{
			l.speciesPaths,
			l.jobPaths,
			l.itemPaths,
			l.gearPaths,
		} {
			if known, shared := previous[path]; shared && known != hash {
				return nil, fmt.Errorf("shared monster source hash differs for %s", path)
			}
		}
	}

	return monsterPaths, nil
}

func (l *defaultCatalogLoader) installMonsters(
	entries []MonsterDef,
	monsterPaths map[string]string,
) error {
	l.catalog.monsters = make(map[string]MonsterDef, len(entries))
	counts := map[MonsterStatus]int{}

	for _, monster := range entries {
		if _, found := monsterPaths[monster.SourcePath]; !found {
			return fmt.Errorf("monster %s lacks source provenance", monster.ID)
		}

		counts[monster.Status]++
		l.catalog.monsters[monster.ID] = monster.clone()
	}

	if counts[MonsterDefined] != 562 ||
		counts[MonsterRemoved] != 120 || counts[MonsterEnumOnly] != 18 {
		return fmt.Errorf("monster artifact has wrong status partition")
	}

	for _, monster := range entries {
		if monster.Status == MonsterDefined {
			if _, found := l.catalog.monsters[monster.GenusID]; !found {
				return fmt.Errorf("monster %s has unknown genus %s", monster.ID, monster.GenusID)
			}

			if _, found := l.catalog.monsters[monster.SpeciesID]; !found {
				return fmt.Errorf("monster %s has unknown species %s", monster.ID, monster.SpeciesID)
			}
		}
	}

	return nil
}

func (l *defaultCatalogLoader) loadPresentation(presentationData []byte) error {
	if len(presentationData) == 0 {
		return nil
	}

	hashedPaths := l.speciesPaths
	jobPaths := l.jobPaths
	gearPaths := l.gearPaths
	catalog := &l.catalog

	var presentation PresentationArtifact

	if err := decodeArtifact(presentationData, "presentation", &presentation); err != nil {
		return err
	}

	if err := presentation.validate(*catalog); err != nil {
		return err
	}

	presentationPaths, err := validSourceFiles(presentation.SourceFiles, "presentation")

	if err != nil {
		return err
	}

	for path, hash := range presentationPaths {
		if previous, shared := hashedPaths[path]; shared && previous != hash {
			return fmt.Errorf("shared species/presentation source hash differs for %s", path)
		}

		if previous, shared := jobPaths[path]; shared && previous != hash {
			return fmt.Errorf("shared job/presentation source hash differs for %s", path)
		}

		if previous, shared := gearPaths[path]; shared && previous != hash {
			return fmt.Errorf("shared gear/presentation source hash differs for %s", path)
		}
	}

	catalog.presentation = presentation

	return nil
}
