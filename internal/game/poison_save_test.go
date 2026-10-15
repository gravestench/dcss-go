package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func TestPoisonLivesOnPlayerAndSurvivesSnapshot(t *testing.T) {
	g := newStepGame(t)
	poison := ecs.Poison{
		AmountScaled:    6250,
		SourceMonsterID: "MONS_ADDER",
	}

	if _, err := g.stores.Poison.Set(g.player, poison); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	var saved *ecs.Poison

	for i := range snapshot.Entities {
		if snapshot.Entities[i].ID == snapshot.PlayerID {
			saved = snapshot.Entities[i].Poison
		}
	}

	if saved == nil || saved.AmountScaled != poison.AmountScaled {
		t.Fatalf("snapshot lost poison: %+v", saved)
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	restoredPoison, found := restored.stores.Poison.Get(restored.player)

	if !found || *restoredPoison != poison {
		t.Fatalf("restored poison = %+v, present %v", restoredPoison, found)
	}

	saved.AmountScaled = 9000

	if restoredPoison.AmountScaled != poison.AmountScaled {
		t.Fatal("restored poison aliases save snapshot")
	}

	if g.View().PoisonAmountScaled != poison.AmountScaled {
		t.Fatal("view lost player poison")
	}
}

func TestRestoreRejectsInvalidPoisonOwnershipAndValue(t *testing.T) {
	g := newStepGame(t)

	tests := []struct {
		name   string
		mutate func(*save.Snapshot)
	}{
		{
			name: "less than one poison point",
			mutate: func(snapshot *save.Snapshot) {
				playerSaveRecord(snapshot).Poison = &ecs.Poison{
					AmountScaled:    999,
					SourceMonsterID: "MONS_ADDER",
				}
			},
		},

		{
			name: "above source integer limit",
			mutate: func(snapshot *save.Snapshot) {
				playerSaveRecord(snapshot).Poison = &ecs.Poison{
					AmountScaled:    2147483648,
					SourceMonsterID: "MONS_ADDER",
				}
			},
		},

		{
			name: "wrong poison source",
			mutate: func(snapshot *save.Snapshot) {
				playerSaveRecord(snapshot).Poison = &ecs.Poison{
					AmountScaled:    4000,
					SourceMonsterID: "MONS_RAT",
				}
			},
		},

		{
			name: "monster owns poison",
			mutate: func(snapshot *save.Snapshot) {
				for i := range snapshot.Entities {
					if snapshot.Entities[i].AI != nil {
						snapshot.Entities[i].Poison = &ecs.Poison{
							AmountScaled:    4000,
							SourceMonsterID: "MONS_ADDER",
						}

						break
					}
				}
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			snapshot := g.Snapshot()
			test.mutate(&snapshot)

			if restored, err := Restore(snapshot); err == nil {
				restored.Close()
				t.Fatal("accepted invalid poison save")
			}
		})
	}
}

func playerSaveRecord(snapshot *save.Snapshot) *save.EntityRecord {
	for i := range snapshot.Entities {
		if snapshot.Entities[i].ID == snapshot.PlayerID {
			return &snapshot.Entities[i]
		}
	}

	return nil
}
