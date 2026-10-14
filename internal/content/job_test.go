package content

import (
	"reflect"
	"testing"
)

func testJob(id, abbreviation string) JobDef {
	return JobDef{
		ID:           id,
		SourcePath:   "crawl-ref/source/job-data.h",
		Abbreviation: abbreviation,
		Name:         "Fighter",

		Strength:     8,
		Intelligence: 0,
		Dexterity:    4,

		RecommendedSpecies: []string{"SP_HUMAN"},
		Spells:             []string{"SPELL_SHOCK"},
		Equipment:          []string{"scale mail", "buckler"},
		WeaponChoice:       "WCHOICE_GOOD",

		Skills: []JobSkillGrant{
			{
				ID:    "SK_FIGHTING",
				Level: 3,
			},

			{
				ID:    "SK_WEAPON",
				Level: 2,
			},
		},
		Selectable: true,
	}
}

func TestJobCatalogCopiesAndSorts(t *testing.T) {
	first := testJob("JOB_Z", "Zz")
	second := testJob("JOB_A", "Aa")
	catalog := Catalog{
		jobs: map[string]JobDef{
			first.ID:  first,
			second.ID: second,
		},
	}

	ids := catalog.JobIDs()

	if !reflect.DeepEqual(ids, []string{"JOB_A", "JOB_Z"}) {
		t.Fatalf("job IDs = %v", ids)
	}

	ids[0] = "changed"

	returned, err := catalog.Job("JOB_Z")

	if err != nil {
		t.Fatal(err)
	}

	returned.RecommendedSpecies[0] = "SP_OTHER"
	returned.Spells[0] = "SPELL_OTHER"
	returned.Equipment[0] = "changed"

	returned.Skills[0].Level = 27

	again, err := catalog.Job("JOB_Z")

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(again, first) {
		t.Fatalf("catalog job mutated through caller: %+v", again)
	}

	if _, err := catalog.Job("JOB_UNKNOWN"); err == nil {
		t.Fatal("unknown job ID accepted")
	}

	if _, err := catalog.Job("JOB_A"); err != nil {
		t.Fatalf("mutating ID list affected catalog: %v", err)
	}
}

func TestJobArtifactRejectsInvalidRecord(t *testing.T) {
	valid := testJob("JOB_FIGHTER", "Fi")

	for _, tc := range []struct {
		name string
		jobs []JobDef
	}{
		{
			name: "duplicate ID",
			jobs: []JobDef{valid, valid},
		},

		{
			name: "duplicate abbreviation",
			jobs: []JobDef{valid, testJob("JOB_OTHER", "Fi")},
		},

		{
			name: "empty name",
			jobs: []JobDef{
				func() JobDef {
					job := valid

					job.Name = ""

					return job
				}(),
			},
		},

		{
			name: "invalid weapon choice",
			jobs: []JobDef{
				func() JobDef {
					job := valid

					job.WeaponChoice = "WCHOICE_UNKNOWN"

					return job
				}(),
			},
		},

		{
			name: "selectable without recommendations",
			jobs: []JobDef{
				func() JobDef {
					job := valid

					job.RecommendedSpecies = nil

					return job
				}(),
			},
		},

		{
			name: "removed with recommendations",
			jobs: []JobDef{
				func() JobDef {
					job := valid

					job.Selectable = false

					return job
				}(),
			},
		},

		{
			name: "negative skill",
			jobs: []JobDef{
				func() JobDef {
					j := valid

					j.Skills = []JobSkillGrant{
						{
							ID:    "SK_FIGHTING",
							Level: -1,
						},
					}

					return j
				}(),
			},
		},

		{
			name: "skill above cap",
			jobs: []JobDef{
				func() JobDef {
					j := valid

					j.Skills = []JobSkillGrant{
						{
							ID:    "SK_FIGHTING",
							Level: 28,
						},
					}

					return j
				}(),
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			artifact := JobArtifact{
				SchemaVersion:   1,
				SourceRevision:  sourceRevision,
				TagMajorVersion: 34,
				Jobs:            tc.jobs,
			}

			if err := artifact.Validate(); err == nil {
				t.Fatal("invalid job artifact accepted")
			}
		})
	}

	if err := (JobArtifact{
		SchemaVersion:   1,
		SourceRevision:  sourceRevision,
		TagMajorVersion: 34,
		Jobs:            []JobDef{valid},
	}).Validate(); err != nil {
		t.Fatalf("valid job rejected: %v", err)
	}
}
