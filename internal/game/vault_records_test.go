package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

func newForcedOctagonGame(t *testing.T) (*Game, modfs.Ruleset) {
	t.Helper()

	rules, err := modfs.Load("testdata/vault-force-octagon")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		41,
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

func TestVaultRecordSaveRestore(t *testing.T) {
	g, rules := newForcedOctagonGame(t)
	defer g.Close()

	level := g.levels[1]

	if level.VaultID() == "" || len(level.VaultRecords()) == 0 {
		t.Fatal("selected arrival vault did not reach the level owner")
	}

	saved := g.Snapshot()

	if saved.Levels[0].VaultID == "" || len(saved.Levels[0].VaultRecords) == 0 {
		t.Fatal("vault identity or placement intent was omitted from the save")
	}

	restored, err := RestoreWithRules(saved, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("vault records changed during save and restore")
	}

	copy := level.VaultRecords()

	copy[0].Identity = "changed"

	if reflect.DeepEqual(copy, level.VaultRecords()) {
		t.Fatal("level exposed mutable vault records")
	}
}

func TestSupplementalVaultRecordsNeedNoPrimaryVault(t *testing.T) {
	level := &Level{
		ID:      5,
		width:   1,
		terrain: [][]terrain.ID{{terrain.Floor}},
	}

	generated := map[string]any{
		"vault_ids": []any{"extra_shop"},
		"vault_records": []any{
			map[string]any{
				"kind":     string(vault.KindItem),
				"vault_id": "extra_shop",
				"identity": "test_item",
				"x":        int64(0),
				"y":        int64(0),
			},
		},
	}

	if err := loadLuaVault(level, generated); err != nil {
		t.Fatal(err)
	}

	if level.VaultID() != "" {
		t.Fatalf("supplemental vault became primary: %q", level.VaultID())
	}

	if records := level.VaultRecords(); len(records) != 1 ||
		records[0].SourceID != "extra_shop" {
		t.Fatalf("supplemental vault records = %+v", records)
	}
}

func TestSupportedVaultEntitiesMaterializeOnce(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-materialize")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		41,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	level := g.levels[1]

	if level.VaultID() != "zz_vault_materialize" {
		t.Fatalf("selected vault = %s", level.VaultID())
	}

	materialized := 0

	for _, record := range level.VaultRecords() {
		if record.SourceID != level.VaultID() ||
			(record.Kind != vault.KindMonster && record.Kind != vault.KindItem) {
			continue
		}

		if record.Pending {
			t.Fatalf("supported source %s stayed pending", record.Identity)
		}

		materialized++
	}

	if materialized != 2 {
		t.Fatalf("materialized source objects = %d, want 2", materialized)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("vault ECS entities or records changed on restore")
	}
}

func TestVaultRecordValidation(t *testing.T) {
	g, rules := newForcedOctagonGame(t)
	defer g.Close()

	level := g.levels[1]

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindItem,
		SourceID: level.VaultID(),
		Identity: "potion of curing",
		X:        -1,
		Y:        1,
	}); err == nil {
		t.Fatal("level accepted an out-of-bounds vault item")
	}

	snapshot := g.Snapshot()

	snapshot.Levels[0].VaultRecords[0].Kind = "unknown"

	if _, err := RestoreWithRules(snapshot, rules, RestorePolicy{}); err == nil {
		t.Fatal("restore accepted an unknown vault record kind")
	}

	bad := vault.Record{
		Kind:     vault.KindMarker,
		SourceID: level.VaultID(),
		X:        1,
		Y:        1,
		Arguments: []vault.Argument{
			{
				Name:   "radius",
				Kind:   vault.ValueInt,
				String: "four",
			},
		},
	}

	if err := level.AddVaultRecord(bad); err == nil {
		t.Fatal("level accepted a mismatched vault argument value")
	}
}

func TestPendingVaultItemIsVisibleAndUnavailable(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]

	if err := level.AddVaultRecord(vault.Record{
		Kind:        vault.KindItem,
		SourceID:    level.VaultID(),
		Identity:    "unported wand",
		SourceGlyph: "%",
		X:           position.X,
		Y:           position.Y,
		Pending:     true,
	}); err != nil {
		t.Fatal(err)
	}

	found := false

	for _, entity := range g.View().Entities {
		if entity.Role == "vault_pending" &&
			entity.Name == "unported wand (unavailable)" &&
			entity.Glyph == '%' {
			found = true
		}
	}

	if !found {
		t.Fatal("pending item is absent from the client view")
	}

	result, err := g.Step(Command{Kind: CommandPickup})

	if err != nil {
		t.Fatal(err)
	}

	if len(result.Events) == 0 ||
		result.Events[0].Text != "The unported wand is unavailable in this port." {
		t.Fatalf("pending item interaction = %+v, %v", result.Events, err)
	}
}

func TestScriptedOctagonVaultRunsInGame(t *testing.T) {
	g, rules := newForcedOctagonGame(t)

	defer g.Close()

	level := g.levels[1]

	if level.VaultID() != "enne_arrival_octagon_isle" {
		t.Fatalf("selected scripted vault = %s", level.VaultID())
	}

	shaped := false

	for _, record := range level.VaultRecords() {
		if record.Kind == vault.KindOctaRoom && !record.Pending {
			shaped = true
		}
	}

	if !shaped {
		t.Fatal("octagon Lua hook did not shape the source map")
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("scripted vault changed after restore")
	}
}
