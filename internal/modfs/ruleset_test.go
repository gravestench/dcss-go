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
	first, err := Load()

	if err != nil {
		t.Fatal(err)
	}

	second, err := Load()

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
	bundled, err := Load()

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

func TestDESOverlayIdentity(t *testing.T) {
	bundled, err := Load()

	if err != nil {
		t.Fatal(err)
	}

	firstLayer := t.TempDir()
	secondLayer := t.TempDir()
	path := "vaults/arrival/zz_mod_entry.des"
	firstBody := []byte("NAME: zz_mod_entry\nMAP\n@\nENDMAP\n")
	secondBody := []byte("NAME: zz_mod_entry\nMAP\n.@\nENDMAP\n")

	writeTestFile(t, firstLayer, path, firstBody)
	writeTestFile(t, secondLayer, path, secondBody)

	first, err := Load(firstLayer)

	if err != nil {
		t.Fatal(err)
	}

	if first.Vanilla() || first.Hash() == bundled.Hash() {
		t.Fatal("added DES file did not change ruleset identity")
	}

	if !reflect.DeepEqual(first.Changes(), []string{path}) ||
		!slices.Contains(first.Paths(), path) ||
		!slices.IsSorted(first.Paths()) {
		t.Fatalf("DES overlay missing from sorted manifest: %v", first.Paths())
	}

	manifestCount := 0

	for _, entry := range first.Manifest() {
		if entry.Path == path {
			manifestCount++
		}
	}

	if manifestCount != 1 {
		t.Fatalf("DES manifest count = %d, want 1", manifestCount)
	}

	copyLayer := t.TempDir()
	writeTestFile(t, copyLayer, path, firstBody)

	unchanged, err := Load(firstLayer, copyLayer)

	if err != nil {
		t.Fatal(err)
	}

	if unchanged.Hash() != first.Hash() {
		t.Fatal("byte-identical DES replacement changed hash")
	}

	replaced, err := Load(firstLayer, secondLayer)

	if err != nil {
		t.Fatal(err)
	}

	winner, err := replaced.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(winner, secondBody) || replaced.Hash() == first.Hash() {
		t.Fatalf("last DES layer did not win: %q", winner)
	}

	winner[0] = 'x'

	again, err := replaced.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(again, secondBody) {
		t.Fatal("DES read exposed mutable ruleset bytes")
	}
}

func TestDESPathValidation(t *testing.T) {
	rules, err := Load()

	if err != nil {
		t.Fatal(err)
	}

	for _, path := range []string{
		"../vaults/entry.des",
		"/vaults/entry.des",
		"vaults/entry.txt",
	} {
		if _, err := rules.ReadFile(path); err == nil {
			t.Errorf("accepted invalid DES path %q", path)
		}
	}

	first := t.TempDir()
	second := t.TempDir()
	writeTestFile(t, first, "vaults/Entry.des", []byte("NAME: entry\n"))
	writeTestFile(t, second, "vaults/entry.des", []byte("NAME: entry\n"))

	if _, err := Load(first, second); err == nil ||
		!strings.Contains(err.Error(), "case") {
		t.Fatalf("DES case collision: %v", err)
	}
}

func TestSingleContentFileParticipatesInRulesetIdentity(t *testing.T) {
	bundled, err := Load()

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
	rules, err := Load()

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

func TestOrderedSparseLayers(t *testing.T) {
	first := t.TempDir()
	second := t.TempDir()

	copyLayerFixtureAs(t, first,
		"first/content/monsters/first.lua", "content/monsters/first.lua")
	copyLayerFixtureAs(t, second,
		"second/content/spells/second.lua", "content/spells/second.lua")
	copyLayerFixtureAs(t, first, "first/lib/shared.lua", "lib/shared.lua")
	copyLayerFixtureAs(t, second, "second/lib/shared.lua", "lib/shared.lua")

	forward, err := Load(first, second)

	if err != nil {
		t.Fatal(err)
	}

	reverse, err := Load(second, first)

	if err != nil {
		t.Fatal(err)
	}

	for _, name := range []string{
		"content/monsters/first.lua",
		"content/spells/second.lua",
	} {
		if _, err := forward.ReadFile(name); err != nil {
			t.Fatalf("missing sparse layer file %s: %v", name, err)
		}
	}

	winner, err := forward.ReadFile("lib/shared.lua")

	if err != nil {
		t.Fatal(err)
	}

	expected, err := os.ReadFile("testdata/layers/second/lib/shared.lua")

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(winner, expected) || forward.Hash() == reverse.Hash() {
		t.Fatalf("wrong precedence or hash: winner=%q", winner)
	}
}

func TestLayerCaseCollision(t *testing.T) {
	overlay := t.TempDir()

	copyLuaFixtureAs(t, overlay, "init.lua", "Init.lua")

	_, err := Load(overlay)

	if err == nil {
		t.Fatal("case collision accepted")
	}

	if !strings.Contains(err.Error(), overlay) ||
		!strings.Contains(err.Error(), "Init.lua") {
		t.Fatalf("case collision lacks layer and path: %v", err)
	}
}

func TestLayerIdentity(t *testing.T) {
	bundled, err := Load()

	if err != nil {
		t.Fatal(err)
	}

	init, err := bundled.ReadFile("init.lua")

	if err != nil {
		t.Fatal(err)
	}

	first := t.TempDir()
	second := t.TempDir()

	writeTestFile(t, first, "init.lua", init)
	writeTestFile(t, second, "init.lua", init)

	withCopies, err := Load(first, second)

	if err != nil {
		t.Fatal(err)
	}

	if !withCopies.Vanilla() ||
		withCopies.Hash() != bundled.Hash() ||
		!reflect.DeepEqual(withCopies.Manifest(), bundled.Manifest()) ||
		!reflect.DeepEqual(withCopies.Changes(), bundled.Changes()) {
		t.Fatal("byte-identical layers changed effective identity")
	}

	copyLayerFixtureAs(t, first, "identical.lua", "lib/addition.lua")
	copyLayerFixtureAs(t, second, "identical.lua", "lib/addition.lua")

	forward, err := Load(first, second)

	if err != nil {
		t.Fatal(err)
	}

	reverse, err := Load(second, first)

	if err != nil {
		t.Fatal(err)
	}

	if forward.Vanilla() ||
		forward.Hash() != reverse.Hash() ||
		!reflect.DeepEqual(forward.Manifest(), reverse.Manifest()) ||
		!reflect.DeepEqual(forward.Changes(), reverse.Changes()) {
		t.Fatal("equivalent effective trees have different identity")
	}
}

func TestInvalidLaterLayer(t *testing.T) {
	for _, name := range []string{"README.txt", "escape.lua"} {
		t.Run(name, func(t *testing.T) {
			first := t.TempDir()
			second := t.TempDir()

			copyLayerFixtureAs(t, first, "identical.lua", "lib/valid.lua")

			if name == "escape.lua" {
				outside := filepath.Join(t.TempDir(), "outside.lua")

				copyLayerFixtureAs(t, filepath.Dir(outside), "identical.lua",
					filepath.Base(outside))

				if err := os.Symlink(outside, filepath.Join(second, name)); err != nil {
					t.Skipf("symlinks unavailable: %v", err)
				}
			} else {
				writeTestFile(t, second, name, []byte("invalid\n"))
			}

			_, err := Load(first, second)

			if err == nil {
				t.Fatal("invalid later layer accepted")
			}

			if !strings.Contains(err.Error(), second) ||
				!strings.Contains(err.Error(), name) {
				t.Fatalf("invalid later layer lacks context: %v", err)
			}
		})
	}
}

func copyLayerFixtureAs(t *testing.T, root, source, name string) {
	t.Helper()

	data, err := os.ReadFile(filepath.Join("testdata/layers", source))

	if err != nil {
		t.Fatal(err)
	}

	writeTestFile(t, root, name, data)
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
