package game

import (
	"fmt"
	"reflect"
	"slices"
	"testing"

	"crawl/internal/vault"
)

// The Depths:4 gate must lead through four generated Zot floors to the
// authored Hall. The exact chosen maps and the Orb record survive a save.
func TestZotGateHallAndOrbSurviveSave(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	descendGeneratedTo(t, g, 15)

	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max

	depths := followBranch(t, g, g.levels[15], "BRANCH_DEPTHS")
	depths = descendBranch(t, g, depths, 4)

	entry := ""

	for _, record := range depths.VaultRecords() {
		if record.Kind == vault.KindFeature &&
			record.Identity == "enter_zot" {
			entry = record.SourceID
			break
		}
	}

	if entry == "" || !slices.Contains(depths.VaultIDs(), entry) {
		t.Fatalf("Depths:4 has no authored Zot gate in %v",
			depths.VaultIDs())
	}

	zot := followBranch(t, g, depths, "BRANCH_ZOT")

	for depth := 1; depth <= 4; depth++ {
		if depth > 1 {
			zot = descendBranch(t, g, zot, depth)
		}

		style := fmt.Sprintf("hall_of_Zot_%d", depth)

		if !slices.Contains(zot.VaultIDs(), style) {
			t.Fatalf("Zot:%d missing source style helper %s in %v",
				depth, style, zot.VaultIDs())
		}
	}

	zotFour := zot
	zot = descendBranch(t, g, zot, 5)

	if zot.BranchID != "BRANCH_ZOT" ||
		zot.LocalDepth != 5 ||
		zot.VaultID() != "hall_of_Zot" {
		t.Fatalf("Zot final floor = %s:%d %q",
			zot.BranchID, zot.LocalDepth, zot.VaultID())
	}

	returns := 0

	for _, link := range zot.StairLinks() {
		if link.ToLevelID == zotFour.ID && link.Unavailable == "" {
			returns++
		}
	}

	if returns == 0 {
		t.Fatal("Zot:5 has no reciprocal stair to Zot:4")
	}

	orbs := 0

	for _, record := range zot.VaultRecords() {
		if record.Kind == vault.KindItem {
			for _, argument := range record.Arguments {
				if argument.Name == "kind_id" &&
					argument.String == "ORB_ZOT" {
					orbs++
				}
			}
		}
	}

	if orbs != 1 {
		t.Fatalf("Hall of Zot has %d authored Orb records", orbs)
	}

	liveOrbs := 0

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, onFloor := g.stores.Positions.Get(entity)

		if onFloor &&
			position.LevelID == zot.ID &&
			item.KindID == "ORB_ZOT" {
			liveOrbs++
		}
	}

	if liveOrbs != 1 {
		t.Fatalf("Hall of Zot has %d live Orb entities", liveOrbs)
	}

	health.Max = 18
	health.Current = 18

	before := g.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatalf("restore Zot run: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("Zot map or Orb record changed across restore")
	}
}
