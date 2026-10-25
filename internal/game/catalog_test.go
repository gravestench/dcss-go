package game

import (
	"encoding/json"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/script"
	"github.com/gravestench/akara"
)

// These narrow views let behavior tests assert on the same Lua definitions
// that the game loads. They do not form a second content catalog.
type testMonster struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Glyph        rune   `json:"glyph"`
	Speed        int    `json:"speed"`
	HD           int    `json:"hd"`
	AverageHP10x int    `json:"average_hp_10x"`
	SpellbookID  string `json:"spellbook_id"`
	LeavesCorpse bool   `json:"leaves_corpse"`
	Attacks      []struct {
		Damage int `json:"damage"`
	} `json:"attacks"`
}

type testItem struct {
	Weapon struct {
		BrandWeights []struct {
			BrandID string `json:"brand_id"`
			Weight  int    `json:"weight"`
		} `json:"brand_weights"`
	} `json:"weapon"`
}

type testSpellSlot struct {
	SpellID string `json:"spell_id"`
}

type testCatalogView struct {
	runtime *script.Runtime
}

func testCatalog(t *testing.T) testCatalogView {
	t.Helper()

	rules, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	runtime, err := script.NewCatalog(world, rules)

	if err != nil {
		world.Close()
		t.Fatal(err)
	}

	t.Cleanup(func() {
		runtime.Close()
		world.Close()
	})

	return testCatalogView{runtime: runtime}
}

func (c testCatalogView) decode(
	category string,
	id string,
	result any,
) error {
	definition, err := c.runtime.Definition(category, id)

	if err != nil {
		return err
	}

	encoded, err := json.Marshal(definition)

	if err != nil {
		return err
	}

	return json.Unmarshal(encoded, result)
}

func (c testCatalogView) Monster(id string) (testMonster, error) {
	var monster testMonster
	err := c.decode("monsters", id, &monster)

	return monster, err
}

func (c testCatalogView) Item(id string) (testItem, error) {
	var item testItem
	err := c.decode("items", id, &item)

	return item, err
}

func (c testCatalogView) MonsterSpellbook(id string) ([]testSpellSlot, error) {
	var book struct {
		Slots []testSpellSlot `json:"slots"`
	}

	err := c.decode("monster_spellbooks", id, &book)

	return book.Slots, err
}
