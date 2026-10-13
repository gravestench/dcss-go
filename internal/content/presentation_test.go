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
	if len(p.SpeciesGroups) != 3 || len(p.JobGroups) != 5 {
		t.Fatalf("menu group counts: %d species, %d jobs", len(p.SpeciesGroups), len(p.JobGroups))
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
	again := catalog.Presentation()
	if again.SpeciesGroups[0].IDs[0] != "SP_HILL_ORC" || again.SpeciesDescriptions["SP_HUMAN"] == "changed" || again.SourceFiles[0].SHA256 == "changed" {
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
			_, err = loadDefault(defaultSpeciesJSON, defaultJobsJSON, defaultStartingGearJSON, data)
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
