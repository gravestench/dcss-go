package script

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

type ownedGear struct {
	Primary   *content.MonsterWeaponSpec `json:"primary"`
	Secondary *content.MonsterWeaponSpec `json:"secondary"`
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

	raw, err := luaDefinitionValue(
		runtime.definitions["monsters"][id], make(map[*lua.LTable]bool))

	if err != nil {
		t.Fatal(err)
	}

	data, err := json.Marshal(raw)

	if err != nil {
		t.Fatal(err)
	}

	var monster ownedMonster

	if err := json.Unmarshal(data, &monster); err != nil {
		t.Fatal(err)
	}

	return monster.WeaponGear
}

func withoutGearProvenance(spec content.MonsterWeaponSpec) content.MonsterWeaponSpec {
	spec.MonsterID = ""
	spec.SourceLine = 0
	spec.SpecLine = 0
	spec.WeaponListLine = 0
	spec.BrandListLine = 0

	return spec
}

func TestBundledMonsterGearMatchesPinnedImport(t *testing.T) {
	data, err := os.ReadFile("../content/generated/monster-weapons.json")

	if err != nil {
		t.Fatal(err)
	}

	var artifact content.MonsterWeaponArtifact

	if err := json.Unmarshal(data, &artifact); err != nil {
		t.Fatal(err)
	}

	primaryByID := make(map[string]content.MonsterWeaponSpec)
	secondaryByID := make(map[string]content.MonsterWeaponSpec)

	for _, spec := range artifact.Primary {
		primaryByID[spec.MonsterID] = spec
	}

	for _, spec := range artifact.Secondary {
		secondaryByID[spec.MonsterID] = spec
	}

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
		owned := registeredMonsterGear(t, runtime, id)

		for _, slot := range []struct {
			name string
			rows map[string]content.MonsterWeaponSpec
		}{
			{
				name: "primary",
				rows: primaryByID,
			},

			{
				name: "secondary",
				rows: secondaryByID,
			},
		} {
			pinned, found := slot.rows[id]
			var actual *content.MonsterWeaponSpec

			if owned != nil {
				if slot.name == "secondary" {
					actual = owned.Secondary
				} else {
					actual = owned.Primary
				}
			}

			if found != (actual != nil) {
				t.Fatalf("%s %s gear presence differs", id, slot.name)
			}

			if !found {
				continue
			}

			expected := withoutGearProvenance(pinned)

			if !reflect.DeepEqual(*actual, expected) {
				t.Fatalf("%s %s gear differs: actual=%#v expected=%#v",
					id, slot.name, *actual, expected)
			}

			if slot.name == "secondary" {
				secondaryCount++
			} else {
				primaryCount++
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
