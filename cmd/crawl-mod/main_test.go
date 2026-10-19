package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/script"
	"github.com/gravestench/akara"
)

func TestScaffoldLoadsThroughRuleset(t *testing.T) {
	root := t.TempDir()
	var output bytes.Buffer

	for _, entry := range []struct {
		kind string
		name string
		path string
	}{
		{
			kind: "monster",
			name: "Moss Wolf",
			path: "content/monsters/moss_wolf.lua",
		},

		{
			kind: "component",
			name: "Moss Count",
			path: "schemas/moss_count.lua",
		},

		{
			kind: "system",
			name: "Moss Growth",
			path: "systems/moss_growth.lua",
		},

		{
			kind: "policy",
			name: "Moss Choice",
			path: "policy/custom/moss_choice.lua",
		},

		{
			kind: "vault",
			name: "Moss Room",
			path: "vaults/arrival/moss_room.des",
		},
	} {
		err := create(options{
			modDir: root,
			kind:   entry.kind,
			name:   entry.name,
		}, &output)

		if err != nil {
			t.Fatal(err)
		}

		if _, err := os.Stat(filepath.Join(root, entry.path)); err != nil {
			t.Fatal(err)
		}
	}

	rules, err := modfs.Load(root)

	if err != nil {
		t.Fatal(err)
	}

	for _, path := range []string{
		"content/monsters/moss_wolf.lua",
		"schemas/moss_count.lua",
		"systems/moss_growth.lua",
		"policy/custom/moss_choice.lua",
		"vaults/arrival/moss_room.des",
	} {
		if _, err := rules.ReadFile(path); err != nil {
			t.Fatal(err)
		}
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := script.NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()
}

func TestScaffoldRejectsUnsafePathsAndOverwrites(t *testing.T) {
	root := t.TempDir()
	var output bytes.Buffer

	for _, name := range []string{
		"../escape",
		"quoted\"name",
		"a/b",
		"",
	} {
		options := options{
			modDir: root,
			kind:   "item",
			name:   name,
		}

		if err := create(options, &output); err == nil {
			t.Fatalf("accepted unsafe name %q", name)
		}
	}

	opts := options{
		modDir: root,
		kind:   "item",
		name:   "safe_item",
	}

	if err := create(opts, &output); err != nil {
		t.Fatal(err)
	}

	err := create(opts, &output)

	if err == nil ||
		!strings.Contains(err.Error(), "overwrite") {
		t.Fatalf("overwrite error = %v", err)
	}

	external := t.TempDir()
	other := filepath.Join(t.TempDir(), "overlay")

	if err := os.MkdirAll(other, 0o755); err != nil {
		t.Fatal(err)
	}

	if err := os.Symlink(external, filepath.Join(other, "content")); err != nil {
		t.Fatal(err)
	}

	escape := options{
		modDir: other,
		kind:   "item",
		name:   "escape",
	}

	if err := create(escape, &output); err == nil {
		t.Fatal("accepted a symlinked content directory")
	}

	linkedRoot := filepath.Join(t.TempDir(), "linked")

	if err := os.Symlink(external, linkedRoot); err != nil {
		t.Fatal(err)
	}

	escape.modDir = linkedRoot

	if err := create(escape, &output); err == nil {
		t.Fatal("accepted a symlinked mod root")
	}
}

func TestVaultHookUsesMatchingName(t *testing.T) {
	root := t.TempDir()
	var output bytes.Buffer

	if err := create(options{
		modDir:   root,
		kind:     "vault",
		name:     "Moss Room",
		withHook: true,
	}, &output); err != nil {
		t.Fatal(err)
	}

	des, err := os.ReadFile(filepath.Join(root, "vaults/arrival/moss_room.des"))

	if err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(string(des), `: vault.run("configure")`) {
		t.Fatal("vault is missing its Lua hook call")
	}

	if _, err := os.Stat(filepath.Join(root, "policy/generation/vaults/arrival/moss_room.lua")); err != nil {
		t.Fatal(err)
	}
}

func TestShopVaultUsesShopPaths(t *testing.T) {
	root := t.TempDir()
	var output bytes.Buffer

	if err := create(options{
		modDir:   root,
		kind:     "vault",
		name:     "Moss Shop",
		family:   "shop",
		withHook: true,
	}, &output); err != nil {
		t.Fatal(err)
	}

	for _, path := range []string{
		"vaults/shop/moss_shop.des",
		"policy/generation/vaults/shop/moss_shop.lua",
	} {
		if _, err := os.Stat(filepath.Join(root, path)); err != nil {
			t.Fatal(err)
		}
	}
}
