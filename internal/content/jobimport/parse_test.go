package jobimport

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

const jobFixture = `static const map<job_type, job_def> job_data =
{
{ JOB_FIGHTER, {
    "Fi", "Fighter", 8, -1, 4,
    { SP_HUMAN, SP_MINOTAUR, },
    { SPELL_SHOCK, SPELL_BLINK, },
    { "scale mail", "wand of flame charges:15, q:2", },
    WCHOICE_GOOD,
    { { SK_FIGHTING, 3 }, { SK_WEAPON, 2 }, },
} },
#if TAG_MAJOR_VERSION == 34
{ JOB_PRIEST, {
    "Pr", "Priest", 0, 0, 0,
    { }, { }, { }, WCHOICE_NONE, { },
} },
#endif
};`

func TestParseJobDataPreservesAllFieldsAndOrder(t *testing.T) {
	jobs, err := parseJobData("job-data.h", []byte(jobFixture))

	if err != nil {
		t.Fatal(err)
	}

	want := []content.JobDef{
		{
			ID:                 "JOB_FIGHTER",
			SourcePath:         "job-data.h",
			Abbreviation:       "Fi",
			Name:               "Fighter",
			Strength:           8,
			Intelligence:       -1,
			Dexterity:          4,
			RecommendedSpecies: []string{"SP_HUMAN", "SP_MINOTAUR"},
			Spells:             []string{"SPELL_SHOCK", "SPELL_BLINK"},
			Equipment:          []string{"scale mail", "wand of flame charges:15, q:2"},
			WeaponChoice:       "WCHOICE_GOOD",
			Skills: []content.JobSkillGrant{
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
		},
		{
			ID:           "JOB_PRIEST",
			SourcePath:   "job-data.h",
			Abbreviation: "Pr",
			Name:         "Priest",
			WeaponChoice: "WCHOICE_NONE",
		},
	}

	if !reflect.DeepEqual(jobs, want) {
		t.Fatalf("parsed jobs = %#v, want %#v", jobs, want)
	}
}

func TestParseJobDataRejectsMalformedDefinitions(t *testing.T) {
	for _, tc := range []struct {
		name        string
		old         string
		replacement string
		want        string
	}{
		{
			name:        "duplicate ID",
			old:         "JOB_PRIEST",
			replacement: "JOB_FIGHTER",
			want:        "duplicate",
		},
		{
			name:        "missing field",
			old:         "WCHOICE_GOOD,",
			replacement: "",
			want:        "JOB_FIGHTER",
		},
		{
			name:        "unknown token",
			old:         "WCHOICE_GOOD",
			replacement: "WCHOICE_MISSING",
			want:        "weapon",
		},
		{
			name:        "malformed string",
			old:         `"Fi", "Fighter"`,
			replacement: `"Fi, "Fighter"`,
			want:        "job-data.h",
		},
		{
			name:        "unsupported conditional",
			old:         "#if TAG_MAJOR_VERSION == 34",
			replacement: "#if FEATURE_X",
			want:        "FEATURE_X",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			input := strings.Replace(jobFixture, tc.old, tc.replacement, 1)
			_, err := parseJobData("job-data.h", []byte(input))

			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("want error containing %q, got %v", tc.want, err)
			}
		})
	}
}
