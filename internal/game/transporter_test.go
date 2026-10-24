package game

import (
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// A source DES arrival must become playable terrain and retain its link
// through the actual command, ECS, save, and restore pipeline.
func TestAuthoredTransporterTravelAndSave(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-force-transporter")

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

	if level.VaultID() != "spicycebolla_arrival_risky_transporter" {
		t.Fatalf("selected vault = %q", level.VaultID())
	}

	var source *vault.Record
	var landing *vault.Record

	for _, record := range level.VaultRecords() {
		copy := record

		if record.Kind != vault.KindMarker {
			continue
		}

		if strings.HasPrefix(record.Identity, "lua:transp_loc(") {
			source = &copy
		} else if strings.HasPrefix(record.Identity, "lua:transp_dest_loc(") {
			landing = &copy
		}
	}

	if source == nil || landing == nil {
		t.Fatalf("source/landing = %+v / %+v", source, landing)
	}

	if level.Cells()[source.Y][source.X] != terrain.Transporter ||
		level.Cells()[landing.Y][landing.X] != terrain.TransporterLanding {
		t.Fatal("authored markers did not paint transporter terrain")
	}

	if err := level.MoveActor(g.player, source.X, source.Y); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	shown := g.View().Cells[source.Y*level.width+source.X]

	if shown.Glyph != '©' || shown.State != Visible {
		t.Fatalf("source cell display = %+v", shown)
	}

	before := g.currentAut
	result, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	if result.View.PlayerX != landing.X ||
		result.View.PlayerY != landing.Y ||
		result.View.LevelID != 1 {
		t.Fatalf("transporter reached %d:%d,%d, want 1:%d,%d",
			result.View.LevelID, result.View.PlayerX, result.View.PlayerY,
			landing.X, landing.Y)
	}

	if g.currentAut-before != 10 {
		t.Fatalf("transporter cost %d aut, want 10", g.currentAut-before)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("transporter state changed on restore")
	}

	forged := g.Snapshot()

	for recordIndex := range forged.Levels[0].VaultRecords {
		record := &forged.Levels[0].VaultRecords[recordIndex]

		if record.Kind != vault.KindMarker ||
			!strings.HasPrefix(record.Identity, "lua:transp_loc(") {
			continue
		}

		for argumentIndex := range record.Arguments {
			argument := &record.Arguments[argumentIndex]

			if argument.Name == "transporter_destination_x" {
				argument.String = "0"
			}
		}
	}

	bad, err := RestoreWithRules(forged, rules, RestorePolicy{})

	if bad != nil {
		_ = bad.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "transporter") {
		t.Fatalf("forged transporter link error = %v", err)
	}

	if err := restored.levels[1].MoveActor(restored.player, source.X, source.Y); err != nil {
		t.Fatal(err)
	}

	up, err := restored.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	if up.View.PlayerX != landing.X || up.View.PlayerY != landing.Y {
		t.Fatal("saved transporter did not accept the other stair key")
	}
}

// A tagged Abyss exit's generated transporter markers must match their
// source and landing cells when the first window is saved.
func TestGeneratedTransporterSeed3167Restores(t *testing.T) {
	g, err := NewDungeonGame(3167, "SP_HUMAN",
		"JOB_ABYSSAL_KNIGHT", "WPN_HAND_AXE", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	snapshot := g.Snapshot()

	if path := os.Getenv("CRAWL_ABYSS_TRANSPORTER_SNAPSHOT"); path != "" {
		writeAbyssTransporterSnapshot(t, snapshot, path)
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("fresh generated floor failed restore: %v", err)
	}

	defer restored.Close()
}

// The opt-in export uses the saved grid and links, so the example shows
// exactly what restore validates rather than a separate renderer's guess.
func writeAbyssTransporterSnapshot(
	t *testing.T,
	snapshot save.Snapshot,
	path string,
) {
	t.Helper()

	var floor save.LevelRecord

	for _, level := range snapshot.Levels {
		if level.ID == abyssStorageID {
			floor = level
			break
		}
	}

	if floor.ID != abyssStorageID {
		t.Fatal("snapshot has no Abyss floor")
	}

	var body strings.Builder

	fmt.Fprintf(&body, "Abyssal Knight starting window, seed %d\n\n",
		snapshot.Seed)
	body.WriteString(formatLevelTextSnapshot(floor, nil))
	body.WriteString("\nThe © glyph marks both a transporter source and its landing.\n")
	body.WriteString("\nNamed transporter connections:\n")

	for _, record := range floor.VaultRecords {
		if !strings.HasPrefix(record.Identity, "lua:transp_loc(") ||
			record.Overridden {
			continue
		}

		coordinates := map[string]string{}

		for _, argument := range record.Arguments {
			coordinates[argument.Name] = argument.String
		}

		fmt.Fprintf(&body, "  %s (%d,%d) -> (%s,%s)\n",
			record.SourceID, record.X, record.Y,
			coordinates["transporter_destination_x"],
			coordinates["transporter_destination_y"])
	}

	if err := os.WriteFile(path, []byte(body.String()), 0o644); err != nil {
		t.Fatal(err)
	}
}

// A moving Abyss window must update a retained vault's named link after
// translating its source and landing into the new coordinate frame.
func TestGeneratedAbyssTransporterLinkSurvivesShift(t *testing.T) {
	g, err := NewDungeonGame(3167, "SP_HUMAN",
		"JOB_ABYSSAL_KNIGHT", "WPN_HAND_AXE", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	level := g.levels[abyssStorageID]
	before := map[string]vault.Record{}

	for _, record := range level.VaultRecords() {
		if strings.Contains(record.Identity, "x_factor") &&
			!record.Overridden {
			before[record.Identity] = record
		}
	}

	if len(before) != 2 {
		t.Fatalf("active x_factor markers before shift = %d, want 2", len(before))
	}

	for identity, record := range before {
		if strings.HasPrefix(identity, "lua:transp_loc(") {
			if err := level.MoveActor(g.player, record.X, record.Y); err != nil {
				t.Fatal(err)
			}

			break
		}
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatalf("travelling before shift: %v", err)
	}

	knowledgeStore := g.scripts.Components()["character.transporter_knowledge"]
	knowledge, found := knowledgeStore.Get(g.player)

	if !found {
		t.Fatal("travelling did not record transporter knowledge")
	}

	knownValue, err := knowledge.Get("links")

	if err != nil {
		t.Fatal(err)
	}

	known := knownValue.(map[string]any)

	if len(known) != 1 {
		t.Fatalf("learned transporter links = %v", known)
	}

	var edge point
	var edgeFound bool

	for y := 28; y < 39; y++ {
		if level.Walkable(11, y) {
			edge = point{
				x: 11,
				y: y,
			}
			edgeFound = true
			break
		}
	}

	if !edgeFound {
		t.Fatal("no walkable cell near the transporter vault")
	}

	if err := level.MoveActor(g.player, edge.x, edge.y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.abyssState.ShiftCount != 1 {
		t.Fatalf("shift count = %d, want 1", g.abyssState.ShiftCount)
	}

	after := map[string]vault.Record{}

	for _, record := range g.levels[abyssStorageID].VaultRecords() {
		if strings.Contains(record.Identity, "x_factor") &&
			!record.Overridden {
			after[record.Identity] = record
		}
	}

	if len(after) != 2 {
		t.Fatalf("active x_factor markers after shift = %d, want 2", len(after))
	}

	shiftX := level.width/2 - edge.x
	shiftY := len(level.Cells())/2 - edge.y
	var source vault.Record
	var landing vault.Record

	for identity, record := range after {
		original := before[identity]

		if record.X != original.X+shiftX ||
			record.Y != original.Y+shiftY {
			t.Fatalf("shifted marker %s at %d:%d, began at %d:%d",
				identity, record.X, record.Y, original.X, original.Y)
		}

		if strings.HasPrefix(identity, "lua:transp_loc(") {
			source = record
		} else {
			landing = record
		}
	}

	coordinates := map[string]string{}

	for _, argument := range source.Arguments {
		coordinates[argument.Name] = argument.String
	}

	if coordinates["transporter_destination_x"] != strconv.Itoa(landing.X) ||
		coordinates["transporter_destination_y"] != strconv.Itoa(landing.Y) {
		t.Fatalf("shifted transporter link = %v, landing at %d:%d",
			coordinates, landing.X, landing.Y)
	}

	knowledge, found = knowledgeStore.Get(g.player)

	if !found {
		t.Fatal("shift lost transporter knowledge component")
	}

	knownValue, err = knowledge.Get("links")

	if err != nil {
		t.Fatal(err)
	}

	known = knownValue.(map[string]any)
	newKey := strconv.Itoa(abyssStorageID) + ":" +
		strconv.Itoa(source.X) + ":" + strconv.Itoa(source.Y)
	newDestination := strconv.Itoa(landing.X) + ":" +
		strconv.Itoa(landing.Y)

	if len(known) != 1 || known[newKey] != newDestination {
		t.Fatalf("shifted learned links = %v, want %s -> %s",
			known, newKey, newDestination)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("shifted transporter floor failed restore: %v", err)
	}

	defer restored.Close()
}
