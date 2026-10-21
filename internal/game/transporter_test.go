package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/modfs"
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
