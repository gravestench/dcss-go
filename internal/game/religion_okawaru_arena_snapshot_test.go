package game

import (
	"strings"
	"testing"

	"crawl/internal/terrain"
)

// Render each staged source layout as a compact text map. The marks show
// the two Duel landings, locked barrier, and return arch on the real grid.
func TestOkawaruArenaTextSnapshots(t *testing.T) {
	g := newGeneratedTestGame(t, 99144)

	for number := 1; number <= 4; number++ {
		id := "okawaru_arena_" + string(rune('0'+number))
		stage, err := g.stageGeneratedLevel(
			"world.generate_arena_level",
			map[string]any{
				"species_id":  "SP_HUMAN",
				"player_name": "Snapshot",
				"layout_id":   id,
			},
		)

		if err != nil {
			t.Fatal(err)
		}

		floor := g.levels[stage.levelID]
		cells := floor.Cells()
		left, top := len(cells[0]), len(cells)
		right, bottom := 0, 0

		for y, row := range cells {
			for x, feature := range row {
				if feature == terrain.MetalWall {
					if x < left {
						left = x
					}
					if x > right {
						right = x
					}
					if y < top {
						top = y
					}
					if y > bottom {
						bottom = y
					}
				}
			}
		}

		if left > right || top > bottom {
			t.Fatal("Arena layout has no outer metal wall")
		}

		targetX, _ := decisionInteger(stage.portalData, "target_x")
		targetY, _ := decisionInteger(stage.portalData, "target_y")
		barrierX, _ := decisionInteger(stage.portalData, "barrier_x")
		barrierY, _ := decisionInteger(stage.portalData, "barrier_y")
		exitX, _ := decisionInteger(stage.portalData, "exit_x")
		exitY, _ := decisionInteger(stage.portalData, "exit_y")
		rows := make([]string, 0, bottom-top+1)

		for y := top; y <= bottom; y++ {
			var line strings.Builder

			for x := left; x <= right; x++ {
				glyph := terrain.Glyph(cells[y][x])

				switch {
				case x == stage.entry.x && y == stage.entry.y:
					glyph = 'A'
				case x == targetX && y == targetY:
					glyph = 'T'
				case x == barrierX && y == barrierY:
					glyph = 'B'
				case x == exitX && y == exitY:
					glyph = 'E'
				default:
					if actor, present := floor.ActorAt(x, y); present {
						body, found := g.stores.Actors.Get(actor)
						if found && body.KindID == "MONS_SPECTATOR" {
							glyph = 'S'
						}
					}
				}

				line.WriteRune(glyph)
			}

			rows = append(rows, line.String())
		}

		t.Logf("%s\n%s", id, strings.Join(rows, "\n"))

		if err := stage.rollback(); err != nil {
			t.Fatal(err)
		}
	}
}
