package content

import (
	"encoding/json"
	"slices"
	"strings"
	"testing"
)

func TestLoadDefaultPresentationOrderAndProvenance(t *testing.T) {
	catalog := mustLoadDefault(t)
	p := catalog.Presentation()
	if p.SchemaVersion != 1 || p.SourceRevision != sourceRevision || p.TagMajorVersion != 34 {
		t.Fatalf("presentation provenance: %+v", p)
	}
	if p.SourceVersion != "0.30-a0-23-ge60ba3568b0" {
		t.Fatalf("source banner version: %q", p.SourceVersion)
	}
	if len(p.SpeciesGroups) != 3 || len(p.JobGroups) != 5 {
		t.Fatalf("menu group counts: %d species, %d jobs", len(p.SpeciesGroups), len(p.JobGroups))
	}
	if len(p.StartupModes) != 8 || p.StartupModes[0].ID != "GAME_TYPE_NORMAL" || p.StartupModes[0].Label != "Dungeon Crawl" || p.StartupModes[7].ID != "GAME_TYPE_HIGH_SCORES" {
		t.Fatalf("source startup mode order: %+v", p.StartupModes)
	}
	if len(p.SkillColumns) != 2 || len(p.SkillColumns[0]) != 16 || len(p.SkillColumns[1]) != 16 || p.SkillColumns[0][0] != "SK_FIGHTING" || p.SkillColumns[1][0] != "SK_SPELLCASTING" {
		t.Fatalf("source skill display columns: %+v", p.SkillColumns)
	}
	if !strings.Contains(p.StartupModes[0].Description, "monsters, items") {
		t.Fatalf("startup description: %+v", p.StartupModes[0])
	}
	var species, jobs []string
	for _, group := range p.SpeciesGroups {
		species = append(species, group.IDs...)
	}
	for _, group := range p.JobGroups {
		jobs = append(jobs, group.IDs...)
	}
	if len(species) != 27 || species[0] != "SP_HILL_ORC" || species[len(species)-1] != "SP_MUMMY" {
		t.Fatalf("species menu order: %v", species)
	}
	if len(jobs) != 25 || jobs[0] != "JOB_FIGHTER" || jobs[len(jobs)-1] != "JOB_VENOM_MAGE" {
		t.Fatalf("job menu order: %v", jobs)
	}
	if !slices.Equal([]string{p.SpeciesGroups[0].Label, p.SpeciesGroups[1].Label, p.SpeciesGroups[2].Label}, []string{"Simple", "Intermediate", "Advanced"}) {
		t.Fatalf("species labels: %+v", p.SpeciesGroups)
	}
	if !strings.Contains(p.SpeciesDescriptions["SP_HUMAN"], "Humans advance quickly") || !strings.Contains(p.JobDescriptions["JOB_FIGHTER"], "Fighters are equipped") {
		t.Fatal("source description prose missing")
	}
	wantHashes := map[string]string{
		"crawl-ref/source/species-groups.h":             "8cbc7cf3b24fbe904d9ce193d04ffcee7b27bfaa4fa44328210c7365b40b9a28",
		"crawl-ref/source/newgame.cc":                   "32e2055c3b71002a2a3610c322fa05b35f8a8b05f00411df46f1de70adf8ef69",
		"crawl-ref/source/dat/descript/species.txt":     "7abe5f3033ae02981f8af6956add4db2f1e08ed69e688d5e213e0e906ee1fb5e",
		"crawl-ref/source/dat/descript/backgrounds.txt": "1263736a450652589bbeb6a4cd3d6e57a092059ff34040263af7a33333803570",
		"crawl-ref/source/tag-version.h":                "2f8ed7610ca03ba6014044f78ca9f9b9392208a37d3539119ef04bd853ab1dfa",
		"crawl-ref/source/startup.cc":                   "82aef31832467f8797e0fd2d5f2818974fe1ddc2213c70445a062f2493282d2f",
		"crawl-ref/source/skills.h":                     "6e43be85f9d80827d8a2a92229751d991069c8e8dd574b51a90edf078972f4c7",
	}
	if len(p.SourceFiles) != len(wantHashes) {
		t.Fatalf("source files: %+v", p.SourceFiles)
	}
	for _, file := range p.SourceFiles {
		if wantHashes[file.Path] != file.SHA256 {
			t.Fatalf("source hash for %s: %s", file.Path, file.SHA256)
		}
	}
}

func TestPresentationReturnedAsDefensiveCopy(t *testing.T) {
	catalog := mustLoadDefault(t)
	first := catalog.Presentation()
	first.SpeciesGroups[0].IDs[0] = "SP_BOGUS"
	first.SpeciesDescriptions["SP_HUMAN"] = "changed"
	first.SourceFiles[0].SHA256 = "changed"
	first.SkillColumns[0][0] = "SK_FAKE"
	again := catalog.Presentation()
	if again.SpeciesGroups[0].IDs[0] != "SP_HILL_ORC" || again.SpeciesDescriptions["SP_HUMAN"] == "changed" || again.SourceFiles[0].SHA256 == "changed" || again.SkillColumns[0][0] == "SK_FAKE" {
		t.Fatal("caller mutated catalog presentation")
	}
}

func TestLoadDefaultRejectsMalformedPresentation(t *testing.T) {
	var original PresentationArtifact
	if err := json.Unmarshal(defaultPresentationJSON, &original); err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		name   string
		change func(*PresentationArtifact)
		want   string
	}{
		{"missing description", func(a *PresentationArtifact) { delete(a.SpeciesDescriptions, "SP_HUMAN") }, "SP_HUMAN"},
		{"duplicate menu ID", func(a *PresentationArtifact) { a.SpeciesGroups[0].IDs = append(a.SpeciesGroups[0].IDs, "SP_HILL_ORC") }, "SP_HILL_ORC"},
		{"unknown catalog ID", func(a *PresentationArtifact) { a.JobGroups[0].IDs[0] = "JOB_NOT_REAL" }, "JOB_NOT_REAL"},
		{"unknown skill ID", func(a *PresentationArtifact) { a.SkillColumns[0][0] = "SK_NOT_REAL" }, "SK_NOT_REAL"},
		{"duplicate skill ID", func(a *PresentationArtifact) { a.SkillColumns[1][0] = "SK_FIGHTING" }, "SK_FIGHTING"},
		{"nonselectable catalog ID", func(a *PresentationArtifact) {
			a.SpeciesGroups[0].IDs[0] = "SP_HIGH_ELF"
			delete(a.SpeciesDescriptions, "SP_HILL_ORC")
			a.SpeciesDescriptions["SP_HIGH_ELF"] = "Deprecated species."
		}, "SP_HIGH_ELF"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			data, err := json.Marshal(original)
			if err != nil {
				t.Fatal(err)
			}
			var changed PresentationArtifact
			if err := json.Unmarshal(data, &changed); err != nil {
				t.Fatal(err)
			}
			tc.change(&changed)
			data, err = json.Marshal(changed)
			if err != nil {
				t.Fatal(err)
			}
			_, err = loadDefault(defaultSpeciesJSON, defaultJobsJSON, defaultItemsJSON, defaultItemIdentitiesJSON, defaultStartingGearJSON, data, defaultMonsterJSON)
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("want %s error, got %v", tc.want, err)
			}
		})
	}
}

func TestLoadDefinitionsForImportDoesNotRequirePresentation(t *testing.T) {
	catalog, err := LoadDefinitionsForImport()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := catalog.Species("SP_HUMAN"); err != nil {
		t.Fatal(err)
	}
	if _, err := catalog.Job("JOB_FIGHTER"); err != nil {
		t.Fatal(err)
	}
	if len(catalog.Presentation().SpeciesGroups) != 0 {
		t.Fatal("import definitions unexpectedly depend on presentation")
	}
}
