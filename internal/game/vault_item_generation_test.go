package game

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/vault"
)

// Read the saved wallet history rather than deriving Gozag's fee from the
// player's balance; an unseen generated pile still counts before pickup.
func generatedVaultGold(t *testing.T, game *Game) int64 {
	t.Helper()

	store := game.scripts.Components()["character.wallet"]
	state, found := store.Get(game.player)

	if !found {
		t.Fatal("generated game has no wallet")
	}

	value, err := state.Get("generated_gold")

	if err != nil {
		t.Fatal(err)
	}

	return value.(int64)
}

// Read the live book that the vault generator actually materialized. The
// names are saved ECS values, so restoring the game must retain both strings.
func generatedVaultBookNames(t *testing.T, game *Game) (string, string) {
	t.Helper()

	for _, entity := range game.world.Entities() {
		item, found := game.stores.Items.Get(entity)

		if !found || item.KindID != "BOOK_RANDART_THEME" {
			continue
		}

		artefacts := game.scripts.Components()["item.artefact"]
		state, found := artefacts.Get(entity)

		if !found {
			t.Fatal("generated random book has no artefact state")
		}

		title, err := state.Get("name")

		if err != nil {
			t.Fatal(err)
		}

		appearance, err := state.Get("appearance")

		if err != nil {
			t.Fatal(err)
		}

		return title.(string), appearance.(string)
	}

	t.Fatal("arrival vault did not generate its themed book")

	return "", ""
}

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

	if got := generatedVaultGold(t, game); got != 17 {
		t.Fatalf("generated gold history = %d, want 17", got)
	}

	title, appearance := generatedVaultBookNames(t, game)

	if strings.HasPrefix(title, "book ") || strings.Contains(title, "@") {
		t.Fatalf("generated book title = %q", title)
	}

	if !strings.HasSuffix(appearance, " book") ||
		strings.Contains(appearance, "non-descript") ||
		strings.Contains(appearance, "@") {
		t.Fatalf("generated book appearance = %q", appearance)
	}

	loaded, err := RestoreWithRules(game.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if got := generatedVaultGold(t, loaded); got != 17 {
		t.Fatalf("restored generated gold history = %d, want 17", got)
	}

	restoredTitle, restoredAppearance := generatedVaultBookNames(t, loaded)

	if restoredTitle != title || restoredAppearance != appearance {
		t.Fatalf("restored book names = %q / %q, want %q / %q",
			restoredTitle, restoredAppearance, title, appearance)
	}

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
