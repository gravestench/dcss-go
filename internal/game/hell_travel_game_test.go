package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/terrain"
)

// The source chance family must put an actionable typed gate on a real
// Depths floor. Travel from it exercises generation, terrain projection,
// command preparation, and the persistent Vestibule in one path.
func TestGeneratedDepthsHellGateOpensVestibule(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	descendGeneratedTo(t, g, 15)

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 10000
	health.Current = health.Max

	depths := followBranch(t, g, g.levels[15], "BRANCH_DEPTHS")
	var gate point
	var found bool

	for y, row := range depths.Cells() {
		for x, feature := range row {
			if feature != terrain.EnterHell {
				continue
			}

			if _, occupied := depths.ActorAt(x, y); occupied {
				continue
			}

			gate = point{
				x: x,
				y: y,
			}

			found = true
			break
		}

		if found {
			break
		}
	}

	if !found {
		t.Fatalf("Depths:1 has no live Hell gate; vaults %v",
			depths.VaultIDs())
	}

	if err := depths.MoveActor(g.player, gate.x, gate.y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		g.hellState == nil ||
		position.LevelID != g.hellState.VestibuleLevelID {
		t.Fatalf("generated Hell gate did not open the Vestibule: %+v",
			position)
	}
}

// A source Hell arch opens the authored Vestibule, keeps that level after
// leaving, and remembers the exact outside gate across a save and reload.
func TestHellEntryReturnAndRestore(t *testing.T) {
	g := newGeneratedTestGame(t, 8101)

	origin := placePortalForTest(t, g, terrain.EnterHell)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	arrived, found := g.stores.Positions.Get(g.player)

	if !found || g.hellState == nil {
		t.Fatal("Hell entry did not create saved travel state")
	}

	vestibuleID := arrived.LevelID
	vestibule := g.levels[vestibuleID]

	if vestibule == nil ||
		vestibule.BranchID != "BRANCH_VESTIBULE" ||
		g.hellState.Return.X != origin.x ||
		g.hellState.Return.Y != origin.y {
		t.Fatalf("Hell entry lost its map or gate: %+v %+v",
			vestibule, g.hellState)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	placePortalForTest(t, restored, terrain.ExitHell)

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	back, found := restored.stores.Positions.Get(restored.player)

	if !found ||
		back.LevelID != 1 ||
		back.X != origin.x ||
		back.Y != origin.y ||
		restored.levels[vestibuleID] == nil {
		t.Fatalf("Hell return lost its saved gate or Vestibule: %+v", back)
	}

	second := placePortalForTest(t, restored, terrain.EnterHell)

	if second == origin {
		t.Fatal("second Hell gate did not use a different cell")
	}

	prior := restored.levels[vestibuleID]

	if _, err := restored.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	if restored.levels[vestibuleID] != prior ||
		restored.hellState.Return.X != second.x ||
		restored.hellState.Return.Y != second.y {
		t.Fatal("reentry rebuilt the Vestibule or kept the old return gate")
	}

	placePortalForTest(t, restored, terrain.ExitHell)

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	back, found = restored.stores.Positions.Get(restored.player)

	if !found ||
		back.LevelID != 1 ||
		back.X != second.x ||
		back.Y != second.y {
		t.Fatalf("Hell returned to the earlier gate: %+v", back)
	}
}

// The authored Vestibule gate opens a real persistent subbranch floor.
// Returning through its exit and revisiting must retain that same map.
func TestHellBranchGateOpensPersistentFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 8201)
	placePortalForTest(t, g, terrain.EnterHell)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	vestibule := g.levels[g.hellState.VestibuleLevelID]
	var gate point
	var found bool

	for y, row := range vestibule.Cells() {
		for x, feature := range row {
			if feature != terrain.EnterDis {
				continue
			}

			if _, occupied := vestibule.ActorAt(x, y); occupied {
				continue
			}

			gate = point{
				x: x,
				y: y,
			}

			found = true
			break
		}

		if found {
			break
		}
	}

	if !found {
		t.Fatal("authored Vestibule has no free Dis gate")
	}

	if err := vestibule.MoveActor(g.player, gate.x, gate.y); err != nil {
		t.Fatal(err)
	}

	// Dis's authored first floor can spawn lethal actors at the entrance.
	// This test follows travel and persistence, so keep combat out of scope.
	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max
	originalCurrent := health.Current

	health.Max = 10000
	health.Current = health.Max

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		position.LevelID == vestibule.ID ||
		len(g.hellState.Floors) != 1 {
		t.Fatalf("Dis gate did not open a persistent floor: %+v %+v",
			position, g.hellState)
	}

	disID := position.LevelID
	dis := g.levels[disID]

	if dis.BranchID != "BRANCH_DIS" ||
		dis.LocalDepth != 1 ||
		dis.width != 40 ||
		len(dis.terrain) != 35 {
		t.Fatalf("Dis:1 has wrong identity or compact geometry: %+v", dis)
	}

	health.Max = originalMax
	health.Current = originalCurrent

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("saved Dis:1 failed restore: %v", err)
	}

	floor := restored.hellState.Floors[0]
	restoredHealth, _ := restored.stores.Health.Get(restored.player)

	restoredHealth.Max = 10000
	restoredHealth.Current = restoredHealth.Max

	if err := restored.levels[disID].MoveActor(restored.player,
		floor.EntryX, floor.EntryY); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, found = restored.stores.Positions.Get(restored.player)

	if !found || position.LevelID != vestibule.ID {
		t.Fatalf("Dis exit did not return to Vestibule: %+v", position)
	}

	if err := restored.levels[vestibule.ID].MoveActor(restored.player,
		gate.x, gate.y); err != nil {
		t.Fatal(err)
	}

	prior := restored.levels[disID]

	if _, err := restored.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found = restored.stores.Positions.Get(restored.player)

	if !found ||
		position.LevelID != disID ||
		restored.levels[disID] != prior ||
		len(restored.hellState.Floors) != 1 {
		t.Fatalf("Dis revisit redrew or lost the saved floor: %+v", position)
	}

	var descent point
	found = false

	for y, row := range prior.Cells() {
		for x, feature := range row {
			if feature == terrain.StairsDown {
				descent = point{
					x: x,
					y: y,
				}

				found = true
				break
			}
		}

		if found {
			break
		}
	}

	if !found {
		t.Fatal("Dis:1 has no down stair")
	}

	if err := prior.MoveActor(restored.player, descent.x, descent.y); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found = restored.stores.Positions.Get(restored.player)

	if !found ||
		position.LevelID == disID ||
		restored.levels[position.LevelID].LocalDepth != 2 ||
		len(restored.hellState.Floors) != 2 {
		t.Fatalf("Dis descent did not open its second depth: %+v", position)
	}
}

// Gate dispatch comes from Lua branch metadata, so all four source gates
// must lead to the matching compact floor without a Go branch switch.
func TestHellFourBranchGates(t *testing.T) {
	g := newGeneratedTestGame(t, 8202)
	placePortalForTest(t, g, terrain.EnterHell)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max
	originalCurrent := health.Current

	health.Max = 10000
	health.Current = health.Max

	vestibuleID := g.hellState.VestibuleLevelID
	vestibule := g.levels[vestibuleID]
	gates := []struct {
		feature terrain.ID
		branch  string
		escape  terrain.ID
	}{
		{
			feature: terrain.EnterDis,
			branch:  "BRANCH_DIS",
			escape:  terrain.ExitDis,
		},

		{
			feature: terrain.EnterGehenna,
			branch:  "BRANCH_GEHENNA",
			escape:  terrain.ExitGehenna,
		},

		{
			feature: terrain.EnterCocytus,
			branch:  "BRANCH_COCYTUS",
			escape:  terrain.ExitCocytus,
		},

		{
			feature: terrain.EnterTartarus,
			branch:  "BRANCH_TARTARUS",
			escape:  terrain.ExitTartarus,
		},
	}

	for _, gate := range gates {
		t.Run(gate.branch, func(t *testing.T) {
			var site point
			found := false

			for y, row := range vestibule.Cells() {
				for x, feature := range row {
					if feature != gate.feature {
						continue
					}

					site = point{
						x: x,
						y: y,
					}

					found = true
					break
				}

				if found {
					break
				}
			}

			if !found {
				t.Fatal("Vestibule gate is missing")
			}

			if blocker, occupied := vestibule.ActorAt(site.x, site.y); occupied {
				moved := false

				for y, row := range vestibule.Cells() {
					for x, feature := range row {
						if feature != terrain.Floor {
							continue
						}

						if _, taken := vestibule.ActorAt(x, y); taken {
							continue
						}

						if err := vestibule.MoveActor(blocker, x, y); err != nil {
							t.Fatal(err)
						}

						moved = true
						break
					}

					if moved {
						break
					}
				}

				if !moved {
					t.Fatal("Vestibule has no free site for gate blocker")
				}
			}

			if err := vestibule.MoveActor(g.player, site.x, site.y); err != nil {
				t.Fatal(err)
			}

			if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
				t.Fatal(err)
			}

			position, found := g.stores.Positions.Get(g.player)
			floor := g.levels[position.LevelID]

			if !found ||
				floor.BranchID != gate.branch ||
				floor.LocalDepth != 1 ||
				floor.width != 40 ||
				len(floor.terrain) != 35 {
				t.Fatalf("gate opened wrong compact floor: %+v", floor)
			}

			down := 0
			exits := 0

			for _, row := range floor.Cells() {
				for _, feature := range row {
					if feature == terrain.StairsDown {
						down++
					}

					if feature == gate.escape {
						exits++
					}
				}
			}

			if down != 1 || exits < 1 {
				t.Fatalf("Hell floor has %d descents and %d exits", down, exits)
			}

			var entry save.HellFloorRecord

			for _, candidate := range g.hellState.Floors {
				if candidate.BranchID == gate.branch {
					entry = candidate
					break
				}
			}

			if entry.LevelID != floor.ID {
				t.Fatal("gate did not save the new floor")
			}

			if err := floor.MoveActor(g.player, entry.EntryX,
				entry.EntryY); err != nil {
				t.Fatal(err)
			}

			if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
				t.Fatal(err)
			}

			position, found = g.stores.Positions.Get(g.player)

			if !found || position.LevelID != vestibuleID {
				t.Fatalf("branch exit missed Vestibule: %+v", position)
			}
		})
	}

	health.Max = originalMax
	health.Current = originalCurrent

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("four saved Hell branches failed restore: %v", err)
	}
}

// Directionally wrong commands on Hell arches are free and never generate
// a floor or create a return record.
func TestHellGateWrongDirectionSpendsNoTime(t *testing.T) {
	g := newGeneratedTestGame(t, 8102)
	placePortalForTest(t, g, terrain.EnterHell)

	result, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || g.hellState != nil {
		t.Fatal("wrong Hell entry direction spent time or changed session")
	}
}

// A monster may move onto the remembered outside gate while the player is
// away. Leaving Hell must find nearby floor without displacing that actor.
func TestHellReturnFindsSafeLanding(t *testing.T) {
	g := newGeneratedTestGame(t, 8103)
	origin := placePortalForTest(t, g, terrain.EnterHell)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	blocker := spawnWormForTest(t, g, 1)

	if err := g.levels[1].MoveActor(blocker, origin.x, origin.y); err != nil {
		t.Fatal(err)
	}

	placePortalForTest(t, g, terrain.ExitHell)

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)
	actor, occupied := g.levels[1].ActorAt(origin.x, origin.y)

	if !found ||
		position.LevelID != 1 ||
		(position.X == origin.x && position.Y == origin.y) ||
		!occupied || actor != blocker {
		t.Fatalf("Hell return displaced the gate blocker: %+v", position)
	}
}

// A malformed saved return pointer must fail at restore, before a future
// exit command can dereference it or strand the player in the Vestibule.
func TestHellRestoreRejectsMissingReturnSite(t *testing.T) {
	g := newGeneratedTestGame(t, 8104)
	placePortalForTest(t, g, terrain.EnterHell)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()

	snapshot.HellState.Return = nil

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("restore accepted a Hell state without an outside return site")
	}
}

// Vestibule is one authored level, so a second saved branch level cannot
// be treated as an ordinary generated floor outside the Hell validator.
func TestHellRestoreRejectsExtraVestibuleFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 8106)
	placePortalForTest(t, g, terrain.EnterHell)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	var found bool

	for index := range snapshot.Levels {
		if snapshot.Levels[index].ID == g.hellState.VestibuleLevelID {
			copy := snapshot.Levels[index]

			copy.ID = 9001

			snapshot.Levels = append(snapshot.Levels, copy)
			found = true
			break
		}
	}

	if !found {
		t.Fatal("snapshot has no Vestibule to duplicate")
	}

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("restore accepted an extra Vestibule floor")
	}
}

// A bad modded generator may consume random draws before Go rejects its
// floor record. Failed entry must leave the old game exactly save-equivalent.
func TestHellEntryFailureRollsBackSession(t *testing.T) {
	rules, err := modfs.Load("testdata/hell-generation-failure-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(8105, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	placePortalForTest(t, g, terrain.EnterHell)

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	before, err := json.Marshal(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.Step(Command{Kind: CommandDownstairs})

	if err == nil {
		t.Fatal("malformed Hell floor was accepted")
	}

	if !strings.Contains(err.Error(), "saved Vestibule") {
		t.Fatalf("wrong-ID floor failed before Hell validation: %v", err)
	}

	after, err := json.Marshal(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) || g.hellState != nil {
		t.Fatal("failed Hell entry changed saved game state")
	}
}
