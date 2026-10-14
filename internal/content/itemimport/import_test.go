package itemimport

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func artifactPairFixture(t *testing.T) ([]byte, []byte) {
	t.Helper()
	files := []content.JobSourceFile{{
		Path:   "crawl-ref/source/item-prop-enum.h",
		SHA256: strings.Repeat("a", 64),
	}}
	identities := []content.ItemIdentity{
		{
			ID:           "WPN_MACE",
			ClassID:      "OBJ_WEAPONS",
			ClassValue:   0,
			SubtypeValue: 3,
			SourcePath:   files[0].Path,
			SourceLine:   10,
		},
		{
			ID:           "POT_CURING",
			ClassID:      "OBJ_POTIONS",
			ClassValue:   7,
			SubtypeValue: 0,
			SourcePath:   files[0].Path,
			SourceLine:   20,
		},
	}
	items := []content.ItemDef{
		{
			ID:           "WPN_MACE",
			Name:         "mace",
			Glyph:        ')',
			Class:        "OBJ_WEAPONS",
			ClassValue:   0,
			SubtypeValue: 3,
			Slot:         "weapon",
			WeaponSkill:  "SK_MACES_FLAILS",
			Naming: content.ItemName{
				Text:       "mace",
				Kind:       "static",
				SourcePath: files[0].Path,
				SourceLine: 10,
			},
			Evidence: content.ItemEvidence{
				PropertySource: files[0].Path,
				PropertyLine:   10,
			},
			Weapon: &content.WeaponProperties{
				Damage:      8,
				Hit:         3,
				Speed:       14,
				SkillID:     "SK_MACES_FLAILS",
				Min2HSizeID: "SIZE_LITTLE",
				Min1HSizeID: "SIZE_LITTLE",
				AmmoID:      "MI_NONE",
				DamageFlags: []string{"DAMV_CRUSHING"},
				BrandWeights: []content.ItemBrandWeight{{
					BrandID: "SPWPN_NORMAL",
					Weight:  58,
				}},
			},
		},
		{
			ID:           "POT_CURING",
			Name:         "potion of curing",
			Glyph:        '!',
			Class:        "OBJ_POTIONS",
			ClassValue:   7,
			SubtypeValue: 0,
			Stackable:    true,
			Naming: content.ItemName{
				Text:       "potion of curing",
				Kind:       "static",
				SourcePath: files[0].Path,
				SourceLine: 20,
			},
		},
	}
	vocab := content.ItemVocabulary{
		Slots:       []string{"EQ_BODY_ARMOUR"},
		Skills:      []string{"SK_MACES_FLAILS"},
		Sizes:       []string{"SIZE_LITTLE"},
		Ammo:        []string{"MI_NONE"},
		DamageFlags: []string{"DAMV_CRUSHING"},
		Brands:      []string{"SPWPN_NORMAL"},
		ArmourFlags: []string{"ARMF_NO_FLAGS"},
	}
	itemBytes, err := json.Marshal(items)
	if err != nil {
		t.Fatal(err)
	}
	hash := sha256.Sum256(itemBytes)
	manifest := content.ItemIdentityManifest{
		SchemaVersion:     1,
		SourceRevision:    "revision",
		TagMajorVersion:   34,
		SourceFiles:       files,
		Identities:        identities,
		Vocabulary:        vocab,
		DefinitionsSHA256: hex.EncodeToString(hash[:]),
	}
	artifact := content.ItemArtifact{
		SchemaVersion:   1,
		SourceRevision:  "revision",
		TagMajorVersion: 34,
		SourceFiles:     files,
		Items:           items,
	}
	if err := artifact.Validate(manifest); err != nil {
		t.Fatal(err)
	}
	itemsJSON, _ := json.Marshal(artifact)
	identitiesJSON, _ := json.Marshal(manifest)
	return append(itemsJSON, '\n'), append(identitiesJSON, '\n')
}

func TestItemImportPair(t *testing.T) {
	itemsJSON, identitiesJSON := artifactPairFixture(t)
	var artifact content.ItemArtifact
	var manifest content.ItemIdentityManifest
	if err := json.Unmarshal(itemsJSON, &artifact); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(identitiesJSON, &manifest); err != nil {
		t.Fatal(err)
	}
	for _, test := range []struct {
		name   string
		change func(*content.ItemArtifact, *content.ItemIdentityManifest)
	}{
		{"omitted row", func(a *content.ItemArtifact, _ *content.ItemIdentityManifest) { a.Items = a.Items[:1] }},
		{"same-count ID substitution", func(a *content.ItemArtifact, _ *content.ItemIdentityManifest) { a.Items[1].ID = "POT_MAGIC" }},
		{"wrong numeric subtype", func(a *content.ItemArtifact, _ *content.ItemIdentityManifest) { a.Items[1].SubtypeValue = 99 }},
		{"swapped removal membership", func(a *content.ItemArtifact, _ *content.ItemIdentityManifest) { a.Items[1].ExplicitlyRemoved = true }},
		{"unknown property symbol", func(a *content.ItemArtifact, _ *content.ItemIdentityManifest) {
			a.Items[0].Weapon.SkillID = "SK_NOT_REAL"
		}},
		{"source hash mismatch", func(a *content.ItemArtifact, _ *content.ItemIdentityManifest) {
			a.SourceFiles[0].SHA256 = strings.Repeat("b", 64)
		}},
	} {
		t.Run(test.name, func(t *testing.T) {
			var a content.ItemArtifact
			var m content.ItemIdentityManifest
			_ = json.Unmarshal(itemsJSON, &a)
			_ = json.Unmarshal(identitiesJSON, &m)
			test.change(&a, &m)
			if err := a.Validate(m); err == nil {
				t.Fatal("corrupt item artifact pair was accepted")
			}
		})
	}
	// A manifest with an updated digest still cannot declare a live enum item
	// while silently omitting its definition.
	missing := artifact
	missing.Items = missing.Items[:1]
	encoded, err := json.Marshal(missing.Items)
	if err != nil {
		t.Fatal(err)
	}
	updated := manifest
	digest := sha256.Sum256(encoded)
	updated.DefinitionsSHA256 = hex.EncodeToString(digest[:])
	if err := missing.Validate(updated); err == nil {
		t.Fatal("missing live definition passed with recomputed manifest digest")
	}
	identities := []content.ItemIdentity{{
		ID:           "WPN_MACE",
		ClassID:      "OBJ_WEAPONS",
		ClassValue:   0,
		SubtypeValue: 3,
	}, {
		ID:                "POT_OLD",
		ClassID:           "OBJ_POTIONS",
		ClassValue:        7,
		SubtypeValue:      1,
		ExplicitlyRemoved: true,
	}}
	rows := map[itemKey]itemPropertyRow{{"OBJ_WEAPONS", "WPN_MACE"}: {
		Name:   "mace",
		Line:   11,
		Weapon: &content.WeaponProperties{SkillID: "SK_MACES_FLAILS"},
	}}
	names := map[itemKey]content.ItemName{}
	glyphs := map[itemKey]rune{
		{"OBJ_WEAPONS", "WPN_MACE"}: ')',
		{"OBJ_POTIONS", "POT_OLD"}:  '!',
	}
	joined, err := joinItemViews(identities, rows, names, glyphs)
	if err != nil || len(joined) != 1 || joined[0].ID != "WPN_MACE" {
		t.Fatalf("wrong source join: items=%+v err=%v", joined, err)
	}
	rows[itemKey{
		"OBJ_WEAPONS",
		"WPN_EXTRA",
	}] = rows[itemKey{
		"OBJ_WEAPONS",
		"WPN_MACE",
	}]
	if _, err := joinItemViews(identities, rows, names, glyphs); err == nil {
		t.Fatal("property row without enum identity accepted")
	}
	food, err := joinItemViews(
		[]content.ItemIdentity{{
			ID:           "FOOD_RATION",
			ClassID:      "OBJ_FOOD",
			ClassValue:   4,
			SubtypeValue: 0,
		}},
		map[itemKey]itemPropertyRow{{"OBJ_FOOD", "FOOD_RATION"}: {
			Name: "buggy ration",
			Line: 40,
			Food: &content.FoodProperties{NormalNutrition: 3400},
		}},
		map[itemKey]content.ItemName{{"OBJ_FOOD", "FOOD_RATION"}: {
			Text:       "removed food",
			Kind:       "static",
			SourcePath: "crawl-ref/source/item-name.cc",
			SourceLine: 20,
		}},
		map[itemKey]rune{{"OBJ_FOOD", "FOOD_RATION"}: '%'},
	)
	if err != nil || len(food) != 1 || food[0].Name != "removed food" || food[0].PropertyName != "buggy ration" {
		t.Fatalf("food names lost: %+v, %v", food, err)
	}
}

func TestItemImportWrite(t *testing.T) {
	itemsJSON, identitiesJSON := artifactPairFixture(t)
	dir := t.TempDir()
	out := filepath.Join(dir, "items.json")
	manifestPath := filepath.Join(dir, "item-identities.json")
	generate := func() ([]byte, []byte, error) { return itemsJSON, identitiesJSON, nil }
	if err := writePair(out, false, generate); err != nil {
		t.Fatal(err)
	}
	if err := writePair(out, true, generate); err != nil {
		t.Fatal(err)
	}
	beforeItems, _ := os.ReadFile(out)
	beforeManifest, _ := os.ReadFile(manifestPath)
	if string(beforeItems) != string(itemsJSON) || string(beforeManifest) != string(identitiesJSON) {
		t.Fatal("written artifact pair differs from generated bytes")
	}
	if err := os.WriteFile(manifestPath, []byte("stale"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := writePair(out, true, generate); err == nil {
		t.Fatal("stale manifest passed -check")
	}
	if got, _ := os.ReadFile(out); string(got) != string(beforeItems) {
		t.Fatal("-check modified items artifact")
	}
	if got, _ := os.ReadFile(manifestPath); string(got) != "stale" {
		t.Fatal("-check modified stale manifest")
	}
	if err := writePair(out, false, func() ([]byte, []byte, error) { return nil, nil, os.ErrInvalid }); err == nil {
		t.Fatal("generation failure was ignored")
	}
	if got, _ := os.ReadFile(out); string(got) != string(beforeItems) {
		t.Fatal("generation failure replaced items artifact")
	}
	if got, _ := os.ReadFile(manifestPath); string(got) != "stale" {
		t.Fatal("generation failure replaced manifest")
	}
}
