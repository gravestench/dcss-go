package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestRatUsesEightDirectionContactAndPursuit(t *testing.T) {
	for _, tc := range []struct {
		name             string
		playerX, playerY int
		blockDiagonal    bool
		want             ecs.Intent
	}{
		{"diagonal melee", 3, 2, false, ecs.Intent{Kind: ecs.IntentMelee, DX: -1, DY: 1}},
		{"diagonal pursuit", 2, 3, false, ecs.Intent{Kind: ecs.IntentMove, DX: -1, DY: 1}},
		{"blocked diagonal fallback", 2, 3, true, ecs.Intent{Kind: ecs.IntentMove, DX: -1}},
		{"cardinal melee", 3, 1, false, ecs.Intent{Kind: ecs.IntentMelee, DX: -1}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newStepGame(t)
			if err := g.levels[1].MoveActor(g.player, tc.playerX, tc.playerY); err != nil {
				t.Fatal(err)
			}
			if tc.blockDiagonal {
				row := []byte(g.levels[1].terrain[2])
				row[3] = '#'
				g.levels[1].terrain[2] = string(row)
			}
			intent, err := g.chooseMonsterIntent(ratID(t, g))
			if err != nil || intent != tc.want {
				t.Fatalf("intent %+v, error %v, want %+v", intent, err, tc.want)
			}
		})
	}
}

func TestRatWaitsWhenPlayerIsOnAnotherFloor(t *testing.T) {
	g := newStepGame(t)
	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].PlaceActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}
	intent, err := g.chooseMonsterIntent(ratID(t, g))
	if err != nil || intent.Kind != ecs.IntentWait {
		t.Fatalf("off-floor intent %+v, %v", intent, err)
	}
}
