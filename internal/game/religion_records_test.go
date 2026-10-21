package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Use one sparse Lua probe for both authored and generated altar records.
func newReligionRecordsGame(t *testing.T, seed uint64) (*Game, modfs.Ruleset) {
	t.Helper()

	rules, err := modfs.Load("testdata/religion-record-probe")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		seed,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	return g, rules
}

// The Lua context sees typed records at the player's coordinate, including
// the saved god ID. A generic grid query must not invent religious meaning.
func TestLuaRecordsAtReturnsTypedAltar(t *testing.T) {
	g, _ := newReligionRecordsGame(t, 41)

	defer g.Close()

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := g.levels[position.LevelID]

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindSourceFeature,
		SourceID: "test_altar",
		Identity: string(terrain.Altar),
		X:        position.X,
		Y:        position.Y,
		Arguments: []vault.Argument{
			{
				Name:   "god_id",
				Kind:   vault.ValueString,
				String: "GOD_ZIN",
			},
		},
	}); err != nil {
		t.Fatal(err)
	}

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: "test_marker",
		Identity: "typed_marker",
		X:        position.X,
		Y:        position.Y,
		Arguments: []vault.Argument{
			{
				Name: "lit",
				Kind: vault.ValueBool,
				Bool: true,
			},

			{
				Name: "rank",
				Kind: vault.ValueInt,
				Int:  7,
			},
		},
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.scripts.Policy("test.records_at", map[string]any{
		"level_id":   position.LevelID,
		"x":          position.X,
		"y":          position.Y,
		"probe_copy": true,
	})

	if err != nil {
		t.Fatal(err)
	}

	records, ok := result["records"].([]any)

	if !ok || len(records) != 2 {
		t.Fatalf("Lua records at altar = %v", result["records"])
	}

	record, ok := records[0].(map[string]any)

	if !ok {
		t.Fatalf("Lua altar record = %T", records[0])
	}

	arguments, ok := record["arguments"].(map[string]any)

	if !ok {
		t.Fatalf("Lua altar arguments = %T", record["arguments"])
	}

	if record["identity"] != string(terrain.Altar) {
		t.Fatalf("Lua altar identity = %v", record)
	}

	if arguments["god_id"] != "GOD_ZIN" {
		t.Fatalf("Lua altar identity = %v", record)
	}

	marker, ok := records[1].(map[string]any)

	if !ok {
		t.Fatalf("Lua marker record = %T", records[1])
	}

	markerArguments, ok := marker["arguments"].(map[string]any)

	if !ok {
		t.Fatalf("Lua marker arguments = %T", marker["arguments"])
	}

	if markerArguments["lit"] != true {
		t.Fatalf("Lua marker bool = %v", markerArguments["lit"])
	}

	if markerArguments["rank"] != int64(7) {
		t.Fatalf("Lua marker int = %v", markerArguments["rank"])
	}

	neighbor, err := g.scripts.Policy("test.records_at", map[string]any{
		"level_id": position.LevelID,
		"x":        position.X + 1,
		"y":        position.Y,
	})

	if err != nil {
		t.Fatal(err)
	}

	if neighbor["count"] != int64(0) {
		t.Fatalf("neighbor inherited altar record: %v", neighbor)
	}
}

// The generated Temple has no hard-coded altar god in Go. Lua reads the god
// bound during generation, and the same query survives a Go save round trip.
func TestLuaTempleAltarRecordRestores(t *testing.T) {
	g, rules := newReligionRecordsGame(t, 423)
	defer g.Close()

	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_TEMPLE" {
			parentDepth = entry.ParentDepth
		}
	}

	if parentDepth == 0 {
		t.Fatal("Temple has no scheduled entrance")
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

	if entrance.ToLevelID == 0 {
		t.Fatal("Temple entrance has no destination")
	}

	if err := parent.MoveActor(g.player, entrance.X, entrance.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	temple := g.levels[entrance.ToLevelID]
	var altar vault.Record

	for _, record := range temple.VaultRecords() {
		if record.Kind == vault.KindSourceFeature &&
			record.Identity == "DNGN_RANDOM_ALTAR" {
			altar = record
			break
		}
	}

	if altar.SourceID == "" {
		t.Fatal("Temple has no assigned altar record")
	}

	query := map[string]any{
		"level_id": temple.ID,
		"x":        altar.X,
		"y":        altar.Y,
	}

	before, err := g.scripts.Policy("test.records_at", query)

	if err != nil {
		t.Fatal(err)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	after, err := restored.scripts.Policy("test.records_at", query)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, after) {
		t.Fatalf("Temple altar query changed after restore: %v to %v",
			before, after)
	}
}

// A Lua rule can replace a saved string argument only on the intended
// source record; a failed compare leaves it unchanged through restore.
func TestLuaReplacesOneSavedRecordArgument(t *testing.T) {
	g, rules := newReligionRecordsGame(t, 447)

	defer g.Close()

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := g.levels[position.LevelID]
	sourceID := level.VaultID()

	if sourceID == "" {
		t.Fatal("generated floor has no catalogued source vault")
	}

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindSourceFeature,
		SourceID: sourceID,
		Identity: string(terrain.Altar),
		X:        position.X,
		Y:        position.Y,
		Arguments: []vault.Argument{
			{
				Name:   "god_id",
				Kind:   vault.ValueString,
				String: "GOD_ECUMENICAL",
			},
		},
	}); err != nil {
		t.Fatal(err)
	}

	input := map[string]any{
		"level_id":    position.LevelID,
		"x":           position.X,
		"y":           position.Y,
		"source_id":   sourceID,
		"kind":        string(vault.KindSourceFeature),
		"identity":    string(terrain.Altar),
		"key":         "god_id",
		"expected":    "GOD_ECUMENICAL",
		"replacement": "GOD_ZIN",
	}

	if _, err := g.scripts.Policy("test.change_record", input); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	assertGod := func(game *Game, want string) {
		t.Helper()

		records := game.levels[position.LevelID].VaultRecords()
		last := records[len(records)-1]

		if last.Arguments[0].String != want {
			t.Fatalf("altar god = %q, want %q", last.Arguments[0].String, want)
		}
	}

	assertGod(g, "GOD_ZIN")

	if _, err := g.scripts.Policy("test.change_record", input); err == nil {
		t.Fatal("stale expected god changed altar twice")
	}

	assertGod(g, "GOD_ZIN")

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	assertGod(restored, "GOD_ZIN")
}
