package content

import (
	"strings"
	"testing"
)

func TestStartingGearCatalogCopies(t *testing.T) {
	c := scenarioCatalog()
	c.startingGear = map[string][]StartingGrant{
		"JOB_FIGHTER": {{Raw: "scale mail", KindID: "ARM_SCALE_MAIL", Quantity: 1}},
	}
	first, err := c.StartingGrants("JOB_FIGHTER")
	if err != nil {
		t.Fatal(err)
	}
	first[0].KindID = "POT_CURING"
	first = append(first, StartingGrant{KindID: "WPN_FLAIL", Quantity: 1})
	again, err := c.StartingGrants("JOB_FIGHTER")
	if err != nil {
		t.Fatal(err)
	}
	if len(again) != 1 || again[0].KindID != "ARM_SCALE_MAIL" {
		t.Fatalf("catalog grants changed through returned slice: %+v", again)
	}
	if _, err := c.StartingGrants("JOB_UNKNOWN"); err == nil {
		t.Fatal("unknown job gear was accepted")
	}
}

func validStartingGearArtifact() StartingGearArtifact {
	return StartingGearArtifact{
		SchemaVersion: 1, SourceRevision: sourceRevision, TagMajorVersion: 34,
		Kinds: []ItemDef{
			{ID: "POT_CURING", Name: "potion of curing", Glyph: '!', Class: "OBJ_POTIONS", Stackable: true},
			{ID: "WPN_FLAIL", Name: "flail", Glyph: ')', Class: "OBJ_WEAPONS", Slot: "weapon", WeaponSkill: "SK_MACES_FLAILS"},
		},
		Jobs: []JobStartingGear{{JobID: "JOB_FIGHTER", Grants: []StartingGrant{{Raw: "potion of curing", KindID: "POT_CURING", Quantity: 1}}}},
	}
}

func TestStartingGearArtifactValidation(t *testing.T) {
	if err := validStartingGearArtifact().Validate(); err != nil {
		t.Fatalf("valid artifact: %v", err)
	}
	for _, tc := range []struct {
		name, want string
		change     func(*StartingGearArtifact)
	}{
		{"duplicate kind", "duplicate", func(a *StartingGearArtifact) { a.Kinds = append(a.Kinds, a.Kinds[0]) }},
		{"duplicate job", "duplicate", func(a *StartingGearArtifact) { a.Jobs = append(a.Jobs, a.Jobs[0]) }},
		{"empty name", "name", func(a *StartingGearArtifact) { a.Kinds[0].Name = "" }},
		{"potion slot", "slot", func(a *StartingGearArtifact) { a.Kinds[0].Slot = "weapon" }},
		{"weapon without slot", "slot", func(a *StartingGearArtifact) { a.Kinds[1].Slot = "" }},
		{"potion skill", "skill", func(a *StartingGearArtifact) { a.Kinds[0].WeaponSkill = "SK_AXES" }},
		{"zero quantity", "quantity", func(a *StartingGearArtifact) { a.Jobs[0].Grants[0].Quantity = 0 }},
		{"potion charges", "charges", func(a *StartingGearArtifact) { a.Jobs[0].Grants[0].Charges = 3 }},
		{"potion ego", "ego", func(a *StartingGearArtifact) { a.Jobs[0].Grants[0].Ego = "poisoned" }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			a := validStartingGearArtifact()
			tc.change(&a)
			if err := a.Validate(); err == nil || !strings.Contains(strings.ToLower(err.Error()), tc.want) {
				t.Fatalf("want %q error, got %v", tc.want, err)
			}
		})
	}
}
