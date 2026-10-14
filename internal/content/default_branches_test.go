package content

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestCommittedBranchCatalogCoverageAndCopies(t *testing.T) {
	catalog, err := LoadDefault()
	if err != nil {
		t.Fatal(err)
	}

	ids := catalog.BranchIDs()
	if len(ids) != 38 || ids[0] != "BRANCH_DUNGEON" || ids[len(ids)-1] != "BRANCH_ARENA" {
		t.Fatalf("branch IDs %d: %v", len(ids), ids)
	}

	ids[0] = "corrupted"
	if catalog.BranchIDs()[0] != "BRANCH_DUNGEON" {
		t.Fatal("branch IDs alias catalog")
	}

	dungeon, err := catalog.Branch("BRANCH_DUNGEON")
	if err != nil || dungeon.ParentID != "NUM_BRANCHES" || dungeon.Depth != 15 || dungeon.TravelShortcut != "D" {
		t.Fatalf("Dungeon %+v, %v", dungeon, err)
	}

	swamp, err := catalog.Branch("BRANCH_SWAMP")
	if err != nil || swamp.ParentID != "BRANCH_LAIR" || swamp.MinDepth != 2 || swamp.MaxDepth != 3 ||
		len(swamp.Runes) != 1 || swamp.Runes[0] != "RUNE_SWAMP" {
		t.Fatalf("Swamp %+v, %v", swamp, err)
	}

	swamp.Runes[0] = "RUNE_BOGUS"
	swamp.Flags[0] = "bogus"
	again, _ := catalog.Branch("BRANCH_SWAMP")
	if again.Runes[0] != "RUNE_SWAMP" || again.Flags[0] == "bogus" {
		t.Fatal("branch slices alias catalog")
	}

	if _, err := catalog.Branch("BRANCH_UNKNOWN"); err == nil {
		t.Fatal("unknown branch accepted")
	}
}

func TestCommittedBranchArtifactRejectsSameCountSubstitution(t *testing.T) {
	var artifact BranchArtifact
	if err := json.Unmarshal(defaultBranchJSON, &artifact); err != nil {
		t.Fatal(err)
	}

	if err := artifact.Validate(); err != nil {
		t.Fatal(err)
	}

	for _, changed := range []string{
		strings.Replace(string(defaultBranchJSON), "BRANCH_DUNGEON", "BRANCH_REPLACED", 1),
		strings.Replace(string(defaultBranchJSON), "the Dungeon", "a Dungeon", 1),
		strings.Replace(string(defaultBranchJSON), artifact.SourceFiles[0].SHA256, strings.Repeat("0", 64), 1),
	} {
		if _, err := attachDefaultBranches(scenarioCatalog(), []byte(changed)); err == nil {
			t.Fatal("accepted altered committed branch content")
		}
	}
}
