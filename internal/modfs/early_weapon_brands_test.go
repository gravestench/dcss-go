package modfs_test

import (
	"strings"
	"testing"

	"crawl/internal/content"
	"crawl/internal/modfs"
)

// Every positive-weight early weapon brand must have a Lua effect module.
// The check follows the committed import rather than a handwritten list.
func TestGeneratedEarlyWeaponBrandsHaveLuaEffects(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	for _, weaponID := range []string{
		"WPN_CLUB",
		"WPN_WHIP",
		"WPN_DAGGER",
		"WPN_SHORT_SWORD",
		"WPN_SLING",
	} {
		weapon, err := catalog.Item(weaponID)

		if err != nil {
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
