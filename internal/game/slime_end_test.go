package game

import (
	"encoding/json"
	"reflect"
	"testing"

	"crawl/internal/save"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Restore must reject a changed authored floor even when the current
// player has not yet looked at the forged cell or rune history.
func rejectSlimeSave(t *testing.T, g *Game, end *Level,
	change func(*save.LevelRecord)) {
	t.Helper()

	forged := g.Snapshot()

	for index := range forged.Levels {
		if forged.Levels[index].ID == end.ID {
			change(&forged.Levels[index])
			break
		}
	}

	loaded, err := Restore(forged)

	if loaded != nil {
		_ = loaded.Close()
	}

	if err == nil {
		t.Fatal("forged Slime end save was accepted")
	}
}

// The authored end's return stair must lead to the exact parent cell,
// then that parent link must return to the same Slime:5 landing.
func assertSlimeReturn(t *testing.T, g *Game, end, parent *Level) {
	t.Helper()

	var ascent StairLink

	for _, link := range end.StairLinks() {
		if link.ToLevelID == parent.ID && link.Unavailable == "" {
			if _, occupied := end.ActorAt(link.X, link.Y); !occupied {
				ascent = link
				break
			}
		}
	}

	if ascent.ToLevelID != parent.ID {
		t.Fatal("Slime:5 has no free return stair")
	}

	if err := end.MoveActor(g.player, ascent.X, ascent.Y); err != nil {
		t.Fatal(err)
	}

	blocker, occupied := parent.ActorAt(ascent.ToX, ascent.ToY)
	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil || up.View.LevelID != parent.ID {
		t.Fatalf("Slime return level = %d, %v",
			up.View.LevelID, err)
	}

	if !occupied && (up.View.PlayerX != ascent.ToX ||
		up.View.PlayerY != ascent.ToY) {
		t.Fatalf("free return stair landed at (%d,%d), want (%d,%d)",
			up.View.PlayerX, up.View.PlayerY,
			ascent.ToX, ascent.ToY)
	}

	if occupied {
		// A monster may have stepped onto the linked stair while the
		// player was away. Move it aside only to exercise the reciprocal
		// descent after verifying the live rule landed beside it.
		if up.View.PlayerX == ascent.ToX &&
			up.View.PlayerY == ascent.ToY {
			t.Fatal("return landed on the occupied stair")
		}

		moved := false

		for y := 1; y < len(parent.terrain)-1 && !moved; y++ {
			for x := 1; x < parent.width-1; x++ {
				if parent.Walkable(x, y) {
					if _, taken := parent.ActorAt(x, y); !taken {
						if err := parent.MoveActor(blocker, x, y); err != nil {
							t.Fatal(err)
						}

						moved = true
						break
					}
				}
			}
		}

		if !moved {
			t.Fatal("no free cell to clear the reciprocal stair")
		}

		if err := parent.MoveActor(g.player,
			ascent.ToX, ascent.ToY); err != nil {
			t.Fatal(err)
		}
	}

	down, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil || down.View.LevelID != end.ID ||
		down.View.PlayerX != ascent.X ||
		down.View.PlayerY != ascent.Y {
		t.Fatalf("Slime reciprocal descent = %d:(%d,%d), %v",
			down.View.LevelID, down.View.PlayerX,
			down.View.PlayerY, err)
	}
}

// Follow ordinary scheduled stairs from Dungeon through Lair and Slime.
// This exercises the same first-entry generation that a player reaches.
func TestSlimePitRoyalJellySealAndRune(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	lairParent := 0
	slimeParent := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			lairParent = entry.ParentDepth
		}

		if entry.BranchID == "BRANCH_SLIME" {
			slimeParent = entry.ParentDepth
		}
	}

	if lairParent == 0 || slimeParent == 0 {
		t.Fatal("generated run has no scheduled Slime route")
	}

	descendGeneratedTo(t, g, lairParent)

	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[lairParent], "BRANCH_LAIR")
	lair = descendBranch(t, g, lair, slimeParent)
	slime := followBranch(t, g, lair, "BRANCH_SLIME")
	parent := descendBranch(t, g, slime, 4)
	end := descendBranch(t, g, parent, 5)

	if end.BranchID != "BRANCH_SLIME" || end.LocalDepth != 5 ||
		end.VaultID() != "slime_pit" {
		t.Fatalf("Slime end identity = %s:%d %s",
			end.BranchID, end.LocalDepth, end.VaultID())
	}

	walls := 0
	runes := 0
	runeX, runeY := 0, 0

	for _, record := range end.VaultRecords() {
		if record.Kind == vault.KindMarker &&
			record.SourceID == "slime_pit" &&
			record.Identity == "slime_seal_wall" {
			walls++

			if end.Cells()[record.Y][record.X] !=
				terrain.ClearStoneWall {
				t.Fatal("source Slime seal wall is absent at entry")
			}
		}

		if runeRecord(record, "RUNE_SLIME") {
			runes++
			runeX = record.X
			runeY = record.Y
		}
	}

	if walls == 0 || runes != 1 {
		t.Fatalf("Slime:5 has %d source walls and %d runes",
			walls, runes)
	}

	seals := g.scripts.Components()["world.slime_seal"]

	if len(seals.Entities()) != walls {
		t.Fatalf("Slime:5 has %d ECS seals for %d source walls",
			len(seals.Entities()), walls)
	}

	health.Max = 18
	health.Current = 18

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatalf("sealed Slime save: %v", err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("sealed Slime floor changed across restore")
	}

	royalJelly := g.player

	for _, entity := range g.stores.Actors.Entities() {
		actor, _ := g.stores.Actors.Get(entity)
		position, placed := g.stores.Positions.Get(entity)

		if placed && position.LevelID == end.ID &&
			actor.KindID == "MONS_ROYAL_JELLY" {
			royalJelly = entity
			break
		}
	}

	if royalJelly == g.player {
		t.Fatal("Slime Pit has no Royal Jelly")
	}

	jellyHealth, _ := g.stores.Health.Get(royalJelly)
	jellyHealth.Current = 0
	health.Max = 10000
	health.Current = health.Max

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatalf("Royal Jelly death: %v", err)
	}

	cells := end.Cells()

	for _, record := range end.VaultRecords() {
		if record.Kind == vault.KindMarker &&
			record.SourceID == "slime_pit" &&
			record.Identity == "slime_seal_wall" &&
			cells[record.Y][record.X] != terrain.Floor {
			t.Fatalf("Slime seal cell (%d,%d) did not fall",
				record.X, record.Y)
		}
	}

	health.Max = 18
	health.Current = 18

	released := g.Snapshot()
	reopened, err := Restore(released)

	if err != nil {
		t.Fatalf("released Slime save: %v", err)
	}

	defer reopened.Close()

	if !reflect.DeepEqual(released, reopened.Snapshot()) {
		t.Fatal("released Slime floor changed across restore")
	}

	rejectSlimeSave(t, g, end, func(floor *save.LevelRecord) {
		floor.VaultID = "layout_caves"
	})

	rejectSlimeSave(t, g, end, func(floor *save.LevelRecord) {
		for _, record := range floor.VaultRecords {
			if runeRecord(record, "RUNE_SLIME") {
				floor.VaultRecords = append(floor.VaultRecords, record)
				return
			}
		}

		t.Fatal("Slime rune record is absent from the save")
	})

	rejectSlimeSave(t, g, end, func(floor *save.LevelRecord) {
		for _, record := range floor.VaultRecords {
			if runeRecord(record, "RUNE_SLIME") {
				record.SourceID = "layout_caves"
				floor.VaultRecords = append(floor.VaultRecords, record)
				return
			}
		}

		t.Fatal("Slime rune record is absent from the save")
	})

	rejectSlimeSave(t, g, end, func(floor *save.LevelRecord) {
		for _, record := range floor.VaultRecords {
			if record.Kind == vault.KindMarker &&
				record.Identity == "slime_seal_wall" {
				floor.Cells[record.Y][record.X] = terrain.ClearStoneWall
				return
			}
		}

		t.Fatal("Slime source seal marker is absent from the save")
	})

	// Erasing a marker identity with its ECS component must still fail:
	// the effective DES map, rather than the mutable save, owns these cells.
	forged := g.Snapshot()
	removedIndex := 0

	for floorIndex := range forged.Levels {
		floor := &forged.Levels[floorIndex]

		if floor.ID != end.ID {
			continue
		}

		for index := len(floor.VaultRecords) - 1; index >= 0; index-- {
			record := floor.VaultRecords[index]

			if record.Kind == vault.KindMarker &&
				record.Identity == "slime_seal_wall" {
				removedIndex = index + 1
				floor.VaultRecords[index].Identity = "slime_removed_marker"
				break
			}
		}
	}

	if removedIndex == 0 {
		t.Fatal("Slime save has no seal marker to remove")
	}

	removedComponent := false

	for entityIndex := range forged.Entities {
		entity := &forged.Entities[entityIndex]

		for componentIndex, dynamic := range entity.Dynamic {
			if dynamic.Schema != "world.slime_seal" {
				continue
			}

			var index int

			if err := json.Unmarshal(dynamic.Values["record_index"], &index); err != nil {
				t.Fatal(err)
			}

			if index == removedIndex {
				entity.Dynamic = append(
					entity.Dynamic[:componentIndex],
					entity.Dynamic[componentIndex+1:]...)
				removedComponent = true
				break
			}
		}
	}

	if !removedComponent {
		t.Fatal("Slime save has no seal component to remove")
	}

	missing, err := Restore(forged)

	if missing != nil {
		_ = missing.Close()
	}

	if err == nil {
		t.Fatal("removed Slime marker and component were accepted")
	}

	health.Max = 10000
	health.Current = health.Max
	assertSlimeReturn(t, g, end, parent)

	collectRune(t, g, end, runeX, runeY, "RUNE_SLIME")
}
