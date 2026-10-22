package game

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/save"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// The saved ECS field, rather than the shared arch glyph, tells whether
// the gate closed because a visitor entered or because its clock expired.
func baileyClosureReason(t *testing.T, g *Game) string {
	t.Helper()

	for _, entity := range g.Snapshot().Entities {
		for _, part := range entity.Dynamic {
			if part.Schema != "world.bailey_portal" {
				continue
			}

			var reason string

			if err := json.Unmarshal(part.Values["closure_reason"], &reason); err != nil {
				t.Fatal(err)
			}

			return reason
		}
	}

	t.Fatal("Bailey portal entity has no saved clock")

	return ""
}

// The source marker and its ECS clock agree on one theme and one duration.
// A real Dungeon population creates the same pair at the chosen gate cell.
func placeBaileyPortalForTest(t *testing.T, g *Game) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterBailey)
	level := g.levels[1]
	identity := `lua:timed_marker { low = 600, high = 600, ` +
		`bailey_type = "axe", single_timed = true, floor = "stone_arch" }`

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: "enter_bailey_1",
		Identity: identity,
		X:        site.x,
		Y:        site.y,
	}); err != nil {
		t.Fatal(err)
	}

	if err := level.SetVaultIDs(append(level.VaultIDs(), "enter_bailey_1")); err != nil {
		t.Fatal(err)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.bailey_portal"]

	if store == nil {
		t.Fatal("Bailey ECS clock schema is missing")
	}

	if _, err := store.Set(entity, map[string]any{
		"level_id":        int64(1),
		"x":               int64(site.x),
		"y":               int64(site.y),
		"vault_id":        "enter_bailey_1",
		"record_index":    int64(len(level.vaultRecords)),
		"theme":           "axe",
		"duration_turns":  int64(600),
		"created_aut":     int64(g.currentAut),
		"expires_aut":     int64(g.currentAut) + 6000,
		"spent":           false,
		"closure_reason":  "",
		"announced":       false,
		"next_notice_aut": int64(g.currentAut) + 500,
		"final_warning":   false,
	}); err != nil {
		t.Fatal(err)
	}

	return site
}

// Entry and return cross the actual staged transaction and save format.
func TestBaileyEntrySaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 88142)
	origin := placeBaileyPortalForTest(t, g)

	restoredOutside, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("unspent Bailey gate did not restore: %v", err)
	}

	g = restoredOutside

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]

	if floor == nil ||
		floor.BranchID != "BRANCH_BAILEY" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatalf("Bailey entry lost its floor or gate: %+v", position)
	}

	if reason := baileyClosureReason(t, g); reason != "entry" {
		t.Fatalf("entered Bailey gate closure reason = %q", reason)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("Bailey visit did not restore: %v", err)
	}

	g = restored
	position, _ = g.stores.Positions.Get(g.player)
	floor = g.levels[position.LevelID]

	for y, row := range floor.Cells() {
		for x, feature := range row {
			if feature != terrain.ExitBailey {
				continue
			}

			if err := floor.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			floorID := floor.ID

			if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
				t.Fatal(err)
			}

			position, _ = g.stores.Positions.Get(g.player)

			if position.LevelID != 1 ||
				position.X != origin.x ||
				position.Y != origin.y ||
				g.levels[floorID] != nil {
				t.Fatalf("Bailey did not return and retire: %+v", position)
			}

			if _, err := Restore(g.Snapshot()); err != nil {
				t.Fatalf("completed Bailey visit did not restore: %v", err)
			}

			return
		}
	}

	t.Fatal("Bailey destination has no return arch")
}

// A failed staging check cannot spend the gate or consume a random draw.
func TestBaileyRejectedStagedMapRollsBack(t *testing.T) {
	g := newGeneratedTestGame(t, 88143)
	placeBaileyPortalForTest(t, g)
	position, _ := g.stores.Positions.Get(g.player)
	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.bailey.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_bailey_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"theme":       "axe",
		},
		"expected_branch_id": "BRANCH_BAILEY",
		"expected_level_id":  int64(999999),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil {
		t.Fatal("rejected Bailey map was accepted")
	}

	afterState := g.Snapshot()

	afterState.EntityCursor = beforeState.EntityCursor

	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("rejected Bailey map changed saved state")
	}
}

// Time advances on other floors; the saved gate must close at its deadline.
func TestBaileyGateExpiresOnInactiveFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 88144)
	origin := placeBaileyPortalForTest(t, g)
	descendGeneratedTo(t, g, 2)
	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatal("inactive Bailey gate survived its deadline")
	}

	if reason := baileyClosureReason(t, g); reason != "expiry" {
		t.Fatalf("expired Bailey gate closure reason = %q", reason)
	}

}

// Accepted travel on the final valid action finishes before expiry runs.
func TestBaileyGateAllowsTravelAtDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88145)
	placeBaileyPortalForTest(t, g)
	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_BAILEY" {
		t.Fatalf("accepted Bailey entry lost deadline travel: %+v", position)
	}
}

// The source marker is independent evidence of the chosen theme and fixed
// deadline. A save cannot redirect the destination by editing the ECS gate.
func TestBaileyRestoreRejectsForgedGate(t *testing.T) {
	for _, changedField := range []struct {
		name  string
		value json.RawMessage
	}{
		{
			name:  "theme",
			value: json.RawMessage(`"polearm"`),
		},

		{
			name:  "missing theme",
			value: json.RawMessage(`""`),
		},

		{
			name:  "expires_aut",
			value: json.RawMessage(`7000`),
		},
	} {
		t.Run(changedField.name, func(t *testing.T) {
			g := newGeneratedTestGame(t, 88146)
			placeBaileyPortalForTest(t, g)
			changed := g.Snapshot()

			for entityIndex := range changed.Entities {
				for partIndex := range changed.Entities[entityIndex].Dynamic {
					entry := &changed.Entities[entityIndex].Dynamic[partIndex]

					if entry.Schema == "world.bailey_portal" {
						entry.Values[changedField.name] = changedField.value
					}
				}
			}

			if _, err := Restore(changed); err == nil ||
				!strings.Contains(strings.ToLower(err.Error()), "bailey") {
				t.Fatalf("forged Bailey %s was accepted: %v", changedField.name, err)
			}
		})
	}
}

// The return site is exact; an occupant leaves the temporary floor active
// and the stair command free, so the visitor can try again later.
func TestBaileyReturnWaitsForExactOutsideCell(t *testing.T) {
	g := newGeneratedTestGame(t, 88147)
	origin := placeBaileyPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]
	blocker := spawnWormForTest(t, g, 1)

	if err := g.levels[1].MoveActor(blocker, origin.x, origin.y); err != nil {
		t.Fatal(err)
	}

	for y, row := range floor.Cells() {
		for x, feature := range row {
			if feature != terrain.ExitBailey {
				continue
			}

			if err := floor.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			beforeState := g.Snapshot()
			before, err := json.Marshal(beforeState)

			if err != nil {
				t.Fatal(err)
			}

			result, err := g.Step(Command{Kind: CommandUpstairs})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent != 0 || g.levels[floor.ID] == nil {
				t.Fatalf("blocked Bailey return changed the visit: %+v, %v", result, err)
			}

			afterState := g.Snapshot()

			// The refusal message is expected; world state must not change.
			afterState.Messages = beforeState.Messages

			after, err := json.Marshal(afterState)

			if err != nil {
				t.Fatal(err)
			}

			if !bytes.Equal(before, after) {
				t.Fatal("blocked Bailey return changed saved session state")
			}

			return
		}
	}

	t.Fatal("Bailey destination has no return arch")
}

// A selected child must remain tagged for the theme stored on the visitor.
// The dispatcher history and usable exit are reciprocal layout evidence.
func TestBaileyRestoreRejectsChangedFloor(t *testing.T) {
	for _, change := range []struct {
		name string
		edit func(*save.LevelRecord)
	}{
		{
			name: "missing dispatcher",
			edit: func(level *save.LevelRecord) {
				level.VaultIDs = []string{level.VaultID}
			},
		},

		{
			name: "missing exit",
			edit: func(level *save.LevelRecord) {
				for y, row := range level.Cells {
					for x, feature := range row {
						if feature == terrain.ExitBailey {
							level.Cells[y][x] = terrain.Floor
						}
					}
				}
			},
		},
	} {
		t.Run(change.name, func(t *testing.T) {
			g := newGeneratedTestGame(t, 88148)
			placeBaileyPortalForTest(t, g)

			if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
				t.Fatal(err)
			}

			changed := g.Snapshot()

			for index := range changed.Levels {
				if changed.Levels[index].BranchID == "BRANCH_BAILEY" {
					change.edit(&changed.Levels[index])
				}
			}

			if _, err := Restore(changed); err == nil {
				t.Fatal("forged Bailey floor was accepted")
			}
		})
	}
}

// A changed grid or removed source marker must not be repaired from an
// otherwise plausible ECS clock during restore.
func TestBaileyRestoreRejectsChangedEntrance(t *testing.T) {
	for _, change := range []struct {
		name string
		edit func(*save.LevelRecord, point)
	}{
		{
			name: "missing marker",
			edit: func(level *save.LevelRecord, _ point) {
				level.VaultRecords = level.VaultRecords[:len(level.VaultRecords)-1]
			},
		},

		{
			name: "changed gate cell",
			edit: func(level *save.LevelRecord, site point) {
				level.Cells[site.y][site.x] = terrain.Floor
			},
		},
	} {
		t.Run(change.name, func(t *testing.T) {
			g := newGeneratedTestGame(t, 88149)
			site := placeBaileyPortalForTest(t, g)
			changed := g.Snapshot()

			for index := range changed.Levels {
				if changed.Levels[index].ID == 1 {
					change.edit(&changed.Levels[index], site)
				}
			}

			if _, err := Restore(changed); err == nil {
				t.Fatal("forged Bailey entrance was accepted")
			}
		})
	}
}

// A visitor's selected theme and outside coordinate must agree with both
// the saved child and the one spent source gate.
func TestBaileyRestoreRejectsChangedVisit(t *testing.T) {
	for _, change := range []struct {
		name  string
		field string
		value json.RawMessage
	}{
		{
			name:  "wrong child theme",
			field: "theme",
			value: json.RawMessage(`"polearm"`),
		},

		{
			name:  "wrong outside cell",
			field: "origin_x",
			value: json.RawMessage(`1`),
		},
	} {
		t.Run(change.name, func(t *testing.T) {
			g := newGeneratedTestGame(t, 88150)
			placeBaileyPortalForTest(t, g)

			if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
				t.Fatal(err)
			}

			changed := g.Snapshot()

			for entityIndex := range changed.Entities {
				for partIndex := range changed.Entities[entityIndex].Dynamic {
					entry := &changed.Entities[entityIndex].Dynamic[partIndex]

					if entry.Schema == "character.bailey_visit" {
						entry.Values[change.field] = change.value
					}
				}
			}

			if _, err := Restore(changed); err == nil {
				t.Fatal("forged Bailey visit was accepted")
			}
		})
	}
}

// Every themed destination must survive the real staged floor and entity
// population path. A DES map that parses but loses its exit is not playable.
func TestBaileyAllSourceMapsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/bailey")

	if err != nil {
		t.Fatal(err)
	}

	g := newGeneratedTestGame(t, 88141)
	count := 0
	directory := os.Getenv("CRAWL_BAILEY_SNAPSHOT_DIR")
	var index strings.Builder
	var returnSite point

	if directory != "" {
		returnSite = placeBaileyPortalForTest(t, g)

		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}

		index.WriteString("Bailey source layouts, seed 88141\n")
		index.WriteString("Coordinates are zero-based: (x,y), origin at top left.\n")
		index.WriteString("The connection uses a Dungeon:1 test gate; live Bailey entrances spawn on D:7–10.\n\n")
	}

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")

		if id == "bailey" {
			continue
		}

		count++

		t.Run(id, func(t *testing.T) {
			theme := "axe"

			if strings.Contains(id, "polearm") {
				theme = "polearm"
			}

			stage, err := g.stageGeneratedLevel(
				"world.generate_bailey_level",
				map[string]any{
					"species_id":  "SP_HUMAN",
					"player_name": "Tester",
					"layout_id":   id,
					"theme":       theme,
				},
			)

			if err != nil {
				t.Fatal(err)
			}

			defer func() {
				if err := stage.rollback(); err != nil {
					t.Error(err)
				}
			}()

			floor := g.levels[stage.levelID]

			if floor == nil ||
				floor.BranchID != "BRANCH_BAILEY" ||
				floor.VaultID() != id ||
				len(floor.VaultRecords()) == 0 {
				t.Fatalf("populated Bailey %s lost its source records", id)
			}

			exits := 0
			firstExit := point{}

			for y, row := range floor.Cells() {
				for x, cell := range row {
					if cell == terrain.ID("DNGN_EXIT_BAILEY") {
						if exits == 0 {
							firstExit = point{
								x: x,
								y: y,
							}
						}

						exits++
					}
				}
			}

			if exits == 0 {
				t.Fatalf("populated Bailey %s has no return exit", id)
			}

			if directory != "" {
				var record save.LevelRecord

				for _, candidate := range g.Snapshot().Levels {
					if candidate.ID == floor.ID {
						record = candidate
						break
					}
				}

				body := formatLevelTextSnapshot(record, nil)
				connection := fmt.Sprintf(
					"Bailey exit (%d,%d) -> Dungeon:1 (%d,%d), exact outside gate\n",
					firstExit.x, firstExit.y, returnSite.x, returnSite.y,
				)
				body += connection
				name := id + ".txt"

				if err := os.WriteFile(filepath.Join(directory, name),
					[]byte(body), 0o644); err != nil {
					t.Fatal(err)
				}

				fmt.Fprintf(&index, "%s  %s  %s", theme, name, connection)
			}
		})
	}

	if count != 15 {
		t.Fatalf("expected 15 source Bailey layouts, got %d", count)
	}

	if directory != "" {
		if err := os.WriteFile(filepath.Join(directory, "index.txt"),
			[]byte(index.String()), 0o644); err != nil {
			t.Fatal(err)
		}
	}
}
