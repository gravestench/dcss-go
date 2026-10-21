package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/vault"
)

// A source entry's keyed O cell must own the scheduled water-branch stair.
// Both branches use the same production travel and save path.
func TestScheduledWaterBranchEntriesUseSourceMaps(t *testing.T) {
	cases := []struct {
		name          string
		branchID      string
		sourceFeature string
		keyedFeature  string
		newRun        func(*testing.T) *Game
		fog           bool
	}{
		{
			name:          "Swamp",
			branchID:      "BRANCH_SWAMP",
			sourceFeature: "DNGN_ENTER_SWAMP",
			keyedFeature:  "enter_swamp",
			newRun:        swampRun,
			fog:           true,
		},

		{
			name:          "Shoals",
			branchID:      "BRANCH_SHOALS",
			sourceFeature: "DNGN_ENTER_SHOALS",
			keyedFeature:  "enter_shoals",
			newRun:        shoalsRun,
		},
	}

	for _, scenario := range cases {
		t.Run(scenario.name, func(t *testing.T) {
			g := scenario.newRun(t)
			lairParent := 0
			branchParent := 0

			for _, scheduled := range g.branchSchedule.Entries {
				switch scheduled.BranchID {
				case "BRANCH_LAIR":
					lairParent = scheduled.ParentDepth

				case scenario.branchID:
					branchParent = scheduled.ParentDepth
				}
			}

			if lairParent == 0 || branchParent == 0 {
				t.Fatal("generated schedule has no water-branch route")
			}

			descendGeneratedTo(t, g, lairParent)

			health, _ := g.stores.Health.Get(g.player)

			health.Max = 10000
			health.Current = health.Max

			lair := followBranch(t, g,
				g.levels[lairParent], "BRANCH_LAIR")
			parent := descendBranch(t, g, lair, branchParent)
			entrance := waterEntryLink(t, parent, scenario.branchID)

			if !entrance.Pending ||
				entrance.SourceFeature != scenario.sourceFeature {
				t.Fatalf("authored entrance link = %+v", entrance)
			}

			entryID := waterEntrySource(t, parent, entrance,
				scenario.keyedFeature)

			if scenario.fog {
				checkEntryFog(t, g, parent, entryID)
			}

			health.Max = 18
			health.Current = 18

			snapshot := g.Snapshot()
			restored, err := Restore(snapshot)

			if err != nil {
				t.Fatalf("authored entrance save: %v", err)
			}

			defer restored.Close()

			if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
				t.Fatal("entrance changed across restore")
			}

			linked, found := restored.levels[parent.ID].StairAt(
				entrance.X, entrance.Y)

			if !found || linked != entrance {
				t.Fatalf("restored entrance = %+v, found %t",
					linked, found)
			}

			health.Max = 10000
			health.Current = health.Max

			clearWaterGateGuard(t, g, parent, entrance)

			child := followBranch(t, g, parent,
				scenario.branchID)

			if child.BranchID != scenario.branchID ||
				child.LocalDepth != 1 {
				t.Fatalf("water branch destination = %s:%d",
					child.BranchID, child.LocalDepth)
			}

			parentLink, found := parent.StairAt(
				entrance.X, entrance.Y)

			if !found ||
				parentLink.Pending ||
				parentLink.ToLevelID != child.ID {
				t.Fatalf("resolved water gate = %+v", parentLink)
			}

			returnLink, found := child.StairAt(
				parentLink.ToX, parentLink.ToY)

			if !found ||
				returnLink.ToLevelID != parent.ID ||
				returnLink.ToX != entrance.X ||
				returnLink.ToY != entrance.Y {
				t.Fatalf("water branch reciprocal link = %+v",
					returnLink)
			}
		})
	}
}

// The scheduled link identifies the final keyed stair after map transforms.
func waterEntryLink(t *testing.T, parent *Level,
	branchID string) StairLink {
	t.Helper()

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == branchID {
			return link
		}
	}

	t.Fatalf("%s has no scheduled stair", branchID)

	return StairLink{}
}

// The placed feature record ties the chosen source NAME to the live stair.
func waterEntrySource(t *testing.T, parent *Level, entrance StairLink,
	feature string) string {
	t.Helper()

	for _, record := range parent.VaultRecords() {
		if record.Kind != vault.KindFeature ||
			record.Identity != feature ||
			record.X != entrance.X ||
			record.Y != entrance.Y {
			continue
		}

		for _, id := range parent.VaultIDs() {
			if id == record.SourceID {
				return id
			}
		}
	}

	t.Fatal("scheduled water stair has no saved source feature")

	return ""
}

// Fog is source-authored at the Swamp entry. Population must materialize
// that same record into saved ECS state, including the alternate T glyph.
func checkEntryFog(t *testing.T, g *Game, parent *Level,
	entryID string) {
	t.Helper()

	realized := false

	for _, record := range parent.VaultRecords() {
		if record.Kind == vault.KindMarker &&
			record.SourceID == entryID &&
			strings.HasPrefix(record.Identity, "lua:fog_machine") &&
			!record.Pending {
			realized = true
		}
	}

	if !realized {
		t.Fatal("source Swamp fog marker was not materialized")
	}

	store := g.scripts.Components()["world.fog_machine"]

	for _, entity := range store.Entities() {
		state, _ := store.Get(entity)
		vaultID, _ := state.Get("vault_id")
		levelID, _ := state.Get("level_id")

		if vaultID == entryID && levelID == int64(parent.ID) {
			return
		}
	}

	t.Fatal("source Swamp entry has no live fog machine")
}

// Travel tests bypass combat, so remove an authored guard only when it
// occupies the exact linked stair. Normal play must defeat it first.
func clearWaterGateGuard(t *testing.T, g *Game, parent *Level,
	entrance StairLink) {
	t.Helper()

	actor, occupied := parent.ActorAt(entrance.X, entrance.Y)

	if !occupied || actor == g.player {
		return
	}

	for _, item := range g.stores.CarriedBy.Entities() {
		carrier, _ := g.stores.CarriedBy.Get(item)

		if carrier.Holder == actor && !g.world.DestroyEntity(item) {
			t.Fatalf("remove gate guard item %d", item)
		}
	}

	if err := parent.RemoveActor(actor); err != nil {
		t.Fatal(err)
	}

	if !g.world.DestroyEntity(actor) {
		t.Fatalf("remove gate guard %d", actor)
	}
}
