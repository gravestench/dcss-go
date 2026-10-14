package branchimport

import (
	"strings"
	"testing"
)

const syntheticEnum = `enum branch_type
{
 BRANCH_DUNGEON,
 BRANCH_TEMPLE,
 BRANCH_FIRST_NON_DUNGEON = BRANCH_TEMPLE,
#if TAG_MAJOR_VERSION > 34
 BRANCH_NEW,
#endif
 NUM_BRANCHES,
 GLOBAL_BRANCH_INFO = 127,
};`

const syntheticTable = `const Branch branches[NUM_BRANCHES] =
{
 { BRANCH_DUNGEON, NUM_BRANCHES, 0, 0, 15, 0,
 brflag::none, NUM_FEATURES, DNGN_EXIT_DUNGEON, NUM_FEATURES,
 "Dungeon", "the Dungeon", "D", nullptr,
 LIGHTGREY, BROWN, 'D', {}, branch_noise::normal, DEFAULT_MON_DIE_SIZE },
 { BRANCH_TEMPLE, BRANCH_DUNGEON, 4, 7, 1, 5,
 brflag::no_items | brflag::spotty, DNGN_ENTER_TEMPLE, DNGN_EXIT_TEMPLE, NUM_FEATURES,
 "Temple", "the Ecumenical Temple", "Temple", "Welcome " "inside.\\n",
 LIGHTGREY, BROWN, 'T', { RUNE_ONE, RUNE_TWO }, branch_noise::quiet },
};`

func TestParseTag34BranchRows(t *testing.T) {
	ids, err := parseEnum("branch-type.h", []byte(syntheticEnum))
	if err != nil || len(ids) != 2 || ids[1].ID != "BRANCH_TEMPLE" || ids[1].NumericID != 1 {
		t.Fatalf("enum %+v, %v", ids, err)
	}
	branches, err := parseTable("branch-data.h", []byte(syntheticTable))
	if err != nil || len(branches) != 2 {
		t.Fatalf("table %+v, %v", branches, err)
	}
	if branches[1].ParentID != "BRANCH_DUNGEON" || branches[1].EntryMessage != "Welcome inside.\\n" || branches[1].MonDieSizeExpr != "" || len(branches[1].Runes) != 2 || len(branches[1].Flags) != 2 {
		t.Fatalf("Temple %+v", branches[1])
	}
	if err := reconcile(ids, branches); err != nil {
		t.Fatal(err)
	}
}

func TestBranchImporterRejectsUnrecognizedRows(t *testing.T) {
	for _, source := range []string{
		strings.Replace(syntheticEnum, "BRANCH_TEMPLE,", "BRANCH_TEMPLE = 4,", 1),
		strings.Replace(syntheticEnum, "NUM_BRANCHES,", "BRANCH_SURPRISE,\n NUM_BRANCHES,", 1),
	} {
		ids, err := parseEnum("branch-type.h", []byte(source))
		if err == nil && len(ids) == 2 {
			t.Fatalf("accepted altered branch identity: %+v", ids)
		}
	}
	for _, source := range []string{
		strings.Replace(syntheticTable, "BRANCH_TEMPLE, BRANCH_DUNGEON", "BRANCH_UNKNOWN, BRANCH_DUNGEON", 1),
		strings.Replace(syntheticTable, "branch_noise::quiet },", "branch_noise::quiet, surprise },", 1),
		strings.Replace(syntheticTable, "};", "garbage\n};", 1),
	} {
		rows, err := parseTable("branch-data.h", []byte(source))
		if err == nil {
			ids, enumErr := parseEnum("branch-type.h", []byte(syntheticEnum))
			if enumErr == nil {
				err = reconcile(ids, rows)
			}
		}
		if err == nil {
			t.Fatalf("accepted altered branch row: %q", source)
		}
	}
}
