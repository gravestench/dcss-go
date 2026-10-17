package vaultimport

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestShopSourceKeepsDepthChanceAndMap(t *testing.T) {
	body, err := os.ReadFile("testdata/shop_simple.des")

	if err != nil {
		t.Fatal(err)
	}

	files, err := splitSourceFamily(ShopFamily, "shop_simple.des", body, nil)

	if err != nil {
		t.Fatal(err)
	}

	shop := string(files["vaults/shop/test_shop.des"])

	for _, line := range []string{
		"DEPTH: D:4-, Depths",
		"CHANCE: 15% (D)",
		"KFEAT: s = general shop greed:0 count:1 ; potion of curing",
		"MAP\n.s.\nENDMAP",
	} {
		if !strings.Contains(shop, line) {
			t.Fatalf("shop output lost %q: %q", line, shop)
		}
	}
}

func TestPinnedShopMapsAreCommittedIndividually(t *testing.T) {
	paths, err := filepath.Glob("../modfs/builtin/vaults/shop/*.des")

	if err != nil {
		t.Fatal(err)
	}

	if len(paths) != 70 {
		t.Fatalf("committed shop vault count = %d, want 70", len(paths))
	}
}

func TestShopScriptPortRecipesCoverBothSourceFiles(t *testing.T) {
	ports, err := loadPorts("shop_ports")

	if err != nil {
		t.Fatal(err)
	}

	if len(ports) != 21 {
		t.Fatalf("scripted shop vaults = %d, want 21", len(ports))
	}

	serial := ports["serial_shops"]

	if serial.SourceFile != "shops.des" ||
		len(serial.Edits) != 1 ||
		serial.Edits[0].Stage != "post_place" {
		t.Fatalf("serial shop post-place script has no port: %+v", serial)
	}

	alphabet := ports["nicolae_alphabet_shops"]

	if alphabet.SourceFile != "alphashops.des" ||
		len(alphabet.Edits) != 1 {
		t.Fatalf("alphabet shop script has no port: %+v", alphabet)
	}
}
