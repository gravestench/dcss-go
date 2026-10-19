package game

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/vault"
)

func TestVaultItemGenerationUsesRolledRecords(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-item-generation")

	if err != nil {
		t.Fatal(err)
	}

	game, err := NewDungeonGameWithRules(
		41,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()
	level := game.levels[1]

	if level.VaultID() != "zz_item_generation" {
		t.Fatalf("selected vault = %s", level.VaultID())
	}

	items := 0
	gold := false

	for _, record := range level.VaultRecords() {
		if record.Kind != vault.KindItem {
			continue
		}

		items++

		if record.Pending {
			t.Fatal("generated vault item stayed pending")
		}

		for _, argument := range record.Arguments {
			if argument.Name != "kind_id" {
				continue
			}

			if argument.String == "" || argument.String == "OBJ_RANDOM" {
				t.Fatalf("vault saved unresolved item %s", argument.String)
			}

			if argument.String == "OBJ_GOLD" {
				gold = true
			}
		}
	}

	if items != 3 || !gold {
		t.Fatalf("generated %d vault items, gold=%t", items, gold)
	}

	loaded, err := RestoreWithRules(game.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if loaded.levels[1].VaultID() != level.VaultID() {
		t.Fatal("generated vault identity changed on restore")
	}

	for _, record := range loaded.levels[1].VaultRecords() {
		if record.Kind == vault.KindItem &&
			strings.Contains(record.Identity, "random") &&
			record.Pending {
			t.Fatal("generated item was retried on restore")
		}
	}
}
