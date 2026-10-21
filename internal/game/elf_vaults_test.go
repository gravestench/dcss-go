package game

import (
	"reflect"
	"testing"
)

// The scheduled Orc gate reaches an authored Elf border check, the Hall of
// Blades, and a final hall. Their selected identities survive a Go save.
func TestElfVaultsOnBranchTravel(t *testing.T) {
	g := newGeneratedTestGame(t, 425)
	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_ORC" {
			parentDepth = entry.ParentDepth
			break
		}
	}

	if parentDepth == 0 {
		t.Fatal("scheduled run has no Orc entrance")
	}

	descendGeneratedTo(t, g, parentDepth)

	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max

	orc := followBranch(t, g, g.levels[parentDepth], "BRANCH_ORC")
	orcEnd := descendBranch(t, g, orc, 2)
	elf := followBranch(t, g, orcEnd, "BRANCH_ELF")

	if elf.BranchID != "BRANCH_ELF" || elf.LocalDepth != 1 ||
		elf.VaultID() == "" {
		t.Fatalf("Elf:1 primary = %s:%d %q",
			elf.BranchID, elf.LocalDepth, elf.VaultID())
	}

	var entrance StairLink
	var foundEntrance bool

	for _, link := range orcEnd.StairLinks() {
		if link.TargetBranchID == "BRANCH_ELF" {
			entrance = link
			foundEntrance = true
			break
		}
	}

	if !foundEntrance {
		t.Fatal("Orc:2 lost its Elf entrance")
	}

	returnLink, foundReturn := elf.StairAt(entrance.ToX,
		entrance.ToY)

	if !foundReturn || returnLink.ToLevelID != orcEnd.ID ||
		returnLink.ToX != entrance.X ||
		returnLink.ToY != entrance.Y {
		t.Fatalf("Elf reciprocal link = %+v, found %t",
			returnLink, foundReturn)
	}

	if err := elf.MoveActor(g.player, returnLink.X,
		returnLink.Y); err != nil {
		t.Fatal(err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil || up.View.LevelID != orcEnd.ID {
		t.Fatalf("Elf return to Orc = %d, %v",
			up.View.LevelID, err)
	}

	if err := orcEnd.MoveActor(g.player, entrance.X,
		entrance.Y); err != nil {
		t.Fatal(err)
	}

	down, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil || down.View.LevelID != elf.ID {
		t.Fatalf("Elf reciprocal descent = %d, %v",
			down.View.LevelID, err)
	}

	hall := descendBranch(t, g, elf, 2)

	if hall.BranchID != "BRANCH_ELF" || hall.LocalDepth != 2 ||
		hall.VaultID() == "" {
		t.Fatalf("Elf:2 Hall primary = %s:%d %q",
			hall.BranchID, hall.LocalDepth, hall.VaultID())
	}

	elfEnd := descendBranch(t, g, hall, 3)

	if elfEnd.BranchID != "BRANCH_ELF" || elfEnd.LocalDepth != 3 ||
		elfEnd.VaultID() == "" {
		t.Fatalf("Elf:3 primary = %s:%d %q",
			elfEnd.BranchID, elfEnd.LocalDepth, elfEnd.VaultID())
	}

	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("restore Elf:3: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Elf primaries changed across restore")
	}
}
