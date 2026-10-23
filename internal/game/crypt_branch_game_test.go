package game

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/vault"
)

// Follow the run's saved schedule through the real stair commands. Both
// tests use this route so their Crypt floor has an ordinary parent link.
func walkToCryptDepth(t *testing.T, g *Game, lastDepth int) (*Level, *Level) {
	t.Helper()

	vaultsParent := 0
	cryptParent := 0

	for _, entry := range g.branchSchedule.Entries {
		switch entry.BranchID {
		case "BRANCH_VAULTS":
			vaultsParent = entry.ParentDepth

		case "BRANCH_CRYPT":
			cryptParent = entry.ParentDepth
		}
	}

	if vaultsParent == 0 || cryptParent == 0 {
		t.Fatal("generated run has no Vaults and Crypt schedule")
	}

	descendGeneratedTo(t, g, vaultsParent)

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 10000
	health.Current = health.Max

	vaultsFloor := followBranch(t, g, g.levels[vaultsParent],
		"BRANCH_VAULTS")
	vaultsFloor = descendBranch(t, g, vaultsFloor, cryptParent)
	crypt := followBranch(t, g, vaultsFloor, "BRANCH_CRYPT")
	floor := descendBranch(t, g, crypt, lastDepth)

	return vaultsFloor, floor
}

// The saved branch schedule leads through Vaults to an authored Crypt gate.
// The same generated-floor path must then produce all three Crypt floors.
func TestCryptBranchTravelEndingAndSave(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	vaultsFloor, end := walkToCryptDepth(t, g, 3)

	endings := []string{
		"church_of_pain_bobbens",
		"cryptofortress_bobbens",
		"david_glass_crypt",
		"quadcrypt_mu",
		"evilmike_haunted_forest",
		"due_elkab",
		"grunt_crypt_end_deaths_head",
		"lightli_unholy_cathedral",
	}

	if end.BranchID != "BRANCH_CRYPT" ||
		end.LocalDepth != 3 ||
		!slices.Contains(endings, end.VaultID()) {
		t.Fatalf("Crypt end = %s:%d vault %s",
			end.BranchID, end.LocalDepth, end.VaultID())
	}

	tombLinks := 0
	var tomb StairLink

	for _, link := range end.StairLinks() {
		if link.TargetBranchID == "BRANCH_TOMB" {
			tombLinks++
			tomb = link
		}
	}

	if tombLinks != 1 {
		t.Fatalf("Crypt:3 has %d scheduled Tomb gates", tombLinks)
	}

	authored := 0

	for _, record := range end.VaultRecords() {
		if record.Kind == vault.KindFeature &&
			record.Identity == "enter_tomb" {
			authored++

			if record.X != tomb.X || record.Y != tomb.Y {
				t.Fatalf("authored Tomb gate (%d,%d) differs from link (%d,%d)",
					record.X, record.Y, tomb.X, tomb.Y)
			}
		}
	}

	if authored > 1 {
		t.Fatalf("Crypt:3 has %d authored Tomb gates", authored)
	}

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()

	if directory := os.Getenv("CRAWL_CRYPT_SNAPSHOT_DIR"); directory != "" {
		if err := writeCryptTextSnapshots(snapshot, vaultsFloor.ID,
			directory); err != nil {
			t.Fatal(err)
		}
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("restore Crypt:3: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Crypt map, links, or actors changed across restore")
	}
}

// A sparse same-path overlay can make one source ending dominant without
// changing the kernel or a central map registry. This tests the authored
// Tomb-gate binder on a complete generated Crypt:3 floor.
func TestCryptAuthoredTombGateFromSparseOverlay(t *testing.T) {
	const sourcePath = "../modfs/builtin/vaults/crypt_end/quadcrypt_mu.des"

	source, err := os.ReadFile(sourcePath)

	if err != nil {
		t.Fatal(err)
	}

	adjusted := strings.Replace(string(source),
		"NAME:   quadcrypt_mu\n",
		"NAME:   quadcrypt_mu\nWEIGHT: 100000\n", 1)

	if adjusted == string(source) {
		t.Fatal("source Quadcrypt NAME was not found")
	}

	rules := quadcryptOverlay(t, adjusted)

	g, err := NewDungeonGameWithRules(423,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, end := walkToCryptDepth(t, g, 3)

	if end.VaultID() != "quadcrypt_mu" {
		t.Fatalf("weighted sparse overlay selected %s", end.VaultID())
	}

	var tomb StairLink
	var links int

	for _, link := range end.StairLinks() {
		if link.TargetBranchID == "BRANCH_TOMB" {
			tomb = link
			links++
		}
	}

	if links != 1 {
		t.Fatalf("Quadcrypt has %d Tomb links", links)
	}

	var gates int

	for _, record := range end.VaultRecords() {
		if record.Kind == vault.KindFeature &&
			record.Identity == "enter_tomb" {
			gates++

			if record.X != tomb.X || record.Y != tomb.Y {
				t.Fatalf("Quadcrypt Tomb record (%d,%d) differs from link (%d,%d)",
					record.X, record.Y, tomb.X, tomb.Y)
			}
		}
	}

	if gates != 1 {
		t.Fatalf("Quadcrypt has %d authored Tomb gates", gates)
	}

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatalf("restore weighted Crypt ending: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("authored Tomb gate changed across restore")
	}
}

// A same-path overlay replaces only Quadcrypt's DES file. Both good and
// malformed variants therefore exercise the normal effective mod catalog.
func quadcryptOverlay(t *testing.T, content string) modfs.Ruleset {
	t.Helper()

	directory := t.TempDir()
	path := filepath.Join(directory, "vaults", "crypt_end",
		"quadcrypt_mu.des")

	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}

	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load(directory)

	if err != nil {
		t.Fatal(err)
	}

	return rules
}

// A malformed modded ending cannot consume the pending Crypt:3 stair or
// advance any saved RNG stream. The stair command owns the whole rollback.
func TestCryptMalformedEndingRollsBack(t *testing.T) {
	source, err := os.ReadFile(
		"../modfs/builtin/vaults/crypt_end/quadcrypt_mu.des")

	if err != nil {
		t.Fatal(err)
	}

	adjusted := strings.Replace(string(source),
		"NAME:   quadcrypt_mu\n",
		"NAME:   quadcrypt_mu\nWEIGHT: 100000\n", 1)
	adjusted = strings.Replace(adjusted,
		"KFEAT:  o = granite_statue",
		"KFEAT:  o = enter_tomb", 1)

	if !strings.Contains(adjusted, "KFEAT:  o = enter_tomb") {
		t.Fatal("Quadcrypt terrain override did not apply")
	}

	rules := quadcryptOverlay(t, adjusted)
	g, err := NewDungeonGameWithRules(423,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, parent := walkToCryptDepth(t, g, 2)
	health, _ := g.stores.Health.Get(g.player)

	health.Max = 18
	health.Current = 18

	for _, link := range parent.StairLinks() {
		if !link.Pending || link.TargetBranchID != "" {
			continue
		}

		if _, occupied := parent.ActorAt(link.X, link.Y); occupied {
			continue
		}

		if err := parent.MoveActor(g.player, link.X, link.Y); err != nil {
			t.Fatal(err)
		}

		// The test moved directly to the stair; update the view state that
		// an ordinary movement command would have saved before descent.
		if err := g.refreshVisibility(); err != nil {
			t.Fatal(err)
		}

		before := g.Snapshot()
		_, err := g.Step(Command{Kind: CommandDownstairs})

		if err == nil {
			t.Fatal("malformed Quadcrypt ending was accepted")
		}

		after := g.Snapshot()
		beforeJSON, err := json.Marshal(before)

		if err != nil {
			t.Fatal(err)
		}

		afterJSON, err := json.Marshal(after)

		if err != nil {
			t.Fatal(err)
		}

		if !bytes.Equal(beforeJSON, afterJSON) {
			t.Fatal("failed Crypt generation changed serialized game state")
		}

		return
	}

	t.Fatal("Crypt:2 has no free down stair")
}

// Probe different layout streams from one Crypt:2 parent. For each new ending,
// restore that parent and run the ordinary floor generation and population
// path, including its reciprocal stairs and saved ECS entities.
func TestCryptEveryEndingPopulates(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	_, parent := walkToCryptDepth(t, g, 2)
	var down StairLink

	for _, link := range parent.StairLinks() {
		if link.Pending && link.TargetBranchID == "" {
			down = link
			break
		}
	}

	if !down.Pending {
		t.Fatal("Crypt:2 has no staged Crypt:3 stair")
	}

	player, _ := g.stores.Players.Get(g.player)
	base := g.rng.States()["layout"]
	health, _ := g.stores.Health.Get(g.player)

	health.Max = 18
	health.Current = 18

	parentSnapshot := g.Snapshot()
	seen := make(map[string]string)

	for attempt := 0; attempt < 96 && len(seen) < 8; attempt++ {
		layoutSeed := base +
			uint64(attempt)*0x9e3779b97f4a7c15

		g.rng.states["layout"] = layoutSeed

		result, err := g.scripts.Policy("world.generate_next_floor",
			map[string]any{
				"branch_id":         "BRANCH_CRYPT",
				"local_depth":       int64(3),
				"level_id":          down.ToLevelID,
				"player_species_id": player.SpeciesID,
				"player_name":       player.Name,
				"from_x":            down.X,
				"from_y":            down.Y,
				"parent":            liveParentRecord(parent),
				"prior_vault_ids":   g.priorVaultIDs(),
				"branch_schedule":   luaBranchSchedule(g.branchSchedule),
				"temple_plan":       luaTemplePlan(g.templePlan),
			},
		)

		if err != nil {
			t.Fatalf("Crypt ending probe %d: %v", attempt, err)
		}

		record, ok := result["level"].(map[string]any)

		if !ok {
			t.Fatalf("Crypt ending probe %d has no level", attempt)
		}

		vaultID, ok := record["vault_id"].(string)

		if !ok || vaultID == "" {
			t.Fatalf("Crypt ending probe %d has no primary vault", attempt)
		}

		if _, found := seen[vaultID]; !found {
			staged, err := Restore(parentSnapshot)

			if err != nil {
				t.Fatal(err)
			}

			staged.rng.states["layout"] = layoutSeed

			stagedParent := staged.levels[parent.ID]
			generated, err := staged.generateNextFloor(parent.ID, down)

			if err != nil {
				staged.Close()
				t.Fatalf("Crypt ending %s generation: %v", vaultID, err)
			}

			resolved, found := stagedParent.StairAt(down.X, down.Y)

			if !found || resolved.Pending {
				staged.Close()
				t.Fatalf("Crypt ending %s has no paired parent stair", vaultID)
			}

			landing := point{
				x: resolved.ToX,
				y: resolved.ToY,
			}

			err = staged.populateGeneratedLevel(resolved.ToLevelID,
				landing, generated.items, true)

			if err != nil {
				staged.Close()
				t.Fatalf("Crypt ending %s population: %v", vaultID, err)
			}

			floor := staged.levels[down.ToLevelID]

			if floor == nil ||
				floor.BranchID != "BRANCH_CRYPT" ||
				floor.LocalDepth != 3 ||
				floor.VaultID() != vaultID {
				staged.Close()
				t.Fatalf("Crypt ending %s generated the wrong floor", vaultID)
			}

			snapshot := staged.Snapshot()
			levels := make(map[int]save.LevelRecord, len(snapshot.Levels))

			for _, record := range snapshot.Levels {
				levels[record.ID] = record
			}

			record := levels[floor.ID]

			seen[vaultID] = formatLevelTextSnapshot(record,
				levels) + "\nAuthored maps: " +
				strings.Join(record.VaultIDs, ", ") + "\n"
			staged.Close()
		}
	}

	if len(seen) != 8 {
		t.Fatalf("generated %d of eight Crypt endings", len(seen))
	}

	if directory := os.Getenv("CRAWL_CRYPT_SNAPSHOT_DIR"); directory != "" {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}

		var index strings.Builder

		index.WriteString("All eight source Crypt:3 endings, generated from one Crypt:2 parent.\n")

		ids := make([]string, 0, len(seen))

		for id := range seen {
			ids = append(ids, id)
		}

		slices.Sort(ids)

		for _, id := range ids {
			filename := "end_" + id + ".txt"

			if err := os.WriteFile(filepath.Join(directory, filename),
				[]byte(seen[id]), 0o644); err != nil {
				t.Fatal(err)
			}

			fmt.Fprintf(&index, "%s\n", id)
		}

		if err := os.WriteFile(filepath.Join(directory,
			"endings_index.txt"), []byte(index.String()), 0o644); err != nil {
			t.Fatal(err)
		}
	}
}

// Export actual generated grids and saved links when explicitly requested.
// The normal test path reads snapshots without rewriting committed examples.
func writeCryptTextSnapshots(
	snapshot save.Snapshot,
	parentID int,
	directory string,
) error {
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return err
	}

	levels := make(map[int]save.LevelRecord, len(snapshot.Levels))

	for _, level := range snapshot.Levels {
		levels[level.ID] = level
	}

	var index strings.Builder

	index.WriteString("Crypt branch generated floor snapshots\n")
	index.WriteString("Coordinates are zero-based; links are saved stair destinations.\n\n")

	for _, level := range snapshot.Levels {
		if level.BranchID != "BRANCH_CRYPT" && level.ID != parentID {
			continue
		}

		name := fmt.Sprintf("crypt_%d", level.LocalDepth)

		if level.ID == parentID {
			name = "vaults_crypt_entry"
		}

		body := formatLevelTextSnapshot(level, levels)
		body += "\nAuthored maps: " + strings.Join(level.VaultIDs, ", ") + "\n"

		if err := os.WriteFile(filepath.Join(directory, name+".txt"),
			[]byte(body), 0o644); err != nil {
			return err
		}

		summary := floorName(level)

		if level.VaultID != "" {
			summary += ", primary " + level.VaultID
		}

		fmt.Fprintf(&index, "%s: %s\n", name, summary)
	}

	return os.WriteFile(filepath.Join(directory, "index.txt"),
		[]byte(index.String()), 0o644)
}
