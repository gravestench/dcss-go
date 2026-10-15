package modfs

import (
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"strings"
	"testing"
)

func TestBundledRulesetHasStableIdentity(t *testing.T) {
	first, err := Load("")

	if err != nil {
		t.Fatal(err)
	}

	second, err := Load("")

	if err != nil {
		t.Fatal(err)
	}

	if !first.Vanilla() {
		t.Fatal("bundled ruleset is not vanilla")
	}

	if first.Hash() != second.Hash() || first.Hash() != first.BundledHash() {
		t.Fatalf("bundled ruleset identity changed: %+v", first)
	}

	paths := first.Paths()

	if len(paths) < 76 ||
		!slices.IsSorted(paths) ||
		!slices.Contains(paths, "init.lua") ||
		!slices.Contains(paths, "policy/character_choice.lua") {
		t.Fatalf("unexpected bundled Lua tree: %d paths", len(paths))
	}

	bytes, err := first.ReadFile("init.lua")

	if err != nil {
		t.Fatal(err)
	}

	bytes[0] = 'x'

	again, err := first.ReadFile("init.lua")

	if err != nil {
		t.Fatal(err)
	}

	if again[0] == 'x' {
		t.Fatalf("ruleset bytes were mutable: %q, %v", again, err)
	}
}

func TestOverlayIdentityAndOrder(t *testing.T) {
	bundled, err := Load("")

	if err != nil {
		t.Fatal(err)
	}

	overlay := t.TempDir()
	init, err := bundled.ReadFile("init.lua")

	if err != nil {
		t.Fatal(err)
	}

	writeTestFile(t, overlay, "init.lua", init)

	same, err := Load(overlay)

	if err != nil {
		t.Fatal(err)
	}

	if !same.Vanilla() {
		t.Fatal("byte-identical overlay is not vanilla")
	}

	if same.Hash() != bundled.Hash() || len(same.Changes()) != 0 {
		t.Fatalf("byte-identical overlay changed identity: %+v", same)
	}

	copyLuaFixture(t, overlay, "systems/z.lua")
	copyLuaFixture(t, overlay, "systems/a.lua")
	copyLuaFixture(t, overlay, "init.lua")

	modded, err := Load(overlay)

	if err != nil {
		t.Fatal(err)
	}

	if modded.Vanilla() || modded.Hash() == bundled.Hash() {
		t.Fatal("changed overlay reported vanilla")
	}

	if !slices.IsSorted(modded.Paths()) ||
		len(modded.Paths()) != len(bundled.Paths())+2 {
		t.Fatalf("unsorted paths: %v", modded.Paths())
	}

	if !reflect.DeepEqual(modded.Changes(), []string{
		"init.lua",
		"systems/a.lua",
		"systems/z.lua",
	}) {
		t.Fatalf("unexpected changed paths: %v", modded.Changes())
	}
}

func TestSingleContentFileParticipatesInRulesetIdentity(t *testing.T) {
	bundled, err := Load("")

	if err != nil {
		t.Fatal(err)
	}

	overlay := t.TempDir()
	path := "content/monsters/0001_mons_abomination_large.lua"
	data, err := bundled.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	writeTestFile(t, overlay, path, data)

	unchanged, err := Load(overlay)

	if err != nil {
		t.Fatal(err)
	}

	if !unchanged.Vanilla() || unchanged.Hash() != bundled.Hash() {
		t.Fatal("identical content override changed vanilla identity")
	}

	newPath := "content/monsters/zz_mod_moss.lua"
	writeTestFile(t, overlay, newPath, []byte("return {}\n"))

	added, err := Load(overlay)

	if err != nil {
		t.Fatal(err)
	}

	if added.Vanilla() ||
		added.Hash() == bundled.Hash() ||
		!reflect.DeepEqual(added.Changes(), []string{newPath}) {
		t.Fatalf("added content file has wrong identity: %+v", added)
	}
}

func TestOverlayRejectsInvalidPathsAndSymlinks(t *testing.T) {
	for _, name := range []string{
		"README.txt",
		"Init.lua",
	} {
		t.Run(name, func(t *testing.T) {
			overlay := t.TempDir()
			copyLuaFixtureAs(t, overlay, "init.lua", name)

			if _, err := Load(overlay); err == nil {
				t.Fatal("invalid overlay path accepted")
			}
		})
	}

	overlay := t.TempDir()
	outside := filepath.Join(t.TempDir(), "outside.lua")

	data, err := os.ReadFile("testdata/identity-mod/init.lua")

	if err != nil {
		t.Fatal(err)
	}

	if err := os.WriteFile(outside, data, 0o600); err != nil {
		t.Fatal(err)
	}

	if err := os.Symlink(outside, filepath.Join(overlay, "escape.lua")); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}

	_, err = Load(overlay)

	if err == nil {
		t.Fatal("symlink escape accepted")
	}

	if !strings.Contains(err.Error(), "symlink") {
		t.Fatalf("symlink escape accepted or unclear error: %v", err)
	}

	if _, err := Load(filepath.Join(overlay, "missing")); !errors.Is(err, fs.ErrNotExist) {
		t.Fatalf("missing overlay: %v", err)
	}
}

func TestReadFileRejectsTraversal(t *testing.T) {
	rules, err := Load("")

	if err != nil {
		t.Fatal(err)
	}

	for _, name := range []string{
		"../init.lua",
		"/init.lua",
		".",
		"init.json",
	} {
		if _, err := rules.ReadFile(name); err == nil {
			t.Errorf("accepted path %q", name)
		}
	}
}

func copyLuaFixture(t *testing.T, root, name string) {
	t.Helper()

	copyLuaFixtureAs(t, root, name, name)
}

func copyLuaFixtureAs(t *testing.T, root, source, name string) {
	t.Helper()

	data, err := os.ReadFile(filepath.Join("testdata/identity-mod", source))

	if err != nil {
		t.Fatal(err)
	}

	writeTestFile(t, root, name, data)
}

func writeTestFile(t *testing.T, root, name string, data []byte) {
	t.Helper()

	path := filepath.Join(root, filepath.FromSlash(name))

	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}

	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
}
