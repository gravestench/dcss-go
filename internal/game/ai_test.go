package game

import (
	"reflect"
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
				// Acquire the player before the new wall cuts sight; fallback
				// movement then uses the remembered target.
				if _, err := g.chooseMonsterIntent(ratID(t, g)); err != nil {
					t.Fatal(err)
				}
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

func TestQuokkaAcquiresPlayerOnlyInItsOwnSight(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)
	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].PlaceActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}
	intent, err := g.chooseMonsterIntent(quokka)
	if err != nil || intent.Kind != ecs.IntentWait {
		t.Fatalf("hidden quokka intent %+v, %v", intent, err)
	}
	ai, _ := g.stores.AI.Get(quokka)
	if ai.Behavior != "wander" {
		t.Fatalf("hidden quokka behavior %+v", ai)
	}
	if err := g.levels[2].MoveActor(g.player, 14, 6); err != nil {
		t.Fatal(err)
	}
	intent, err = g.chooseMonsterIntent(quokka)
	if err != nil || intent.Kind != ecs.IntentMelee || intent.DX != 0 || intent.DY != -1 {
		t.Fatalf("visible quokka intent %+v, %v", intent, err)
	}
	if ai.Behavior != "seek" || ai.TargetX != 14 || ai.TargetY != 6 {
		t.Fatalf("quokka did not remember seen player: %+v", ai)
	}
}

func TestQuokkaPursuesLastSeenTileThenStops(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)
	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].PlaceActor(g.player, 14, 5); err != nil {
		t.Fatal(err)
	}
	if _, err := g.chooseMonsterIntent(quokka); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].MoveActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}
	intent, err := g.chooseMonsterIntent(quokka)
	if err != nil || intent != (ecs.Intent{Kind: ecs.IntentMove, DY: -1}) {
		t.Fatalf("quokka did not pursue last seen tile: %+v, %v", intent, err)
	}
	if err := g.levels[2].MoveActor(quokka, 14, 5); err != nil {
		t.Fatal(err)
	}
	intent, err = g.chooseMonsterIntent(quokka)
	if err != nil || intent.Kind != ecs.IntentWait {
		t.Fatalf("quokka continued blind pursuit: %+v, %v", intent, err)
	}
	ai, _ := g.stores.AI.Get(quokka)
	if ai.Behavior != "wander" {
		t.Fatalf("quokka kept stale target: %+v", ai)
	}
}

func TestMonsterAwarenessSurvivesSaveAndRejectsInvalidTarget(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)
	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].PlaceActor(g.player, 14, 5); err != nil {
		t.Fatal(err)
	}
	if _, err := g.chooseMonsterIntent(quokka); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].MoveActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}
	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}
	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("monster target changed across save")
	}
	want, err := g.chooseMonsterIntent(quokka)
	if err != nil {
		t.Fatal(err)
	}
	got, err := loaded.chooseMonsterIntent(quokka)
	if err != nil || got != want {
		t.Fatalf("restored pursuit %+v, %v; want %+v", got, err, want)
	}
	for i := range snapshot.Entities {
		if snapshot.Entities[i].ID == uint64(quokka) {
			snapshot.Entities[i].AI.TargetX = -1
			break
		}
	}
	if bad, err := Restore(snapshot, testCatalog(t)); err == nil {
		bad.Close()
		t.Fatal("invalid monster target accepted")
	}
}

func TestLegacyChaseSaveStillLoadsAndStopsBlindPursuit(t *testing.T) {
	g := newStepGame(t)
	legacy := g.Snapshot()
	for i := range legacy.Entities {
		if legacy.Entities[i].AI != nil {
			legacy.Entities[i].AI.Behavior = "chase"
		}
	}
	loaded, err := Restore(legacy, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if !reflect.DeepEqual(legacy, loaded.Snapshot()) {
		t.Fatal("legacy chase AI changed during restore")
	}
	quokka := quokkaID(t, loaded)
	if err := loaded.levels[1].RemoveActor(loaded.player); err != nil {
		t.Fatal(err)
	}
	if err := loaded.levels[2].PlaceActor(loaded.player, 1, 1); err != nil {
		t.Fatal(err)
	}
	intent, err := loaded.chooseMonsterIntent(quokka)
	if err != nil || intent.Kind != ecs.IntentWait {
		t.Fatalf("legacy quokka pursued unseen player: %+v, %v", intent, err)
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
