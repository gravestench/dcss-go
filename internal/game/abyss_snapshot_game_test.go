package game

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/terrain"
)

// Export only on request. These four stages use the live ruleset and
// action path, so the text reveals what a player could actually traverse.
func TestAbyssTextSnapshots(t *testing.T) {
	directory := os.Getenv("CRAWL_ABYSS_SNAPSHOT_DIR")

	if directory == "" {
		t.Skip("set CRAWL_ABYSS_SNAPSHOT_DIR to export playable maps")
	}

	if err := os.MkdirAll(directory, 0o755); err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load("testdata/region-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	var index strings.Builder

	fmt.Fprintln(&index, "Playable Abyss windows, seed 1")
	fmt.Fprintln(&index, "Coordinates are zero-based (x,y); x goes right, y goes down.")
	fmt.Fprintln(&index, "Each 80x70 grid shows terrain without actor, item, or fog glyphs.")
	fmt.Fprintln(&index, "Unlinked Abyss exits return to the saved outside site; stairs regenerate the window.")
	fmt.Fprintln(&index)

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	writeAbyssWindow(t, g, directory, &index, "proto")
	level := g.levels[abyssStorageID]
	var edge point
	found := false

	for y := 12; y < 58; y++ {
		_, occupied := level.ActorAt(11, y)

		if level.Walkable(11, y) && !occupied {
			edge = point{
				x: 11,
				y: y,
			}

			found = true
			break
		}
	}

	if !found {
		t.Fatal("snapshot seed has no open shift edge")
	}

	if err := level.MoveActor(g.player, edge.x, edge.y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	writeAbyssWindow(t, g, directory, &index, "shifted")

	for depth := 2; depth <= 7; depth++ {
		position, _ := g.stores.Positions.Get(g.player)

		if err := g.levels[abyssStorageID].SetCell(position.X,
			position.Y, terrain.AbyssalStair); err != nil {
			t.Fatal(err)
		}

		if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
			t.Fatal(err)
		}
	}

	writeAbyssWindow(t, g, directory, &index, "rune")
	g.abyssState.ExitXP = 1

	if _, err := g.scripts.Policy("test.abyss_xp_exit", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	writeAbyssWindow(t, g, directory, &index, "exit")

	if err := os.WriteFile(filepath.Join(directory, "index.txt"),
		[]byte(index.String()), 0o644); err != nil {
		t.Fatal(err)
	}
}

// Print the saved terrain and explicit unlinked travel rules that the
// ordinary Dungeon stair formatter cannot infer from a link record.
func writeAbyssWindow(
	t *testing.T,
	g *Game,
	directory string,
	index *strings.Builder,
	stage string,
) {
	t.Helper()
	snapshot := g.Snapshot()
	var level save.LevelRecord

	for _, candidate := range snapshot.Levels {
		if candidate.ID == abyssStorageID {
			level = candidate
			break
		}
	}

	if level.ID != abyssStorageID || snapshot.AbyssState == nil {
		t.Fatal("snapshot has no live Abyss window")
	}

	state := snapshot.AbyssState
	var playerPosition *point

	for _, entity := range snapshot.Entities {
		if entity.ID == snapshot.PlayerID && entity.Position != nil {
			playerPosition = &point{
				x: entity.Position.X,
				y: entity.Position.Y,
			}
		}
	}

	if playerPosition == nil {
		t.Fatal("Abyss snapshot has no player position")
	}

	reachable := abyssSnapshotReachable(level.Cells, *playerPosition)
	filename := stage + ".txt"
	mapIDs := strings.Join(state.SelectedMapIDs, ", ")

	if mapIDs == "" {
		mapIDs = "(none)"
	}

	var body strings.Builder

	fmt.Fprintf(&body, "Stage: %s\n", stage)
	fmt.Fprintf(&body, "Abyss depth: %d; morph depth: %d; phase: %.3f\n",
		state.BranchDepth, state.MorphDepth, state.Phase)
	fmt.Fprintf(&body, "World origin: (%d,%d); shifts: %d\n",
		state.WorldX, state.WorldY, state.ShiftCount)
	fmt.Fprintf(&body, "Selected maps: %s\n", mapIDs)
	fmt.Fprintf(&body, "Reachable cells from player (%d,%d): %d\n",
		playerPosition.x, playerPosition.y, len(reachable))
	body.WriteByte('\n')
	body.WriteString(formatLevelTextSnapshot(level, nil))
	body.WriteString("\nAbyss travel and rune locations:\n")
	travel := 0
	exits := 0

	for y, row := range level.Cells {
		for x, feature := range row {
			switch feature {
			case terrain.ExitAbyss:
				exits++

				if state.ReturnSite != nil {
					cell := point{
						x: x,
						y: y,
					}

					fmt.Fprintf(&body, "  exit (%d,%d) -> level %d (%d,%d); reachable=%t\n",
						x, y, state.ReturnSite.LevelID,
						state.ReturnSite.X, state.ReturnSite.Y,
						reachable[cell])
				}

				travel++

			case terrain.AbyssalStair:
				cell := point{
					x: x,
					y: y,
				}

				fmt.Fprintf(&body, "  stair (%d,%d) -> Abyss:%d (new window); reachable=%t\n",
					x, y, state.BranchDepth+1,
					reachable[cell])

				travel++
			}
		}
	}

	runes := 0

	for _, entity := range snapshot.Entities {
		if entity.Item != nil &&
			entity.Position != nil &&
			entity.Item.KindID == "RUNE_ABYSSAL" &&
			entity.Position.LevelID == abyssStorageID {
			runes++
			cell := point{
				x: entity.Position.X,
				y: entity.Position.Y,
			}

			fmt.Fprintf(&body, "  rune (%d,%d); reachable=%t\n",
				entity.Position.X, entity.Position.Y,
				reachable[cell])
		}
	}

	if stage == "rune" && runes == 0 {
		t.Fatal("rune snapshot contains no Abyssal rune")
	}

	if stage == "exit" && exits == 0 {
		t.Fatal("exit snapshot contains no Abyss exit")
	}

	if travel == 0 {
		body.WriteString("  no visible exit or stair in this window\n")
	}

	if err := os.WriteFile(filepath.Join(directory, filename),
		[]byte(body.String()), 0o644); err != nil {
		t.Fatal(err)
	}

	fmt.Fprintf(index, "%s  %s  Abyss:%d  shift %d  reachable %d  maps: %s\n",
		stage, filename, state.BranchDepth, state.ShiftCount,
		len(reachable), mapIDs)
}

// Explore eight-way player movement over the printed cells so each text
// snapshot reports which stairs, exits, and runes connect to the player.
func abyssSnapshotReachable(cells [][]terrain.ID, start point) map[point]bool {
	reached := map[point]bool{start: true}
	queue := []point{start}

	for head := 0; head < len(queue); head++ {
		current := queue[head]

		for dy := -1; dy <= 1; dy++ {
			for dx := -1; dx <= 1; dx++ {
				next := point{
					x: current.x + dx,
					y: current.y + dy,
				}

				if next.x < 0 ||
					next.y < 0 ||
					next.y >= len(cells) ||
					next.x >= len(cells[0]) ||
					reached[next] ||
					!terrain.Walkable(cells[next.y][next.x]) {
					continue
				}

				reached[next] = true
				queue = append(queue, next)
			}
		}
	}

	return reached
}
