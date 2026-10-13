package content

import (
	"encoding/json"
	"slices"
	"strings"
	"testing"
)

func TestLoadDefaultJobs(t *testing.T) {
	catalog, err := LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	if got := len(catalog.JobIDs()); got != 31 {
		t.Fatalf("jobs = %d, want 31", got)
	}
	fighter, err := catalog.Job("JOB_FIGHTER")
	if err != nil {
		t.Fatal(err)
	}
	if fighter.Strength != 8 || fighter.Intelligence != 0 || fighter.Dexterity != 4 || !fighter.Selectable {
		t.Fatalf("Fighter modifiers or selectability: %+v", fighter)
	}
	if !slices.Equal(fighter.Equipment, []string{"scale mail", "buckler", "potion of might"}) || !slices.Equal(fighter.Skills, []JobSkillGrant{{"SK_FIGHTING", 3}, {"SK_SHIELDS", 3}, {"SK_ARMOUR", 3}, {"SK_WEAPON", 2}}) {
		t.Fatalf("Fighter gear or skills: %+v", fighter)
	}
	air, err := catalog.Job("JOB_AIR_ELEMENTALIST")
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(air.Spells, []string{"SPELL_SHOCK", "SPELL_DISCHARGE", "SPELL_SWIFTNESS", "SPELL_AIRSTRIKE"}) {
		t.Fatalf("Air Elementalist spell library: %v", air.Spells)
	}
	wanderer, err := catalog.Job("JOB_WANDERER")
	if err != nil {
		t.Fatal(err)
	}
	if !wanderer.Selectable || wanderer.Strength != 0 || wanderer.Intelligence != 0 || wanderer.Dexterity != 0 || len(wanderer.Skills) != 0 {
		t.Fatalf("Wanderer table placeholders: %+v", wanderer)
	}
	for _, id := range []string{"JOB_DEATH_KNIGHT", "JOB_HEALER", "JOB_JESTER", "JOB_PRIEST", "JOB_SKALD", "JOB_STALKER"} {
		job, err := catalog.Job(id)
		if err != nil || job.Selectable {
			t.Fatalf("removed job %s: %+v, %v", id, job, err)
		}
	}
	fighter.Equipment[0] = "altered"
	second, err := LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	again, err := second.Job("JOB_FIGHTER")
	if err != nil || again.Equipment[0] != "scale mail" {
		t.Fatalf("fresh catalog changed: %+v, %v", again, err)
	}
}

func TestLoadDefaultRejectsBadJobArtifact(t *testing.T) {
	var original JobArtifact
	if err := json.Unmarshal(defaultJobsJSON, &original); err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		name   string
		mutate func(*JobArtifact)
	}{
		{"wrong revision", func(a *JobArtifact) { a.SourceRevision = "wrong" }},
		{"wrong tag", func(a *JobArtifact) { a.TagMajorVersion = 35 }},
		{"wrong schema", func(a *JobArtifact) { a.SchemaVersion = 2 }},
		{"duplicate", func(a *JobArtifact) { a.Jobs = append(a.Jobs, a.Jobs[0]) }},
		{"missing", func(a *JobArtifact) { a.Jobs = a.Jobs[1:] }},
		{"unknown species", func(a *JobArtifact) { a.Jobs[0].RecommendedSpecies = []string{"SP_MISSING"} }},
		{"bad hash", func(a *JobArtifact) { a.SourceFiles[0].SHA256 = "zzz" }},
		{"mismatched shared hash", func(a *JobArtifact) {
			for i := range a.SourceFiles {
				if a.SourceFiles[i].Path == "crawl-ref/source/species-type.h" {
					a.SourceFiles[i].SHA256 = strings.Repeat("a", 64)
					break
				}
			}
		}},
		{"unsorted hashes", func(a *JobArtifact) { a.SourceFiles[0], a.SourceFiles[1] = a.SourceFiles[1], a.SourceFiles[0] }},
		{"wrong source path", func(a *JobArtifact) { a.Jobs[0].SourcePath = "not-a-source-file" }},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			artifact := original
			artifact.Jobs = append([]JobDef(nil), original.Jobs...)
			artifact.SourceFiles = append([]JobSourceFile(nil), original.SourceFiles...)
			tc.mutate(&artifact)
			data, err := json.Marshal(artifact)
			if err != nil {
				t.Fatal(err)
			}
			if _, err := loadDefault(defaultSpeciesJSON, data, defaultStartingGearJSON); err == nil {
				t.Fatal("invalid job artifact accepted")
			}
		})
	}
	if _, err := loadDefault(defaultSpeciesJSON, []byte(`{"jobs":`), defaultStartingGearJSON); err == nil || !strings.Contains(err.Error(), "decode") {
		t.Fatalf("malformed job artifact error = %v", err)
	}
}

func TestLoadDefaultRejectsBadSpeciesJobReference(t *testing.T) {
	var artifact SpeciesArtifact
	if err := json.Unmarshal(defaultSpeciesJSON, &artifact); err != nil {
		t.Fatal(err)
	}
	for i := range artifact.Species {
		if artifact.Species[i].ID == "SP_HUMAN" {
			artifact.Species[i].RecommendedJobs = []string{"JOB_MISSING"}
			break
		}
	}
	data, err := json.Marshal(artifact)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := loadDefault(data, defaultJobsJSON, defaultStartingGearJSON); err == nil {
		t.Fatal("unknown recommended job accepted")
	}
}
