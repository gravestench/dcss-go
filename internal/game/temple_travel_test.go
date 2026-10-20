package game

import (
	"strings"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// The scheduled Dungeon entrance belongs to a source entry vault. Its
// first traversal creates the already chosen main Temple map and exact
// saved altar identities, then pairs the return stair to that entrance.
func TestScheduledTempleEntryUsesSavedSourceMap(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_TEMPLE" {
			parentDepth = entry.ParentDepth
		}
	}

	if parentDepth == 0 {
		t.Fatal("Temple has no scheduled Dungeon entrance")
	}

	descendGeneratedTo(t, g, parentDepth)
	parent := g.levels[parentDepth]
	var entrance StairLink

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_TEMPLE" {
			entrance = link
			break
		}
	}

	if !entrance.Pending || entrance.ToLevelID == 0 {
		t.Fatalf("Temple entrance = %+v", entrance)
	}

	var sourceEntry bool

	for _, record := range parent.VaultRecords() {
		if record.X == entrance.X && record.Y == entrance.Y &&
			record.Kind == vault.KindFeature &&
			record.Identity == "enter_temple" {
			sourceEntry = true
		}
	}

	if !sourceEntry {
		t.Fatal("Temple entrance has no source entry-vault feature")
	}

	if err := parent.MoveActor(g.player, entrance.X, entrance.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	child := g.levels[entrance.ToLevelID]

	if child == nil || child.BranchID != "BRANCH_TEMPLE" ||
		child.VaultID() != g.templePlan.MapID {
		t.Fatalf("Temple floor = %+v", child)
	}

	assigned := make(map[string]bool)
	altarPoints := make(map[string][2]int)

	for _, record := range child.VaultRecords() {
		if record.Kind != vault.KindSourceFeature ||
			record.Identity != "DNGN_RANDOM_ALTAR" {
			continue
		}

		for _, argument := range record.Arguments {
			if argument.Name == "god_id" {
				assigned[argument.String] = true
				altarPoints[argument.String] = [2]int{record.X, record.Y}
			}
		}
	}

	if len(assigned) != g.templePlan.AltarCount {
		t.Fatalf("Temple has %d saved gods, want %d",
			len(assigned), g.templePlan.AltarCount)
	}

	for _, id := range g.templePlan.MainGodIDs {
		if !assigned[id] {
			t.Fatalf("Temple omitted saved god %s", id)
		}

		point := altarPoints[id]

		if child.Cells()[point[1]][point[0]] != terrain.Altar {
			t.Fatalf("Temple god %s has no altar terrain at %v", id, point)
		}
	}

	g.visibleLevelID = child.ID
	g.visible = make([]bool, child.width*len(child.terrain))

	for index := range g.visible {
		g.visible[index] = true
	}

	visible := View{}
	g.fillVaultView(&visible, child)
	shown := make(map[string]bool)

	for _, entity := range visible.Entities {
		if entity.Role == "altar" {
			shown[entity.KindID] = entity.Name != "" && entity.Glyph == '_'
		}
	}

	for _, id := range g.templePlan.MainGodIDs {
		if !shown[id] {
			t.Fatalf("Temple god %s has no named visible altar", id)
		}
	}

	resolved, found := parent.StairAt(entrance.X, entrance.Y)

	if !found || resolved.Pending || resolved.ToLevelID != child.ID {
		t.Fatalf("Temple parent link = %+v", resolved)
	}

	back, found := child.StairAt(resolved.ToX, resolved.ToY)

	if !found || back.ToLevelID != parentDepth ||
		back.ToX != entrance.X || back.ToY != entrance.Y {
		t.Fatalf("Temple return link = %+v", back)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if restored.templePlan.MapID != g.templePlan.MapID ||
		restored.levels[entrance.ToLevelID].VaultID() != child.VaultID() {
		t.Fatal("restored Temple changed its saved map")
	}

	returned, err := restored.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	if returned.View.LevelID != parentDepth {
		t.Fatalf("Temple return reached level %d, want %d",
			returned.View.LevelID, parentDepth)
	}

	reentered, err := restored.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	if reentered.View.LevelID != child.ID ||
		restored.levels[child.ID].VaultID() != child.VaultID() {
		t.Fatal("Temple revisit rerolled its floor")
	}

	forged := g.Snapshot()
	changed := false

	for levelIndex := range forged.Levels {
		if forged.Levels[levelIndex].ID != child.ID {
			continue
		}

		for recordIndex := range forged.Levels[levelIndex].VaultRecords {
			record := &forged.Levels[levelIndex].VaultRecords[recordIndex]

			if record.Identity != string(terrain.Altar) {
				continue
			}

			for argumentIndex := range record.Arguments {
				if record.Arguments[argumentIndex].Name == "god_id" {
					record.Arguments[argumentIndex].String = "GOD_NO_GOD"
					changed = true
					break
				}
			}

			if changed {
				break
			}
		}
	}

	if !changed {
		t.Fatal("test could not find a saved Temple altar")
	}

	if bad, err := Restore(forged); err == nil ||
		!strings.Contains(err.Error(), "Temple altar") {
		if bad != nil {
			_ = bad.Close()
		}

		t.Fatalf("forged Temple altar error = %v", err)
	}
}

// A zero ambient budget must still run authored vault population once.
// This source map contains keyed plants and fungi among its altar cells.
func TestTempleMaterializesAuthoredMonstersWithoutAmbientSpawns(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	allGods := append([]string{}, g.templePlan.MainGodIDs...)
	allGods = append(allGods, g.templePlan.OverflowGodIDs...)
	g.templePlan.MapID = "ebering_untended_altars"
	g.templePlan.AltarCount = 12
	g.templePlan.MainGodIDs = append([]string{}, allGods[:12]...)
	g.templePlan.OverflowGodIDs = append([]string{}, allGods[12:]...)

	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_TEMPLE" {
			parentDepth = entry.ParentDepth
			break
		}
	}

	descendGeneratedTo(t, g, parentDepth)
	parent := g.levels[parentDepth]
	var entrance StairLink

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_TEMPLE" {
			entrance = link
			break
		}
	}

	if err := parent.MoveActor(g.player, entrance.X, entrance.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	temple := g.levels[entrance.ToLevelID]

	if temple.initialMonsters != 0 || temple.initialActors != 0 {
		t.Fatalf("Temple ambient budgets = rolls %d, actors %d",
			temple.initialMonsters, temple.initialActors)
	}

	materialized := 0

	for _, record := range temple.VaultRecords() {
		if record.Kind == vault.KindMonster && !record.Pending {
			if _, found := temple.ActorAt(record.X, record.Y); found {
				materialized++
			}
		}
	}

	if materialized == 0 {
		t.Fatal("source Temple monsters were not materialized")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	remaining := 0

	for _, record := range restored.levels[temple.ID].VaultRecords() {
		if record.Kind == vault.KindMonster && !record.Pending {
			if _, found := restored.levels[temple.ID].ActorAt(
				record.X, record.Y); found {
				remaining++
			}
		}
	}

	if remaining != materialized {
		t.Fatalf("restored Temple has %d authored monsters, want %d",
			remaining, materialized)
	}
}
