package script

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
)

type gearChoice struct {
	ID     string `json:"id"`
	Weight int    `json:"weight"`
}

type gearSpec struct {
	Weapons []gearChoice `json:"weapons"`
	Brands  []gearChoice `json:"brands"`
}

type ownedGear struct {
	Primary   *gearSpec `json:"primary"`
	Secondary *gearSpec `json:"secondary"`
}

type ownedMonster struct {
	WeaponGear *ownedGear `json:"weapon_gear"`
}

func registeredMonsterGear(
	t *testing.T,
	runtime *Runtime,
	id string,
) *ownedGear {
	t.Helper()

	definition, err := runtime.Definition("monsters", id)

	if err != nil {
		t.Fatal(err)
	}

	data, err := json.Marshal(definition)

	if err != nil {
		t.Fatal(err)
	}

	var monster ownedMonster

	if err := json.Unmarshal(data, &monster); err != nil {
		t.Fatal(err)
	}

	return monster.WeaponGear
}

func TestBundledMonsterGearUsesEffectiveLuaCatalog(t *testing.T) {
	rules, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	primaryCount := 0
	secondaryCount := 0

	for _, id := range runtime.DefinitionIDs("monsters") {
		gear := registeredMonsterGear(t, runtime, id)

		if gear == nil {
			continue
		}

		for _, entry := range []struct {
			name string
			spec *gearSpec
		}{
			{
				name: "primary",
				spec: gear.Primary,
			},

			{
				name: "secondary",
				spec: gear.Secondary,
			},
		} {
			if entry.spec == nil {
				continue
			}

			if len(entry.spec.Weapons) == 0 {
				t.Fatalf("%s has empty %s gear", id, entry.name)
			}

			for _, choice := range append(
				append([]gearChoice(nil), entry.spec.Weapons...),
				entry.spec.Brands...,
			) {
				if choice.ID == "" || choice.Weight <= 0 {
					t.Fatalf("%s has invalid %s choice: %+v",
						id, entry.name, choice)
				}
			}

			if entry.name == "primary" {
				primaryCount++
			} else {
				secondaryCount++
			}
		}
	}

	if primaryCount != 162 || secondaryCount != 16 {
		t.Fatalf("gear owner counts = %d/%d", primaryCount, secondaryCount)
	}
}

func TestSamePathMonsterGearOverrideChangesDefinition(t *testing.T) {
	const path = "content/monsters/mons_goblin.lua"
	const original = "id = item_ids.WPN_DAGGER,\n                    weight = 1,"
	const replacement = "id = item_ids.WPN_DAGGER,\n                    weight = 9,"

	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	source, err := bundled.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if strings.Count(string(source), original) != 1 {
		t.Fatal("Goblin gear source changed")
	}

	root := t.TempDir()
	file := filepath.Join(root, filepath.FromSlash(path))

	if err := os.MkdirAll(filepath.Dir(file), 0o755); err != nil {
		t.Fatal(err)
	}

	changed := strings.Replace(string(source), original, replacement, 1)

	if err := os.WriteFile(file, []byte(changed), 0o644); err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load(root)

	if err != nil {
		t.Fatal(err)
	}

	if rules.Hash() == bundled.Hash() {
		t.Fatal("gear override did not change ruleset identity")
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	owned := registeredMonsterGear(t, runtime, "MONS_GOBLIN")

	if owned == nil ||
		owned.Primary == nil ||
		owned.Primary.Weapons[0].Weight != 9 {
		t.Fatalf("same-path gear override was ignored: %+v", owned)
	}
}

func TestSamePathMonsterGearHandlerOverrideRuns(t *testing.T) {
	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load("testdata/monster-gear-handler-override")

	if err != nil {
		t.Fatal(err)
	}

	if rules.Hash() == bundled.Hash() {
		t.Fatal("gear handler override did not change ruleset identity")
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	result, err := runtime.Policy("test.monster_gear_override", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["kind_id"] != "WPN_CLUB" {
		t.Fatalf("gear handler override was ignored: %+v", result)
	}
}
