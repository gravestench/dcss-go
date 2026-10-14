package monsterbookimport

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func TestGenerateAndCheckUseExplicitPinnedFiles(t *testing.T) {
	root := t.TempDir()
	files := map[string]string{
		"mon-spell.h": fixtureBooks,
		"mon-mst.h":   fixtureEnum,
		"externs.h":   fixtureFlags,
	}

	for name, body := range files {
		if err := os.WriteFile(filepath.Join(root, name), []byte(body), 0600); err != nil {
			t.Fatal(err)
		}
	}

	out := filepath.Join(root, "monster-spellbooks.json")

	if err := Write(root, out, false); err != nil {
		t.Fatal(err)
	}

	if err := Write(root, out, true); err != nil {
		t.Fatal(err)
	}

	data, err := os.ReadFile(out)

	if err != nil {
		t.Fatal(err)
	}

	var artifact content.MonsterSpellbookArtifact

	if err := json.Unmarshal(data, &artifact); err != nil {
		t.Fatal(err)
	}

	if len(artifact.Books) != 2 ||
		len(artifact.SourceFiles) != 3 {
		t.Fatalf("incomplete generated artifact %+v", artifact)
	}

	if err := os.WriteFile(out, []byte("corrupt"), 0600); err != nil {
		t.Fatal(err)
	}

	if err := Write(root, out, true); err == nil {
		t.Fatal("check accepted changed committed artifact")
	}
}

func TestGenerateRejectsUnknownCommittedSpell(t *testing.T) {
	root := t.TempDir()
	books := strings.Replace(fixtureBooks, "SPELL_SLUG_DART", "SPELL_NOT_IN_CATALOG", 1)
	files := map[string]string{
		"mon-spell.h": books,
		"mon-mst.h":   fixtureEnum,
		"externs.h":   fixtureFlags,
	}

	for name, body := range files {
		if err := os.WriteFile(filepath.Join(root, name), []byte(body), 0600); err != nil {
			t.Fatal(err)
		}
	}

	if _, err := Generate(root); err == nil {
		t.Fatal("generated an unknown monster spell")
	}
}

func TestGenerateAcceptsPinnedOptionalSpellFlags(t *testing.T) {
	root := t.TempDir()
	books := strings.Replace(
		fixtureBooks,
		"MON_SPELL_NATURAL }",
		"MON_SPELL_NATURAL | MON_SPELL_NO_SILENT | MON_SPELL_EVOKE }",
		1,
	)
	flags := fixtureFlags + "\n"
	flags = strings.Replace(
		flags,
		"    MON_SPELL_NOISY = 4,",
		"    MON_SPELL_NOISY = 4,\n    MON_SPELL_NO_SILENT = 16,\n    MON_SPELL_EVOKE = 32,",
		1,
	)

	files := map[string]string{
		"mon-spell.h": books,
		"mon-mst.h":   fixtureEnum,
		"externs.h":   flags,
	}

	for name, body := range files {
		if err := os.WriteFile(filepath.Join(root, name), []byte(body), 0600); err != nil {
			t.Fatal(err)
		}
	}

	if _, err := Generate(root); err != nil {
		t.Fatal(err)
	}
}
