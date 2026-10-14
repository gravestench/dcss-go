package monsterbookimport

import (
	"testing"
)

const fixtureBooks = `static const mon_spellbook mspell_list[] =
{
    { MST_DART_SLUG,
      {
        { SPELL_SLUG_DART, 60, MON_SPELL_NATURAL }
      }
    },
    { MST_BREATH,
      {
        { SPELL_FIRE_BREATH, 68, MON_SPELL_NATURAL | MON_SPELL_BREATH
                                   | MON_SPELL_NOISY },
      }
    },
};`

const fixtureEnum = `enum mon_spellbook_type
{
    MST_DART_SLUG,
    MST_BREATH,
    MST_GHOST,
    NUM_MSTYPES,
    MST_NO_SPELLS
};`

const fixtureFlags = `enum mon_spell_slot_flag
{
    MON_SPELL_NATURAL = 1,
    MON_SPELL_WIZARD = 8,
    MON_SPELL_BREATH = 2,
    MON_SPELL_NOISY = 4,
};`

func TestParseBooksPreservesOrderFlagsAndSourceLines(t *testing.T) {
	books, err := parseBooks("mon-spell.h", []byte(fixtureBooks))

	if err != nil {
		t.Fatal(err)
	}

	if len(books) != 2 ||
		books[0].ID != "MST_DART_SLUG" ||
		books[1].ID != "MST_BREATH" ||
		books[0].Slots[0].SourceLine != 5 ||
		books[1].Slots[0].Frequency != 68 ||
		len(books[1].Slots[0].Flags) != 3 ||
		books[1].Slots[0].Flags[2] != "MON_SPELL_NOISY" {
		t.Fatalf("parsed books %+v", books)
	}

	ids, err := parseBookEnum("mon-mst.h", []byte(fixtureEnum))

	if err != nil {
		t.Fatal(err)
	}

	flags, err := parseFlagVocabulary("externs.h", []byte(fixtureFlags))

	if err != nil {
		t.Fatal(err)
	}

	if err := reconcile(books, ids, flags); err != nil {
		t.Fatal(err)
	}
}

func TestReconcileRejectsMissingBookAndUnknownFlag(t *testing.T) {
	books, err := parseBooks("mon-spell.h", []byte(fixtureBooks))

	if err != nil {
		t.Fatal(err)
	}

	ids, _ := parseBookEnum("mon-mst.h", []byte(fixtureEnum))
	flags, _ := parseFlagVocabulary("externs.h", []byte(fixtureFlags))

	if err := reconcile(books[:1], ids, flags); err == nil {
		t.Fatal("accepted missing active spellbook")
	}

	books[0].Slots[0].Flags[0] = "MON_SPELL_UNKNOWN"

	if err := reconcile(books, ids, flags); err == nil {
		t.Fatal("accepted unknown spell flag")
	}
}

func TestReconcileRejectsDuplicateAndReorderedBooks(t *testing.T) {
	books, err := parseBooks("mon-spell.h", []byte(fixtureBooks))

	if err != nil {
		t.Fatal(err)
	}

	ids, _ := parseBookEnum("mon-mst.h", []byte(fixtureEnum))
	flags, _ := parseFlagVocabulary("externs.h", []byte(fixtureFlags))

	books[0], books[1] = books[1], books[0]

	if err := reconcile(books, ids, flags); err == nil {
		t.Fatal("accepted reordered source books")
	}

	books[0] = books[1]

	if err := reconcile(books, ids, flags); err == nil {
		t.Fatal("accepted duplicate source book")
	}
}

func TestParseBooksAcceptsGroupedStokerSlots(t *testing.T) {
	source := `static const mon_spellbook mspell_list[] =
{
    { MST_STOKER,
      {
       {
        { SPELL_WIND_BLAST, 20, MON_SPELL_WIZARD },
        { SPELL_STOKE_FLAMES, 10, MON_SPELL_WIZARD },
       }
      }
    },
};`

	books, err := parseBooks("mon-spell.h", []byte(source))

	if err != nil ||
		len(books) != 1 ||
		len(books[0].Slots) != 2 {
		t.Fatalf("grouped stoker slots %+v, %v", books, err)
	}
}
