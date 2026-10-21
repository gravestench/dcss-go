package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/save"
	"crawl/internal/vault"
)

// A source-labelled Dungeon entrance opens the generated primary Vaults
// floors in sequence, then the authored four-quadrant end floor and rune.
func TestGeneratedVaultsPrimaryFloorsAndEndVault(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_VAULTS" {
			parentDepth = entry.ParentDepth
			break
		}
	}

	if parentDepth == 0 {
		t.Fatal("Vaults has no scheduled Dungeon entrance")
	}

	descendGeneratedTo(t, g, parentDepth)
	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max
	parent := g.levels[parentDepth]
	var entrance StairLink

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_VAULTS" {
			entrance = link
			break
		}
	}

	if !entrance.Pending || entrance.Unavailable != "" {
		t.Fatalf("Vaults entrance = %+v", entrance)
	}

	if err := parent.MoveActor(g.player, entrance.X, entrance.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	level := g.levels[entrance.ToLevelID]
	roomHistory := make(map[int][]string)
	var endDeparture StairLink

	for depth := 1; depth <= 4; depth++ {
		if level == nil || level.BranchID != "BRANCH_VAULTS" ||
			level.LocalDepth != depth {
			t.Fatalf("Vaults:%d = %+v", depth, level)
		}

		ids := level.VaultIDs()

		if len(ids) == 0 {
			t.Fatalf("Vaults:%d lost its authored room history", depth)
		}

		roomHistory[level.ID] = ids

		var departure StairLink

		for _, link := range level.StairLinks() {
			if link.TargetBranchID != "" {
				continue
			}

			if actor, occupied := level.ActorAt(link.X, link.Y); occupied &&
				actor != g.player {
				continue
			}

			if link.Pending {
				departure = link
				break
			}
		}

		if depth == 4 {
			if !departure.Pending || departure.ToLevelID != 1105 ||
				departure.Unavailable != "" {
				t.Fatalf("Vaults:4 end stair = %+v", departure)
			}

			endDeparture = departure
			break
		}

		if !departure.Pending {
			t.Fatalf("Vaults:%d has no pending down stair", depth)
		}

		if err := level.MoveActor(g.player, departure.X, departure.Y); err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{Kind: CommandDownstairs})

		if err != nil {
			t.Fatal(err)
		}

		if result.View.LevelID != departure.ToLevelID {
			t.Fatalf("Vaults:%d descent through %+v stayed on %d with %d HP",
				depth, departure, result.View.LevelID, result.View.PlayerHP)
		}

		level = g.levels[departure.ToLevelID]
	}

	if g.levels[1105] != nil {
		t.Fatal("Vaults:5 generated before its stair was used")
	}

	health.Max = 18
	health.Current = 18
	assertLegacyVaultsBoundary(t, g, level)

	// Exercise a resolved stair in both directions. The save validator also
	// checks links, but live travel proves the exact landing is usable.
	var ascent StairLink

	for _, link := range level.StairLinks() {
		if link.ToLevelID != 1103 || link.Unavailable != "" {
			continue
		}

		if actor, occupied := level.ActorAt(link.X, link.Y); occupied &&
			actor != g.player {
			continue
		}

		ascent = link
		break
	}

	if ascent.ToLevelID != 1103 {
		t.Fatal("Vaults:4 has no free reciprocal stair to Vaults:3")
	}

	if err := level.MoveActor(g.player, ascent.X, ascent.Y); err != nil {
		t.Fatal(err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil || up.View.LevelID != 1103 ||
		up.View.PlayerX != ascent.ToX || up.View.PlayerY != ascent.ToY {
		t.Fatalf("Vaults return through %+v: view %+v, error %v",
			ascent, up.View, err)
	}

	down, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil || down.View.LevelID != level.ID ||
		down.View.PlayerX != ascent.X || down.View.PlayerY != ascent.Y {
		t.Fatalf("Vaults reciprocal descent through %+v: view %+v, error %v",
			ascent, down.View, err)
	}

	// The travel fixture has extra HP only to survive deep monsters while
	// crossing floors. Restore the source Human/Fighter maximum before save.
	health.Max = 18
	health.Current = 18

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if restored.levels[level.ID] == nil {
		t.Fatal("Vaults:4 disappeared on restore")
	}

	for id, before := range roomHistory {
		after := restored.levels[id]

		if after == nil || !reflect.DeepEqual(after.VaultIDs(), before) {
			t.Fatalf("Vaults level %d room history changed on restore", id)
		}
	}

	forged := g.Snapshot()

	for levelIndex := range forged.Levels {
		floor := &forged.Levels[levelIndex]

		if floor.ID != level.ID {
			continue
		}

		for linkIndex := range floor.Stairs {
			link := &floor.Stairs[linkIndex]

			if !link.Pending || link.ToLevelID != 1105 {
				continue
			}

			link.ToLevelID = 1106
			break
		}
	}

	if bad, err := Restore(forged); err == nil {
		if bad != nil {
			_ = bad.Close()
		}

		t.Fatal("forged Vaults:5 link restored")
	}

	// Generate the authored end floor only through its pending V:4 stair.
	health.Max = 10000
	health.Current = health.Max

	if err := level.MoveActor(g.player, endDeparture.X, endDeparture.Y); err != nil {
		t.Fatal(err)
	}

	arrival, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil || arrival.View.LevelID != 1105 {
		t.Fatalf("Vaults:5 descent = %+v, %v", arrival.View, err)
	}

	end := g.levels[1105]

	if end == nil || end.BranchID != "BRANCH_VAULTS" ||
		end.LocalDepth != 5 || end.VaultID() != "vaults_vault" {
		t.Fatalf("Vaults end identity = level %v, branch %v, depth %v, vault %v",
			end.ID, end.BranchID, end.LocalDepth, end.VaultID())
	}

	runeX, runeY := 0, 0
	runeCount := 0

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, onFloor := g.stores.Positions.Get(entity)

		if item.KindID == "RUNE_VAULTS" && onFloor &&
			position.LevelID == end.ID {
			runeX = position.X
			runeY = position.Y
			runeCount++
		}
	}

	if runeCount != 1 {
		t.Fatalf("Vaults:5 ground silver runes = %d", runeCount)
	}

	if len(end.VaultIDs()) < 5 {
		t.Fatalf("Vaults:5 lost selected helper IDs: %v", end.VaultIDs())
	}

	monsters, items := 0, 0

	for _, record := range end.VaultRecords() {
		if record.Kind == vault.KindMonster && !record.Pending {
			monsters++
		}

		if record.Kind == vault.KindItem && !record.Pending {
			items++
		}
	}

	if monsters == 0 || items < 2 {
		t.Fatalf("Vaults:5 lost source monsters or loot: %d monsters, %d items",
			monsters, items)
	}

	linked := false

	for _, link := range level.StairLinks() {
		if link.X == endDeparture.X && link.Y == endDeparture.Y &&
			link.ToLevelID == end.ID && !link.Pending &&
			link.ToX == arrival.View.PlayerX &&
			link.ToY == arrival.View.PlayerY {
			linked = true
		}
	}

	if !linked {
		t.Fatal("Vaults:4 and Vaults:5 lack exact reciprocal cells")
	}

	health.Max = 18
	health.Current = 18
	beforePickup := g.Snapshot()
	loaded, err := Restore(beforePickup)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(beforePickup, loaded.Snapshot()) {
		t.Fatal("Vaults:5 changed across restore before rune pickup")
	}

	assertForgedVaultsEndSaves(t, g, end)

	collectVaultsSilverRune(t, g, end, runeX, runeY)

}

// Preserve the old explicit unavailable boundary after a save has passed
// ruleset hash checks; this test simulates the old stair data.
func assertLegacyVaultsBoundary(t *testing.T, g *Game, level *Level) {
	t.Helper()
	// Saves made before the end map opened had an unavailable V:5 stair.
	// Loading one must retain that visible boundary without fabricating a
	// child floor or silently changing the old link into a pending link.
	legacy := g.Snapshot()

	for index := range legacy.Levels {
		floor := &legacy.Levels[index]

		if floor.ID != level.ID {
			continue
		}

		for stairIndex := range floor.Stairs {
			link := &floor.Stairs[stairIndex]

			if link.Pending && link.ToLevelID == 1105 {
				link.Pending = false
				link.ToLevelID = 0
				link.Unavailable = "Vaults:5 awaits its end vault in the Go port."
			}
		}
	}

	old, err := Restore(legacy)

	if err != nil {
		t.Fatalf("pre-port Vaults:4 save rejected: %v", err)
	}

	defer old.Close()

	if !reflect.DeepEqual(legacy, old.Snapshot()) {
		t.Fatal("pre-port unavailable Vaults:5 link changed on restore")
	}
}

// A saved end composition must retain its rune source and helper history.
func assertForgedVaultsEndSaves(t *testing.T, g *Game, end *Level) {
	t.Helper()
	// Save validation must reject a forged end composition before restoring
	// entities, while leaving a collected rune valid after pickup.
	isRune := func(record vault.Record) bool {
		if record.Kind != vault.KindItem {
			return false
		}

		for _, argument := range record.Arguments {
			if argument.Name == "kind_id" &&
				argument.String == "RUNE_VAULTS" {
				return true
			}
		}

		return false
	}

	corruptions := []struct {
		name   string
		change func(*save.LevelRecord)
	}{
		{
			name: "missing rune record",
			change: func(floor *save.LevelRecord) {
				for index, record := range floor.VaultRecords {
					if isRune(record) {
						floor.VaultRecords = append(floor.VaultRecords[:index],
							floor.VaultRecords[index+1:]...)
						return
					}
				}

				t.Fatal("source rune record absent")
			},
		},
		{
			name: "duplicate rune record",
			change: func(floor *save.LevelRecord) {
				for _, record := range floor.VaultRecords {
					if isRune(record) {
						floor.VaultRecords = append(floor.VaultRecords, record)
						return
					}
				}

				t.Fatal("source rune record absent")
			},
		},
		{
			name: "missing selected IDs",
			change: func(floor *save.LevelRecord) {
				floor.VaultIDs = nil
			},
		},
	}

	for _, corruption := range corruptions {
		t.Run(corruption.name, func(t *testing.T) {
			forged := g.Snapshot()

			for index := range forged.Levels {
				floor := &forged.Levels[index]

				if floor.ID == end.ID {
					corruption.change(floor)
					break
				}
			}

			loaded, err := Restore(forged)

			if loaded != nil {
				_ = loaded.Close()
			}

			if err == nil || !strings.Contains(err.Error(), "Vaults end needs") {
				t.Fatalf("forged end composition result: %v", err)
			}
		})
	}
}

// Pick up the silver rune through the actual command and saved ECS state.
func collectVaultsSilverRune(t *testing.T, g *Game, end *Level,
	runeX, runeY int) {
	t.Helper()
	if actor, occupied := end.ActorAt(runeX, runeY); occupied {
		// The test clears the rune guard to exercise pickup directly. Its
		// equipment belongs to that guard and must leave the ECS as well.
		for _, item := range g.stores.CarriedBy.Entities() {
			carrier, _ := g.stores.CarriedBy.Get(item)

			if carrier.Holder == actor && !g.world.DestroyEntity(item) {
				t.Fatalf("remove rune guard item %d", item)
			}
		}

		if err := end.RemoveActor(actor); err != nil ||
			!g.world.DestroyEntity(actor) {
			t.Fatalf("remove rune guard: %v", err)
		}
	}

	if err := end.MoveActor(g.player, runeX, runeY); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	progress, found := g.scripts.Components()["character.runes"].Get(g.player)

	if !found {
		t.Fatal("player lost rune progress after pickup")
	}

	collectedRunes, err := progress.Get("collected")

	if err != nil {
		t.Fatal(err)
	}

	collectedMap, ok := collectedRunes.(map[string]any)

	if !ok || collectedMap["RUNE_VAULTS"] != true {
		t.Fatalf("silver rune was not collected: %#v", collectedRunes)
	}

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, onFloor := g.stores.Positions.Get(entity)

		if item.KindID == "RUNE_VAULTS" && onFloor &&
			position.LevelID == end.ID {
			t.Fatal("silver rune still lies on Vaults:5 after pickup")
		}
	}

	afterPickup := g.Snapshot()
	collected, err := Restore(afterPickup)

	if err != nil {
		t.Fatal(err)
	}

	defer collected.Close()

	if !reflect.DeepEqual(afterPickup, collected.Snapshot()) {
		t.Fatal("Vaults silver rune pickup changed across restore")
	}
}
