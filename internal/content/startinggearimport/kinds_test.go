package startinggearimport

import (
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func TestResolveKindsFromCommittedCatalog(t *testing.T) {
	catalog, err := content.LoadItemsForImport()

	if err != nil {
		t.Fatal(err)
	}

	names := []string{
		"scale mail",
		"flail",
		"dart",
		"potion of might",
		"scroll of magic mapping",
		"wand of charming",
		"piece from Xom's chessboard",
	}
	resolved, err := resolveKinds(catalog, names)

	if err != nil {
		t.Fatal(err)
	}

	for name, want := range map[string]string{
		"scale mail":                  "ARM_SCALE_MAIL",
		"flail":                       "WPN_FLAIL",
		"dart":                        "MI_DART",
		"potion of might":             "POT_MIGHT",
		"scroll of magic mapping":     "SCR_MAGIC_MAPPING",
		"wand of charming":            "WAND_CHARMING",
		"piece from Xom's chessboard": "MISC_XOMS_CHESSBOARD",
	} {
		if resolved[name].ID != want {
			t.Errorf("%q resolved to %s, want %s", name, resolved[name].ID, want)
		}
	}

	if _, err := resolveKinds(catalog, []string{"unknown item"}); err == nil ||
		!strings.Contains(err.Error(), "unknown item") {
		t.Fatalf("unknown name accepted: %v", err)
	}

	if _, err := resolveKinds(catalog, []string{"removed deck"}); err == nil ||
		!strings.Contains(err.Error(), "ambiguous") {
		t.Fatalf("ambiguous legacy name accepted: %v", err)
	}
}
