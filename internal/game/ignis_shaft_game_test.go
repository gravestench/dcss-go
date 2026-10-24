package game

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"crawl/internal/save"
)

// Keep a human-readable copy of every floor made during the D:1 to D:3
// fall. The stair lines show how the intermediate map still connects.
func assertIgnisShaftSnapshots(t *testing.T, g *Game) {
	t.Helper()

	snapshot := g.Snapshot()
	levels := make(map[int]save.LevelRecord, len(snapshot.Levels))

	for _, level := range snapshot.Levels {
		levels[level.ID] = level
	}

	var textMap strings.Builder

	fmt.Fprintf(&textMap, "Ignis shaft: Dungeon:1 -> Dungeon:3, seed %d\n", snapshot.Seed)
	textMap.WriteString("Dungeon:2 is generated en route. Coordinates are zero-based.\n\n")

	for depth := 1; depth <= 3; depth++ {
		level, found := levels[depth]

		if !found {
			t.Fatalf("shaft snapshot has no Dungeon:%d", depth)
		}

		textMap.WriteString(formatLevelTextSnapshot(level, levels))

		if depth < 3 {
			textMap.WriteByte('\n')
		}
	}

	path := filepath.Join("testdata", "ignis_shaft_d1_to_d3.txt")

	if os.Getenv("UPDATE_IGNIS_SHAFT_SNAPSHOT") == "1" {
		if err := os.WriteFile(path, []byte(textMap.String()), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	want, err := os.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if textMap.String() != string(want) {
		t.Fatal("Ignis shaft floors differ from their text snapshot")
	}
}

// The enchantment belongs to the monster, so its effect must survive a
// save/load cycle without another wrath draw or temporary action state.
func TestIgnisChampionSurvivesRestore(t *testing.T) {
	g := newStepGame(t)
	monsters := g.stores.AI.Entities()

	if len(monsters) == 0 {
		t.Fatal("scenario has no monster to anoint")
	}

	_, err := g.scripts.Components()["religion.ignis_fire_champion"].Set(
		monsters[0],
		map[string]any{
			"active": true,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("fire champion marker changed across restore")
	}
}

// A pending shaft is an action effect. The session must move the player
// after the timed action and consume the request before a second turn.
func TestPendingShaftMovesToLoadedDungeonFloor(t *testing.T) {
	g := newStepGame(t)

	store := g.scripts.Components()["world.pending_shaft"]

	if _, err := store.Set(g.player, map[string]any{
		"origin_level_id": int64(1),
		"branch_id":       "BRANCH_DUNGEON",
		"local_depth":     int64(2),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found || position.LevelID != 2 {
		t.Fatalf("shaft destination = %+v, want D:2", position)
	}

	if _, pending := store.Get(g.player); pending {
		t.Fatal("completed shaft remains pending")
	}
}

// The next Dungeon floor begins absent in a normal game. A shaft must
// stage and populate it before moving the player into its active grid.
func TestPendingShaftGeneratesDungeonDestination(t *testing.T) {
	g := newGeneratedTestGame(t, 73)

	if g.levels[2] != nil {
		t.Fatal("D:2 unexpectedly exists before the shaft")
	}

	store := g.scripts.Components()["world.pending_shaft"]

	if _, err := store.Set(g.player, map[string]any{
		"origin_level_id": int64(1),
		"branch_id":       "BRANCH_DUNGEON",
		"local_depth":     int64(3),
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if g.levels[2] == nil ||
		g.levels[3] == nil ||
		result.View.LevelID != 3 {
		t.Fatalf("shaft arrived on level %d with D:2 = %v, D:3 = %v",
			result.View.LevelID, g.levels[2] != nil, g.levels[3] != nil)
	}

	if _, pending := store.Get(g.player); pending {
		t.Fatal("generated shaft remains pending")
	}

	assertIgnisShaftSnapshots(t, g)
}

// A card can create a shaft during command preparation. If staging the
// destination fails, the card draw and its RNG draws must roll back too.
func TestFailedShaftRestoresAbilityPreparation(t *testing.T) {
	g := newGeneratedTestGame(t, 1021)

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_NEMELEX_XOBEH",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["religion.nemelex_decks"].Set(
		g.player,
		map[string]any{
			"counts": map[string]any{
				"DECK_OF_ESCAPE": int64(1),
			},
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["world.pending_shaft"].Set(
		g.player,
		map[string]any{
			"origin_level_id": int64(1),
			"branch_id":       "BRANCH_DUNGEON",
			"local_depth":     int64(99),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()

	if _, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_NEMELEX_DRAW_ESCAPE",
	}); err == nil {
		t.Fatal("accepted an unstaged shaft destination")
	}

	state, found := g.scripts.Components()["religion.nemelex_decks"].Get(g.player)

	if !found {
		t.Fatal("failed shaft removed the player's deck")
	}

	fields, err := state.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	counts := fields["counts"].(map[string]any)

	if counts["DECK_OF_ESCAPE"] != int64(1) {
		t.Fatalf("failed shaft spent a card: %+v", counts)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("failed shaft changed the run, generated floors, or RNG")
	}
}

// An anointment may only attach to a living monster. A malformed save
// must not let the marker turn the player or an item into a champion.
func TestIgnisChampionRejectsPlayerSave(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID != snapshot.PlayerID {
			continue
		}

		snapshot.Entities[index].Dynamic = append(
			snapshot.Entities[index].Dynamic,
			save.DynamicComponentRecord{
				Schema: "religion.ignis_fire_champion",
				Values: map[string]json.RawMessage{
					"active": json.RawMessage("true"),
				},
			},
		)

		break
	}

	restored, err := Restore(snapshot)

	if err == nil {
		defer restored.Close()

		t.Fatal("accepted a fire champion marker on the player")
	}
}
