package game

import (
	"testing"

	"dcrawl-go/internal/modfs"
)

func TestEverySourceTrapEffectHandlesPlayerEntry(t *testing.T) {
	cases := []struct {
		kindID  string
		charges int64
	}{
		{
			kindID:  "TRAP_TELEPORT",
			charges: 1,
		},
		{kindID: "TRAP_TELEPORT_PERMANENT"},
		{kindID: "TRAP_ALARM"},
		{kindID: "TRAP_NET"},
		{kindID: "TRAP_ZOT"},
		{kindID: "TRAP_SHAFT"},
		{
			kindID:  "TRAP_GOLUBRIA",
			charges: 30,
		},
		{kindID: "TRAP_PLATE"},
		{kindID: "TRAP_WEB"},
		{kindID: "TRAP_DISPERSAL"},
	}

	rules, err := modfs.Load("testdata/vault-traps")

	if err != nil {
		t.Fatal(err)
	}

	for _, test := range cases {
		t.Run(test.kindID, func(t *testing.T) {
			game, err := NewDungeonGameWithRules(
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

			defer game.Close()

			store := game.scripts.Components()[trapSchema]
			trap := store.Entities()[0]
			position, _ := game.stores.Positions.Get(trap)

			if _, err := store.Set(trap, map[string]any{
				"kind_id":       test.kindID,
				"level_id":      int64(position.LevelID),
				"x":             int64(position.X),
				"y":             int64(position.Y),
				"charges":       test.charges,
				"revealed":      true,
				"source_record": "",
			}); err != nil {
				t.Fatal(err)
			}

			directions := []struct {
				dx int
				dy int
			}{
				{dx: -1},
				{dx: 1},
				{dy: -1},
				{dy: 1},
			}

			entry := Command{Kind: CommandMove}
			found := false

			for _, direction := range directions {
				x := position.X - direction.dx
				y := position.Y - direction.dy

				if game.levels[1].Walkable(x, y) {
					if err := game.levels[1].MoveActor(game.player, x, y); err != nil {
						t.Fatal(err)
					}

					entry.DX = direction.dx
					entry.DY = direction.dy
					found = true
					break
				}
			}

			if !found {
				t.Fatal("trap has no walkable approach")
			}

			if err := game.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			result, err := game.Step(entry)

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent != 10 {
				t.Fatalf("trap entry spent %d aut", result.Spent)
			}

			restored, err := RestoreWithRules(
				game.Snapshot(), rules, RestorePolicy{},
			)

			if err != nil {
				t.Fatalf("restore after trap entry: %v", err)
			}

			restored.Close()
		})
	}
}
