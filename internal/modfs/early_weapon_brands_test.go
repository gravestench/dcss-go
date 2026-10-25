package modfs_test

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/script"
	"github.com/gravestench/akara"
)

// Every positive-weight early weapon brand in the effective Lua content
// needs an effect module; an added or overridden item is checked as loaded.
func TestEarlyWeaponBrandsHaveLuaEffects(t *testing.T) {
	rules, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := script.NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	for _, weaponID := range []string{
		"WPN_CLUB",
		"WPN_WHIP",
		"WPN_DAGGER",
		"WPN_SHORT_SWORD",
		"WPN_SLING",
	} {
		definition, err := runtime.Definition("items", weaponID)

		if err != nil {
			t.Fatal(err)
		}

		encoded, err := json.Marshal(definition)

		if err != nil {
			t.Fatal(err)
		}

		var weapon struct {
			Weapon struct {
				BrandWeights []struct {
					BrandID string `json:"brand_id"`
					Weight  int    `json:"weight"`
				} `json:"brand_weights"`
			} `json:"weapon"`
		}

		if err := json.Unmarshal(encoded, &weapon); err != nil {
			t.Fatal(err)
		}

		for _, weight := range weapon.Weapon.BrandWeights {
			if weight.Weight <= 0 {
				continue
			}

			name := strings.ToLower(strings.TrimPrefix(weight.BrandID, "SPWPN_"))
			path := "policy/combat/brands/" + name + ".lua"

			if _, err := rules.ReadFile(path); err != nil {
				t.Errorf("%s can generate %s without %s: %v",
					weaponID, weight.BrandID, path, err)
			}
		}
	}
}
