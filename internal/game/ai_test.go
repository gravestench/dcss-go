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
		{
			name:          "diagonal melee",
			playerX:       3,
			playerY:       2,
			blockDiagonal: false,
			want: ecs.Intent{
				Kind: ecs.IntentMelee,
				DX:   -1,
				DY:   1,
			},
		},
		{
			name:          "diagonal pursuit",
			playerX:       2,
			playerY:       3,
			blockDiagonal: false,
			want: ecs.Intent{
				Kind: ecs.IntentMove,
				DX:   -1,
				DY:   1,
			},
		},
		{
			name:          "blocked sight routes around wall",
			playerX:       2,
			playerY:       3,
			blockDiagonal: true,
			want: ecs.Intent{
				Kind: ecs.IntentMove,
				DY:   1,
			},
		},
		{
			name:          "cardinal melee",
			playerX:       3,
			playerY:       1,
			blockDiagonal: false,
			want: ecs.Intent{
				Kind: ecs.IntentMelee,
				DX:   -1,
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newStepGame(t)

			if err := g.levels[1].MoveActor(g.player, tc.playerX, tc.playerY); err != nil {
				t.Fatal(err)
			}

			if tc.blockDiagonal {
				// Acquire the player before the new wall cuts sight; routing
				// then uses the remembered target and avoids the blocked corner.
				if _, err := newMonsterDecisionSystem(g).chooseIntent(ratID(t, g)); err != nil {
					t.Fatal(err)
				}

				row := []byte(g.levels[1].terrain[2])
				row[3] = '#'
				g.levels[1].terrain[2] = string(row)
			}

			intent, err := newMonsterDecisionSystem(g).chooseIntent(ratID(t, g))

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

	intent, err := newMonsterDecisionSystem(g).chooseIntent(quokka)

	if err != nil || intent.Kind == ecs.IntentMelee {
		t.Fatalf("hidden quokka intent %+v, %v", intent, err)
	}

	ai, _ := g.stores.AI.Get(quokka)

	if ai.Behavior != "wander" || ai.TargetX < 8 || ai.TargetX > 16 || ai.TargetY < 1 ||
		ai.TargetY > 7 || !g.levels[2].Walkable(ai.TargetX, ai.TargetY) {
		t.Fatalf("hidden quokka behavior %+v", ai)
	}

	if err := g.levels[2].MoveActor(g.player, 14, 6); err != nil {
		t.Fatal(err)
	}

	intent, err = newMonsterDecisionSystem(g).chooseIntent(quokka)

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

	if _, err := newMonsterDecisionSystem(g).chooseIntent(quokka); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].MoveActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}

	intent, err := newMonsterDecisionSystem(g).chooseIntent(quokka)

	if err != nil || intent != (ecs.Intent{
		Kind: ecs.IntentMove,
		DY:   -1,
	}) {
		t.Fatalf("quokka did not pursue last seen tile: %+v, %v", intent, err)
	}

	if err := g.levels[2].MoveActor(quokka, 14, 5); err != nil {
		t.Fatal(err)
	}

	intent, err = newMonsterDecisionSystem(g).chooseIntent(quokka)

	if err != nil || intent.Kind == ecs.IntentMelee {
		t.Fatalf("quokka attacked at an unseen target: %+v, %v", intent, err)
	}

	ai, _ := g.stores.AI.Get(quokka)

	if ai.Behavior != "wander" || (ai.TargetX == 14 && ai.TargetY == 5) {
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

	if _, err := newMonsterDecisionSystem(g).chooseIntent(quokka); err != nil {
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

	want, err := newMonsterDecisionSystem(g).chooseIntent(quokka)

	if err != nil {
		t.Fatal(err)
	}

	got, err := newMonsterDecisionSystem(loaded).chooseIntent(quokka)

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

	intent, err := newMonsterDecisionSystem(loaded).chooseIntent(quokka)

	if err != nil || intent.Kind == ecs.IntentMelee {
		t.Fatalf("legacy quokka pursued unseen player: %+v, %v", intent, err)
	}

	ai, _ := loaded.stores.AI.Get(quokka)

	if ai.Behavior != "wander" {
		t.Fatalf("legacy chase behavior persisted after unseen decision: %+v", ai)
	}
}

func TestQuokkaWanderTargetAndMemoryUseSerializableAIStream(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)

	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].PlaceActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}

	before := g.rng.States()

	if _, err := newMonsterDecisionSystem(g).chooseIntent(quokka); err != nil {
		t.Fatal(err)
	}

	ai, _ := g.stores.AI.Get(quokka)

	if ai.Behavior != "wander" || (ai.TargetX == 0 && ai.TargetY == 0) {
		t.Fatalf("quokka did not select wander target: %+v", ai)
	}

	after := g.rng.States()

	if after["ai"] == 0 || after["monster_hp"] != before["monster_hp"] {
		t.Fatalf("wander changed unrelated RNG streams: before %+v after %+v", before, after)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("wander target or RNG stream changed on save")
	}

	want, err := newMonsterDecisionSystem(g).chooseIntent(quokka)

	if err != nil {
		t.Fatal(err)
	}

	got, err := newMonsterDecisionSystem(loaded).chooseIntent(quokka)

	if err != nil || got != want || !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("wander continuation diverged: got %+v, %v; want %+v", got, err, want)
	}
}

func TestQuokkaFoeMemoryExpiresAfterSourceRange(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)

	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].PlaceActor(g.player, 14, 5); err != nil {
		t.Fatal(err)
	}

	if _, err := newMonsterDecisionSystem(g).chooseIntent(quokka); err != nil {
		t.Fatal(err)
	}

	ai, _ := g.stores.AI.Get(quokka)

	if ai.MemoryUntilAut < 250 || ai.MemoryUntilAut > 550 {
		t.Fatalf("animal memory deadline = %d", ai.MemoryUntilAut)
	}

	if err := g.levels[2].MoveActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}

	g.currentAut = Aut(ai.MemoryUntilAut - 1)

	if _, err := newMonsterDecisionSystem(g).chooseIntent(quokka); err != nil || ai.Behavior != "seek" {
		t.Fatalf("animal forgot too soon: %+v, %v", ai, err)
	}

	g.currentAut = Aut(ai.MemoryUntilAut)

	if _, err := newMonsterDecisionSystem(g).chooseIntent(quokka); err != nil ||
		ai.Behavior != "wander" || ai.MemoryUntilAut != 0 {
		t.Fatalf("animal retained expired foe memory: %+v, %v", ai, err)
	}
}

func TestLegacyZeroDeadlineSeekGetsFiniteMemory(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)

	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].PlaceActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}

	ai, _ := g.stores.AI.Get(quokka)
	ai.Behavior = "seek"
	ai.TargetX = 7
	ai.TargetY = 7

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	legacy := g.Snapshot()
	loaded, err := Restore(legacy, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(legacy, loaded.Snapshot()) {
		t.Fatal("legacy seek save changed during load")
	}

	if _, err := newMonsterDecisionSystem(loaded).chooseIntent(quokka); err != nil {
		t.Fatal(err)
	}

	loadedAI, _ := loaded.stores.AI.Get(quokka)

	if loadedAI.MemoryUntilAut != 250 {
		t.Fatalf("legacy seek memory deadline = %d, want 250", loadedAI.MemoryUntilAut)
	}

	loaded.currentAut = 250

	if _, err := newMonsterDecisionSystem(loaded).chooseIntent(quokka); err != nil ||
		loadedAI.Behavior != "wander" || loadedAI.MemoryUntilAut != 0 {
		t.Fatalf("legacy seek did not expire: %+v, %v", loadedAI, err)
	}
}

func TestRestoreRejectsImpossibleAnimalMemoryDeadline(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)

	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].PlaceActor(g.player, 14, 5); err != nil {
		t.Fatal(err)
	}

	if _, err := newMonsterDecisionSystem(g).chooseIntent(quokka); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	for _, deadline := range []int64{-1, 551} {
		bad := g.Snapshot()

		for i := range bad.Entities {
			if bad.Entities[i].ID == uint64(quokka) {
				bad.Entities[i].AI.MemoryUntilAut = deadline
			}
		}

		if loaded, err := Restore(bad, testCatalog(t)); err == nil {
			loaded.Close()
			t.Fatalf("invalid animal memory deadline %d accepted", deadline)
		}
	}
}

func TestQuokkaRoutesAroundCentralWallToRememberedTarget(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)

	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].PlaceActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].MoveActor(quokka, 9, 1); err != nil {
		t.Fatal(err)
	}

	ai, _ := g.stores.AI.Get(quokka)
	ai.Behavior = "seek"
	ai.TargetX = 7
	ai.TargetY = 1
	ai.MemoryUntilAut = 550
	first, err := newMonsterDecisionSystem(g).chooseIntent(quokka)

	if err != nil || first != (ecs.Intent{
		Kind: ecs.IntentMove,
		DY:   1,
	}) {
		t.Fatalf("first route step %+v, %v; want south around wall", first, err)
	}

	for turn := 0; turn < 12; turn++ {
		intent, err := newMonsterDecisionSystem(g).chooseIntent(quokka)

		if err != nil {
			t.Fatal(err)
		}

		if intent.Kind != ecs.IntentMove {
			t.Fatalf("route stalled on turn %d with %+v", turn, intent)
		}

		position, _ := g.stores.Positions.Get(quokka)

		if err := g.levels[2].MoveActor(quokka, position.X+intent.DX, position.Y+intent.DY); err != nil {
			t.Fatal(err)
		}

		g.currentAut += 10
		position, _ = g.stores.Positions.Get(quokka)

		if position.X <= 8 {
			return
		}
	}

	t.Fatal("quokka did not cross the central gap")
}

func TestFixedAnimalRouteAvoidsOccupantsAndUnreachableTarget(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	if err := level.MoveActor(g.player, 5, 1); err != nil {
		t.Fatal(err)
	}

	dx, dy, ok := level.RouteStep(4, 1, 6, 1, 0)

	if !ok || (dx == 1 && dy == 0) {
		t.Fatalf("route stepped into occupied tile: %d,%d found %v", dx, dy, ok)
	}

	second := g.levels[2]
	row := []byte(second.terrain[4])
	row[8] = '#'
	second.terrain[4] = string(row)

	if _, _, ok := second.RouteStep(9, 1, 7, 1, 0); ok {
		t.Fatal("route crossed a sealed central wall")
	}
}

func TestOffFloorMonsterDecisionIsRejected(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].PlaceActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}

	_, err := newMonsterDecisionSystem(g).chooseIntent(ratID(t, g))

	if err == nil {
		t.Fatal("off-floor monster received an ordinary turn")
	}
}
