package game

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

func TestGeneratedShopVaultsMaterializeAndRestore(t *testing.T) {
	found := false
	foundWithoutShop := false
	purchased := false
	checkedCorruption := false

	for seed := uint64(1); seed <= 64; seed++ {
		g, err := NewDungeonGame(seed, "SP_HUMAN", "JOB_FIGHTER",
			"WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatalf("seed %d: %v", seed, err)
		}

		shops := g.scripts.Components()["world.shop"].Entities()

		if len(shops) == 0 {
			foundWithoutShop = true
		}

		for _, level := range g.levels {
			for _, record := range level.vaultRecords {
				if record.Kind != vault.KindFeature &&
					record.Kind != vault.KindSourceFeature {
					continue
				}

				reason := ""

				for _, argument := range record.Arguments {
					if argument.Name == "pending_reason" {
						reason = argument.String
					}
				}

				if record.Pending && reason == "" {
					t.Fatalf("seed %d: pending feature %s has no reason",
						seed, record.Identity)
				}

				if !record.Pending && reason != "" {
					t.Fatalf("seed %d: materialized feature %s kept a pending reason",
						seed, record.Identity)
				}
			}
		}

		for _, entity := range shops {
			value, exists := g.scripts.Components()["world.shop"].Get(entity)

			if !exists {
				t.Fatal("shop query returned a missing component")
			}

			fields, err := value.Snapshot()

			if err != nil {
				t.Fatal(err)
			}

			levelID := int(fields["level_id"].(int64))
			x := int(fields["x"].(int64))
			y := int(fields["y"].(int64))

			if g.levels[levelID].terrain[y][x] != terrain.ShopEntrance {
				t.Fatalf("seed %d: authored shop has no entrance", seed)
			}

			found = true

			if levelID == 1 && !purchased {
				if err := g.levels[1].MoveActor(g.player, x, y); err != nil {
					t.Fatalf("seed %d: move to authored shop: %v", seed, err)
				}

				if _, err := g.scripts.Components()["character.wallet"].Set(
					g.player,
					map[string]any{
						"gold":      int64(100000),
						"purchases": int64(0),
					},
				); err != nil {
					t.Fatal(err)
				}

				shop, err := g.ShopAtPlayer("type")

				if err != nil {
					t.Fatal(err)
				}

				if !shop.Available || len(shop.Items) == 0 {
					t.Fatalf("seed %d: authored shop has no purchasable stock", seed)
				}

				first := shop.Items[0]
				result, err := g.BuyShop(shop.ID, []uint64{first.ID})

				if err != nil {
					t.Fatal(err)
				}

				if result.Spent != first.Price || len(result.Acquired) != 1 {
					t.Fatalf("seed %d: authored purchase = %+v", seed, result)
				}

				purchased = true
			}
		}

		if len(shops) > 0 {
			snapshot := g.Snapshot()
			restored, err := Restore(snapshot)

			if err != nil {
				t.Fatalf("seed %d shop restore: %v", seed, err)
			}

			_ = restored.Close()

			if !checkedCorruption {
				changed := false

				for levelIndex := range snapshot.Levels {
					records := snapshot.Levels[levelIndex].VaultRecords

					for recordIndex := range records {
						record := &records[recordIndex]

						if record.Kind == vault.KindFeature &&
							strings.Contains(record.Identity, " shop") {
							record.Identity = "floor"
							changed = true

							break
						}
					}

					if changed {
						break
					}
				}

				if !changed {
					t.Fatal("authored shop has no source feature record")
				}

				if _, err := Restore(snapshot); err == nil {
					t.Fatal("restored an orphan authored shop entity")
				}

				missing := g.Snapshot()

				for levelIndex := range missing.Levels {
					if missing.Levels[levelIndex].VaultID != "" {
						missing.Levels[levelIndex].VaultID =
							"zz_missing_vault"

						break
					}
				}

				if _, err := Restore(missing); err == nil {
					t.Fatal("restored a missing source vault ID")
				}

				checkedCorruption = true
			}
		}

		_ = g.Close()
	}

	if !found {
		t.Fatal("no authored shop appeared in 64 generated seeds")
	}

	if !foundWithoutShop {
		t.Fatal("all generated seeds had a shop despite conditional vault selection")
	}

	if !purchased {
		t.Fatal("no D:1 authored shop could be purchased in 64 seeds")
	}
}

func TestShopVaultAndHandlerOverlayIdentity(t *testing.T) {
	base, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	overlay := t.TempDir()
	newPath := "vaults/shop/zz_mod_shop.des"
	shopPath := "vaults/shop/shop.des"
	handlerPath := "policy/generation/vaults/shop/serial_shops.lua"

	writeShopVaultOverlay(t, overlay, newPath, []byte(
		"NAME: zz_mod_shop\n"+
			"TAGS: allow_dup extra shop transparent\n"+
			"DEPTH: D:1-\n"+
			"KFEAT: O = general shop count:1 use_all ; potion of curing\n"+
			"MAP\nO\nENDMAP\n"))

	for _, path := range []string{shopPath, handlerPath} {
		source, err := base.ReadFile(path)

		if err != nil {
			t.Fatal(err)
		}

		comment := []byte("\n-- mod overlay\n")

		if strings.HasSuffix(path, ".des") {
			comment = []byte("\n# mod overlay\n")
		}

		source = append(source, comment...)
		writeShopVaultOverlay(t, overlay, path, source)
	}

	rules, err := modfs.Load(overlay)

	if err != nil {
		t.Fatal(err)
	}

	if rules.Hash() == base.Hash() ||
		!reflect.DeepEqual(rules.Changes(), []string{
			handlerPath,
			shopPath,
			newPath,
		}) {
		t.Fatalf("sparse shop overlay was not included in ruleset identity: %v",
			rules.Changes())
	}

	g, err := NewDungeonGameWithRules(31, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	foundAdded := false

	for _, id := range g.scripts.DefinitionIDs("vaults") {
		foundAdded = foundAdded || id == "zz_mod_shop"
	}

	if !foundAdded {
		t.Fatal("mod-added shop vault was not registered")
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if _, err := Restore(g.Snapshot()); err == nil {
		t.Fatal("base ruleset restored a shop-vault overlay save")
	}
}

func writeShopVaultOverlay(
	t *testing.T,
	root string,
	path string,
	content []byte,
) {
	t.Helper()

	target := filepath.Join(root, filepath.FromSlash(path))

	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		t.Fatal(err)
	}

	if err := os.WriteFile(target, content, 0o644); err != nil {
		t.Fatal(err)
	}
}
