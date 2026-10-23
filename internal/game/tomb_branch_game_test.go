package game

import (
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/vault"
)

// Replacing only the Tomb:1 source map can remove its Crypt return stair.
// First entry must reject that graph and retain the exact pending gate.
func TestTombMalformedMapRollsBackFirstEntry(t *testing.T) {
	source, err := os.ReadFile("../modfs/builtin/vaults/tomb_1/tomb_1.des")

	if err != nil {
		t.Fatal(err)
	}

	bad := strings.Replace(string(source),
		"NSUBST:   ( = 1:( / *:.",
		"SUBST:    ( = .", 1)

	if bad == string(source) {
		t.Fatal("Tomb:1 return-stair directive was not replaced")
	}

	directory := t.TempDir()
	path := filepath.Join(directory, "vaults", "tomb_1", "tomb_1.des")

	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}

	if err := os.WriteFile(path, []byte(bad), 0o644); err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load(directory)

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(423,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, crypt := walkToCryptDepth(t, g, 3)
	health, _ := g.stores.Health.Get(g.player)

	health.Max = 18
	health.Current = 18

	for _, link := range crypt.StairLinks() {
		if link.TargetBranchID != "BRANCH_TOMB" {
			continue
		}

		moveGeneratedPlayerToStair(t, g, crypt, link)

		if err := g.refreshVisibility(); err != nil {
			t.Fatal(err)
		}

		before := g.Snapshot()
		_, err := g.Step(Command{Kind: CommandDownstairs})

		if err == nil {
			t.Fatal("malformed Tomb:1 entry succeeded")
		}

		if !strings.Contains(err.Error(), "Tomb:1 has no Crypt return stair") {
			t.Fatalf("malformed Tomb:1 entry = %v", err)
		}

		if !reflect.DeepEqual(before, g.Snapshot()) {
			t.Fatal("failed Tomb generation changed the saved run")
		}

		if g.levels[1401] != nil ||
			g.levels[1402] != nil ||
			g.levels[1403] != nil {
			t.Fatal("failed Tomb generation retained a staged floor")
		}

		return
	}

	t.Fatal("Crypt:3 has no scheduled Tomb gate")
}

// Probe the effective Lua builder with varied saved layout streams. Every
// source helper must fit its parent region and leave a valid hatch graph.
func TestTombEveryHelperBuilds(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	_, crypt := walkToCryptDepth(t, g, 3)
	player, _ := g.stores.Players.Get(g.player)
	var entrance StairLink

	for _, link := range crypt.StairLinks() {
		if link.TargetBranchID == "BRANCH_TOMB" {
			entrance = link
			break
		}
	}

	if !entrance.Pending {
		t.Fatal("Crypt:3 has no pending Tomb gate")
	}

	want := map[string]bool{
		"tomb_1_centre_old":                     true,
		"tomb_1_centre_grunt_parallel":          true,
		"tomb_1_centre_grunt_layered":           true,
		"tomb_1_centre_nicolae_necropolis":      true,
		"tomb_1_hall_stairs_old":                true,
		"tomb_1_hall_stairs_grunt_patterns":     true,
		"tomb_1_hall_stairs_grunt_snakey":       true,
		"tomb_1_hall_stairs_nicolae_cartouches": true,
		"tomb_1_hall_stairs_nicolae_galleries":  true,
		"tomb_2_ambush_old":                     true,
		"tomb_2_ambush_grunt_patterns":          true,
		"tomb_2_ambush_grunt_arcs":              true,
		"tomb_2_ambush_grunt_hexed":             true,
		"tomb_3_rune_old":                       true,
		"tomb_3_rune_grunt_curves":              true,
		"tomb_3_rune_grunt_snapback":            true,
		"tomb_3_rune_grunt_layered":             true,
		"tomb_3_rune_grunt_doroklohe":           true,
	}

	seen := make(map[string]bool, len(want))

	for attempt := uint64(1); attempt <= 80 && len(seen) < len(want); attempt++ {
		layoutState := attempt * 7919

		g.rng.states["layout"] = layoutState

		result, err := g.scripts.Policy("world.generate_next_floor", map[string]any{
			"branch_id":         "BRANCH_TOMB",
			"local_depth":       int64(1),
			"level_id":          entrance.ToLevelID,
			"player_species_id": player.SpeciesID,
			"player_name":       player.Name,
			"from_x":            entrance.X,
			"from_y":            entrance.Y,
			"parent":            liveParentRecord(crypt),
			"prior_vault_ids":   g.priorVaultIDs(),
			"branch_schedule":   luaBranchSchedule(g.branchSchedule),
			"temple_plan":       luaTemplePlan(g.templePlan),
		})

		if err != nil {
			t.Fatalf("Tomb helper draw %d: %v", attempt, err)
		}

		records, ok := result["levels"].([]any)

		if !ok || len(records) != 3 {
			t.Fatalf("Tomb helper draw %d returned %d floors", attempt,
				len(records))
		}

		for _, value := range records {
			floor := value.(map[string]any)
			ids, ok := floor["vault_ids"].([]any)

			if !ok {
				t.Fatalf("Tomb helper draw %d lost vault IDs", attempt)
			}

			for _, raw := range ids {
				id := raw.(string)

				if want[id] {
					seen[id] = true
				}
			}
		}
	}

	for id := range want {
		if !seen[id] {
			t.Errorf("Tomb helper %s was never selected", id)
		}
	}
}

// Snapshot the actual saved floor grids and every source hatch identity.
// The files are generated explicitly, then reviewed and committed as docs.
func writeTombTextSnapshots(snapshot save.Snapshot, directory string) error {
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return err
	}

	levels := make(map[int]save.LevelRecord, len(snapshot.Levels))

	for _, level := range snapshot.Levels {
		levels[level.ID] = level
	}

	var index strings.Builder

	index.WriteString("Tomb source floor snapshots\n")
	index.WriteString("Coordinates are zero-based; named hatches are one-way.\n\n")

	for _, level := range snapshot.Levels {
		if level.BranchID != "BRANCH_TOMB" {
			continue
		}

		name := fmt.Sprintf("tomb_%d", level.LocalDepth)
		body := formatLevelTextSnapshot(level, levels)
		body += "\nAuthored maps: " + strings.Join(level.VaultIDs, ", ") + "\n"
		body += "Named hatch markers:\n"

		for _, record := range level.VaultRecords {
			if record.Kind == vault.KindItem && runeRecord(record, "RUNE_TOMB") {
				fmt.Fprintf(&index, "%s golden rune at (%d,%d)\n",
					name, record.X, record.Y)
				body += fmt.Sprintf("Golden rune: (%d,%d)\n",
					record.X, record.Y)
			}

			if record.Kind != vault.KindMarker {
				continue
			}

			var hatchName string
			var hatchKind string

			for _, argument := range record.Arguments {
				switch argument.Name {
				case "hatch_name":
					hatchName = argument.String

				case "hatch_kind":
					hatchKind = argument.String
				}
			}

			active := hatchKind == "dest"

			if hatchKind == "name" {
				for _, link := range level.Stairs {
					if link.X == record.X && link.Y == record.Y {
						active = true
						break
					}
				}
			}

			if hatchName != "" && active {
				fmt.Fprintf(&index, "%s %s %s at (%d,%d)\n",
					name, hatchKind, hatchName, record.X, record.Y)
				body += fmt.Sprintf("  %s %s at (%d,%d)\n",
					hatchKind, hatchName, record.X, record.Y)
			}
		}

		if err := os.WriteFile(filepath.Join(directory, name+".txt"),
			[]byte(body), 0o644); err != nil {
			return err
		}

		fmt.Fprintf(&index, "%s: %s\n", name, floorName(level))
	}

	return os.WriteFile(filepath.Join(directory, "index.txt"),
		[]byte(index.String()), 0o644)
}

// Choose a source hatch by destination rather than by its map coordinate.
// The DES helpers can rotate, but the typed stair links must keep their route.
func followTombHatch(t *testing.T, g *Game, level *Level,
	destination int) *Level {
	t.Helper()

	for _, link := range level.StairLinks() {
		if link.ToLevelID != destination || link.Pending {
			continue
		}

		moveGeneratedPlayerToStair(t, g, level, link)
		command := CommandDownstairs

		if destination < level.ID {
			command = CommandUpstairs
		}

		result, err := g.Step(Command{Kind: command})

		if err != nil {
			t.Fatal(err)
		}

		if result.View.LevelID != destination {
			t.Fatalf("Tomb hatch %+v arrived at %d", link,
				result.View.LevelID)
		}

		return g.levels[destination]
	}

	t.Fatalf("Tomb level %d has no route to %d", level.ID, destination)

	return nil
}

// A scheduled Crypt gate must install all three named-hatch floors before
// moving the player, because Tomb:1 can lead directly to a Tomb:2 landing.
func TestTombBranchStagesCompleteRoute(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	_, crypt := walkToCryptDepth(t, g, 3)
	health, _ := g.stores.Health.Get(g.player)

	fullHealth := 18

	health.Max = fullHealth
	health.Current = fullHealth

	first := followBranch(t, g, crypt, "BRANCH_TOMB")

	if first.ID != 1401 {
		t.Fatalf("entered level %d, want Tomb:1", first.ID)
	}

	for depth := 1; depth <= 3; depth++ {
		level := g.levels[1400+depth]

		if level == nil {
			t.Fatalf("Tomb:%d was not staged", depth)
		}

		if len(level.StairLinks()) == 0 {
			t.Fatalf("Tomb:%d has no named-hatch links", depth)
		}
	}

	runes := 0
	runeX, runeY := 0, 0

	for _, record := range g.levels[1403].VaultRecords() {
		if record.Kind == vault.KindItem && runeRecord(record, "RUNE_TOMB") {
			runes++
			runeX, runeY = record.X, record.Y
		}
	}

	if runes != 1 {
		t.Fatalf("Tomb:3 has %d authored golden runes", runes)
	}

	snapshot := g.Snapshot()

	if directory := os.Getenv("CRAWL_TOMB_SNAPSHOT_DIR"); directory != "" {
		if err := writeTombTextSnapshots(snapshot, directory); err != nil {
			t.Fatal(err)
		}
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("restore staged Tomb: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Tomb bundle changed across save/restore")
	}

	health.Max = 10000
	health.Current = health.Max

	second := followTombHatch(t, g, first, 1402)
	third := followTombHatch(t, g, second, 1403)
	collectRune(t, g, third, runeX, runeY, "RUNE_TOMB")
	second = followTombHatch(t, g, third, 1402)
	first = followTombHatch(t, g, second, 1401)
	_ = followTombHatch(t, g, first, crypt.ID)
}
