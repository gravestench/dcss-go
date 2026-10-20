package game

import (
	"strings"
	"testing"

	"crawl/internal/vault"
)

// A saved overflow group becomes authored altars on its scheduled Dungeon
// floor. The same god identities must survive a normal save and restore.
func TestScheduledOverflowAltarsAppearOnDungeonFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 717)
	plan := g.Snapshot().TemplePlan

	if len(plan.OverflowSchedule) == 0 {
		t.Fatal("test run has no scheduled overflow altars")
	}

	depth := 10
	expected := make(map[string]bool)

	for _, group := range plan.OverflowSchedule {
		if group.Depth < depth {
			depth = group.Depth
		}
	}

	for _, group := range plan.OverflowSchedule {
		if group.Depth == depth {
			for _, id := range group.GodIDs {
				expected[id] = true
			}
		}
	}

	descendGeneratedTo(t, g, depth)

	snapshot := g.Snapshot()
	actual := make(map[string]bool)

	for _, level := range snapshot.Levels {
		if level.BranchID != "BRANCH_DUNGEON" || level.LocalDepth != depth {
			continue
		}

		for _, record := range level.VaultRecords {
			if record.Kind != vault.KindSourceFeature ||
				record.Identity != "DNGN_RANDOM_ALTAR" {
				continue
			}

			for _, argument := range record.Arguments {
				if argument.Name == "god_id" {
					actual[argument.String] = true
				}
			}
		}
	}

	if len(actual) != len(expected) {
		t.Fatalf("D:%d overflow altars = %v, want %v", depth, actual, expected)
	}

	for id := range expected {
		if !actual[id] {
			t.Fatalf("D:%d lacks scheduled overflow god %s", depth, id)
		}
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	forged := g.Snapshot()
	changed := false

	for levelIndex := range forged.Levels {
		level := &forged.Levels[levelIndex]

		if level.BranchID != "BRANCH_DUNGEON" ||
			level.LocalDepth != depth {
			continue
		}

		for recordIndex := range level.VaultRecords {
			record := &level.VaultRecords[recordIndex]

			if record.Kind != vault.KindSourceFeature ||
				record.Identity != "DNGN_RANDOM_ALTAR" {
				continue
			}

			for argumentIndex := range record.Arguments {
				argument := &record.Arguments[argumentIndex]

				if argument.Name == "god_id" {
					argument.String = plan.MainGodIDs[0]
					changed = true
					break
				}
			}
		}
	}

	if !changed {
		t.Fatal("test floor has no saved god argument to forge")
	}

	if rejected, err := Restore(forged); err == nil ||
		!strings.Contains(err.Error(), "overflow altar") {
		if rejected != nil {
			_ = rejected.Close()
		}

		t.Fatalf("forged overflow altar error = %v", err)
	}
}

// The source also schedules two gods into one map. Reaching that floor
// exercises the count-aware hook and binds both identities to one layout.
func TestScheduledMultiGodOverflowMap(t *testing.T) {
	g := newGeneratedTestGame(t, 1)
	depth := 8
	expected := make(map[string]bool)
	multi := false

	for _, group := range g.Snapshot().TemplePlan.OverflowSchedule {
		if group.Depth != depth {
			continue
		}

		multi = multi || len(group.GodIDs) > 1

		for _, id := range group.GodIDs {
			expected[id] = true
		}
	}

	if !multi {
		t.Fatal("seed no longer schedules a multi-god D:8 map")
	}

	descendGeneratedTo(t, g, depth)

	actual := make(map[string]bool)

	for _, level := range g.Snapshot().Levels {
		if level.BranchID != "BRANCH_DUNGEON" || level.LocalDepth != depth {
			continue
		}

		for _, record := range level.VaultRecords {
			if record.Kind != vault.KindSourceFeature ||
				record.Identity != "DNGN_RANDOM_ALTAR" {
				continue
			}

			for _, argument := range record.Arguments {
				if argument.Name == "god_id" {
					actual[argument.String] = true
				}
			}
		}
	}

	if len(actual) != len(expected) {
		t.Fatalf("multi-god D:8 altars = %v, want %v", actual, expected)
	}

	for id := range expected {
		if !actual[id] {
			t.Fatalf("multi-god D:8 lacks scheduled %s", id)
		}
	}
}
