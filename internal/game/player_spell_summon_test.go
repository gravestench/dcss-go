package game

import (
	"math"
	"reflect"
	"testing"

	"crawl/internal/character"
	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

func grantSummonForSavedFixture(t *testing.T, g *Game, id string) func() {
	t.Helper()
	progress, _ := g.stores.Progression.Get(g.player)
	attributes, _ := g.stores.Attributes.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)
	health, _ := g.stores.Health.Get(g.player)
	skills, _ := g.stores.Skills.Get(g.player)
	startProgress := *progress
	startAttributes := *attributes
	startMagic := *magic
	startHealth := *health
	startSkills := append([]character.Skill(nil), skills.Entries...)
	grantSummonForTest(t, g, id)

	return func() {
		earnedXP := progress.TotalXP

		*progress = startProgress
		progress.TotalXP = earnedXP
		*attributes = startAttributes
		*magic = startMagic
		*health = startHealth
		skills.Entries = startSkills
	}
}

func movePlayerToOpenSummoningRoom(t *testing.T, g *Game) {
	t.Helper()
	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]

	for y := 3; y < len(level.terrain)-3; y++ {
		for x := 3; x < level.width-4; x++ {
			open := true

			for dy := -1; dy <= 1; dy++ {
				for dx := -1; dx <= 3; dx++ {
					if !level.Walkable(x+dx, y+dy) {
						open = false
					}
				}
			}

			if !open {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if _, occupied := level.ActorAt(x+2, y); occupied {
				continue
			}

			if err := level.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			return
		}
	}

	t.Fatal("no open summoning room")
}

func TestSummonForestChangesTypedTerrainAndRestores(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	resetStats := grantSummonForSavedFixture(t, g, "SPELL_SUMMON_FOREST")
	movePlayerToOpenSummoningRoom(t, g)

	before := g.levels[1].Cells()
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUMMON_FOREST",
	})

	if err != nil ||
		result.Spent == 0 {
		t.Fatalf("Forest cast = %+v, %v", result.Events, err)
	}

	markers := g.scripts.Components()["world.temporary_terrain"]

	if len(markers.Entities()) == 0 {
		t.Fatal("Forest left no timed terrain markers")
	}

	if reflect.DeepEqual(before, g.levels[1].Cells()) {
		t.Fatal("Forest did not change typed terrain")
	}

	resetStats()
	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.levels[1].Cells(), restored.levels[1].Cells()) ||
		len(restored.scripts.Components()["world.temporary_terrain"].Entities()) == 0 {
		t.Fatal("Forest terrain or markers changed across restore")
	}

	marker := restored.scripts.Components()["world.temporary_terrain"].Entities()[0]
	markerState, _ := restored.scripts.Components()["world.temporary_terrain"].Get(marker)
	expiry, _ := markerState.Get("expires_aut")

	restored.currentAut = Aut(expiry.(int64))

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, restored.levels[1].Cells()) {
		t.Fatal("Forest failed to restore original terrain")
	}
}

func TestTerrainSummonsRejectCrampedCellWithoutTime(t *testing.T) {
	for _, id := range []string{
		"SPELL_SUMMON_FOREST",
		"SPELL_MALIGN_GATEWAY",
	} {
		t.Run(id, func(t *testing.T) {
			g := newStepGame(t)
			grantSummonForTest(t, g, id)
			position, _ := g.stores.Positions.Get(g.player)
			level := g.levels[position.LevelID]

			for dy := -1; dy <= 1; dy++ {
				for dx := -1; dx <= 1; dx++ {
					if dx == 0 && dy == 0 {
						continue
					}

					if err := level.SetCell(position.X+dx, position.Y+dy,
						"DNGN_ROCK_WALL"); err != nil {
						t.Fatal(err)
					}
				}
			}

			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			before := g.Snapshot()
			result, err := g.Step(Command{
				Kind:    CommandForceCast,
				SpellID: id,
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent != 0 || g.currentAut != Aut(before.CurrentAut) {
				t.Fatalf("cramped %s spent %d aut", id, result.Spent)
			}
		})
	}
}

func TestMalignGatewayOwnsPortalAndTentacleAcrossRestore(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	resetStats := grantSummonForSavedFixture(t, g, "SPELL_MALIGN_GATEWAY")
	movePlayerToOpenSummoningRoom(t, g)

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_MALIGN_GATEWAY",
	})

	if err != nil ||
		result.Spent == 0 {
		t.Fatalf("Gateway cast = %+v, %v", result.Events, err)
	}

	markers := g.scripts.Components()["magic.summon_gateway"]

	if len(markers.Entities()) != 1 {
		t.Fatalf("Gateway markers = %d", len(markers.Entities()))
	}

	state, _ := markers.Get(markers.Entities()[0])
	xValue, _ := state.Get("x")
	yValue, _ := state.Get("y")
	x, y := int(xValue.(int64)), int(yValue.(int64))

	if got := g.levels[1].terrain[y][x]; got != "DNGN_MALIGN_GATEWAY" {
		t.Fatalf("portal feature = %s", got)
	}

	resetStats()
	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	for i := 0; i < 3; i++ {
		if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	var spawnedTentacle akara.Entity

	for _, actor := range restored.stores.Actors.Entities() {
		kind, exists := restored.stores.Actors.Get(actor)

		if exists && kind.KindID == "MONS_ELDRITCH_TENTACLE" {
			spawnedTentacle = actor
			break
		}
	}

	if spawnedTentacle == 0 {
		t.Fatal("gateway did not produce a tentacle")
	}

	var headX int
	var headY int
	connected := false

	for _, direction := range [][2]int{
		{
			1,
			0,
		},

		{
			-1,
			0,
		},

		{
			0,
			1,
		},

		{
			0,
			-1,
		},

		{
			1,
			1,
		},

		{
			-1,
			-1,
		},

		{
			1,
			-1,
		},

		{
			-1,
			1,
		},
	} {
		mx, my := x+direction[0], y+direction[1]
		hx, hy := x+2*direction[0], y+2*direction[1]

		if !restored.levels[1].Walkable(mx, my) ||
			!restored.levels[1].Walkable(hx, hy) {
			continue
		}

		if _, occupied := restored.levels[1].ActorAt(mx, my); occupied {
			continue
		}

		if _, occupied := restored.levels[1].ActorAt(hx, hy); occupied {
			continue
		}

		headX, headY = hx, hy
		connected = true
		break
	}

	if !connected {
		t.Fatal("gateway has no free two-cell connector path")
	}

	if err := restored.levels[1].MoveActor(spawnedTentacle, headX, headY); err != nil {
		t.Fatal(err)
	}

	energy, _ := restored.stores.MonsterEnergy.Get(spawnedTentacle)

	energy.Points = -1000

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	energy.Points = 0

	segments := restored.scripts.Components()["magic.summon_segment"].Entities()

	if len(segments) == 0 {
		t.Fatal("gateway tentacle did not grow a connector segment")
	}

	segmentActor := segments[0]
	segmentPosition, found := restored.stores.Positions.Get(segmentActor)

	if !found ||
		math.Max(math.Abs(float64(segmentPosition.X-x)),
			math.Abs(float64(segmentPosition.Y-y))) > 1 ||
		math.Max(math.Abs(float64(segmentPosition.X-headX)),
			math.Abs(float64(segmentPosition.Y-headY))) > 1 {
		t.Fatalf("gateway connector does not bridge portal and head: %+v", segmentPosition)
	}

	if kind, _ := restored.stores.Actors.Get(segmentActor); kind.KindID !=
		"MONS_ELDRITCH_TENTACLE_SEGMENT" {
		t.Fatalf("gateway connector kind = %s", kind.KindID)
	}

	occupied, err := Restore(restored.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer occupied.Close()
	tentacle := spawnedTentacle

	if _, found := occupied.stores.Actors.Get(tentacle); !found {
		t.Fatal("restored portal lost its tentacle")
	}

	if _, found := occupied.stores.Actors.Get(segmentActor); !found {
		t.Fatal("restored tentacle lost its connector segment")
	}

	severed, err := Restore(restored.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer severed.Close()
	segmentHealth, _ := severed.stores.Health.Get(segmentActor)

	segmentHealth.Current = 0

	for i := 0; i < 3; i++ {
		if _, err := severed.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if _, found := severed.stores.Actors.Get(spawnedTentacle); found {
		t.Fatal("severing a connector left the tentacle head alive")
	}

	health, _ := occupied.stores.Health.Get(tentacle)

	health.Current = 0

	for i := 0; i < 2; i++ {
		if _, err := occupied.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if got := occupied.levels[1].terrain[y][x]; got != "DNGN_FLOOR" {
		t.Fatalf("portal remained after tentacle death: %s", got)
	}

	if _, found := occupied.stores.Actors.Get(segmentActor); found {
		t.Fatal("tentacle connector survived head death")
	}
}

func TestPhantomMirrorCopiesVisibleMonster(t *testing.T) {
	g := newStepGame(t)
	grantSummonForTest(t, g, "SPELL_PHANTOM_MIRROR")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 2

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_PHANTOM_MIRROR",
		DX:      3,
	})

	if err != nil ||
		result.Spent == 0 {
		t.Fatalf("mirror cast = %+v, %v", result.Events, err)
	}

	store := g.scripts.Components()["magic.summon"]

	if len(store.Entities()) != 1 {
		t.Fatalf("mirrored actors = %d", len(store.Entities()))
	}

	clone := store.Entities()[0]
	actor, _ := g.stores.Actors.Get(clone)
	copyHealth, _ := g.stores.Health.Get(clone)

	if actor.KindID != "MONS_RAT" || copyHealth.Max != 2 {
		t.Fatalf("mirror created %s with %d HP", actor.KindID, copyHealth.Max)
	}
}

func TestNecromancyAurasRaiseKilledMonster(t *testing.T) {
	for _, tc := range []struct {
		spellID string
		kindID  string
	}{
		{
			"SPELL_DEATH_CHANNEL",
			"MONS_SPECTRAL_THING",
		},

		{
			"SPELL_ANIMATE_DEAD",
			"MONS_ZOMBIE",
		},
	} {
		t.Run(tc.spellID, func(t *testing.T) {
			g := newStepGame(t)
			resetStats := grantSummonForSavedFixture(t, g, tc.spellID)
			result, err := g.Step(Command{
				Kind:    CommandForceCast,
				SpellID: tc.spellID,
			})

			if err != nil ||
				result.Spent == 0 {
				t.Fatalf("aura cast = %+v, %v", result.Events, err)
			}

			rat := ratID(t, g)

			if err := g.levels[1].MoveActor(rat, 4, 1); err != nil {
				t.Fatal(err)
			}

			if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
				t.Fatal(err)
			}

			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			health, _ := g.stores.Health.Get(rat)

			health.Current = 1
			var strike StepResult

			for attempt := 0; attempt < 20 && g.world.EntityExists(rat); attempt++ {
				playerHealth, _ := g.stores.Health.Get(g.player)

				playerHealth.Current = playerHealth.Max
				strike, err = g.Step(Command{
					Kind: CommandMove,
					DX:   1,
				})

				if err != nil ||
					strike.Spent == 0 {
					t.Fatalf("killing strike = %+v, %v", strike.Events, err)
				}
			}

			if g.world.EntityExists(rat) {
				t.Fatalf("rat survived twenty attacks: %+v", strike.Events)
			}

			found := false

			for _, summoned := range g.scripts.Components()["magic.summon"].Entities() {
				actor, _ := g.stores.Actors.Get(summoned)

				if actor.KindID == tc.kindID {
					found = true
				}
			}

			if !found {
				aura, _ := g.scripts.Components()["magic.summon_necromancy"].Get(g.player)
				progress, _ := g.stores.Progression.Get(g.player)
				t.Fatalf("%s produced no %s; events %+v; rat alive %t; aura=%v xp=%d",
					tc.spellID, tc.kindID, strike.Events, g.world.EntityExists(rat),
					aura, progress.TotalXP)
			}

			resetStats()
			loaded, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatal(err)
			}

			defer loaded.Close()

			if len(loaded.scripts.Components()["magic.summon"].Entities()) == 0 {
				t.Fatal("raised undead lost across save")
			}

			if tc.spellID == "SPELL_ANIMATE_DEAD" {
				grantSummonForTest(t, loaded, tc.spellID)
				recast, err := loaded.Step(Command{
					Kind:    CommandForceCast,
					SpellID: tc.spellID,
				})

				if err != nil ||
					recast.Spent == 0 {
					t.Fatalf("Animate Dead recast = %+v, %v", recast.Events, err)
				}

				for _, undead := range loaded.scripts.Components()["magic.summon"].Entities() {
					state, _ := loaded.scripts.Components()["magic.summon"].Get(undead)
					origin, _ := state.Get("source_id")

					if origin == tc.spellID {
						t.Fatal("Animate Dead recast retained an older zombie")
					}
				}
			}
		})
	}
}

func grantSummonForTest(t *testing.T, g *Game, id string) {
	t.Helper()

	store := g.scripts.Components()["character.spell"]
	var entity akara.Entity

	for _, candidate := range store.Entities() {
		record, _ := store.Get(candidate)
		spellID, _ := record.Get("spell_id")
		owner, _ := record.Get("owner")

		if spellID == id && owner == g.player {
			entity = candidate
			break
		}
	}

	if entity == 0 {
		created, createErr := g.world.CreateEntity()

		if createErr != nil {
			t.Fatal(createErr)
		}

		entity = created
	}

	_, err := store.Set(entity, map[string]any{
		"owner":        g.player,
		"spell_id":     id,
		"in_library":   true,
		"known_slot":   int64(20),
		"letter_slot":  int64(20),
		"future_level": int64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	magic, _ := g.stores.Magic.Get(g.player)

	magic.Current = 80
	magic.Max = 80

	skills, _ := g.stores.Skills.Get(g.player)
	hasNecromancy := false

	for index := range skills.Entries {
		skill := &skills.Entries[index]

		if skill.ID == "SK_NECROMANCY" {
			hasNecromancy = true
		}

		if skill.ID == "SK_SUMMONINGS" ||
			skill.ID == "SK_SPELLCASTING" ||
			skill.ID == "SK_NECROMANCY" ||
			skill.ID == "SK_CONJURATIONS" ||
			skill.ID == "SK_HEXES" ||
			skill.ID == "SK_ICE_MAGIC" ||
			skill.ID == "SK_FIRE_MAGIC" ||
			skill.ID == "SK_AIR_MAGIC" ||
			skill.ID == "SK_EARTH_MAGIC" {
			skill.Level = 27
		}
	}

	if !hasNecromancy {
		skills.Entries = append(skills.Entries, character.Skill{
			ID:    "SK_NECROMANCY",
			Level: 27,
		})
	}
}

func TestSmallMammalSummonHasOwnerAndTimeout(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUMMON_SMALL_MAMMAL",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("summon spell did not spend a turn")
	}

	store, found := g.scripts.Components()["magic.summon"]

	if !found {
		t.Fatal("summon ownership schema was not registered")
	}

	if len(store.Entities()) != 1 {
		t.Fatalf("got %d summoned actors, want one; events: %+v", len(store.Entities()), result.Events)
	}

	entity := store.Entities()[0]
	state, _ := store.Get(entity)
	owner, _ := state.Get("owner")
	spellID, _ := state.Get("source_id")
	expires, _ := state.Get("expires_aut")

	if owner != g.player ||
		spellID != "SPELL_SUMMON_SMALL_MAMMAL" ||
		expires.(int64) <= int64(g.currentAut) {
		t.Fatalf("invalid summon state: owner=%v spell=%v expires=%v aut=%d",
			owner, spellID, expires, g.currentAut)
	}

	if _, exists := g.stores.Positions.Get(entity); !exists {
		t.Fatal("summoned actor was not placed on the map")
	}

	if _, exists := g.stores.MonsterEnergy.Get(entity); !exists {
		t.Fatal("summoned actor cannot take scheduled actions")
	}

	if _, hasSavedRole := g.stores.AI.Get(entity); !hasSavedRole {
		t.Fatal("summoned actor lacks the saved monster role")
	}
}

func TestSmallMammalSummonSurvivesRestore(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUMMON_SMALL_MAMMAL",
	}); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	store := restored.scripts.Components()["magic.summon"]

	if len(store.Entities()) != 1 {
		t.Fatalf("restored %d summons, want one", len(store.Entities()))
	}

	state, _ := store.Get(store.Entities()[0])
	owner, _ := state.Get("owner")
	spellID, _ := state.Get("source_id")

	if owner != restored.player || spellID != "SPELL_SUMMON_SMALL_MAMMAL" {
		t.Fatalf("restored summon link = %v, %v", owner, spellID)
	}

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
}

func TestAlliedSummonUsesMonsterDecisionAndRestoresSeek(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	rollback := grantSummonForSavedFixture(t, g, "SPELL_SUMMON_ICE_BEAST")
	movePlayerToOpenSummoningRoom(t, g)

	if _, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUMMON_ICE_BEAST",
	}); err != nil {
		t.Fatal(err)
	}

	summons := g.scripts.Components()["magic.summon"].Entities()

	if len(summons) != 1 {
		t.Fatalf("got %d allied summons", len(summons))
	}

	ally := summons[0]
	position, _ := g.stores.Positions.Get(ally)
	level := g.levels[position.LevelID]
	var destinationX int
	var destinationY int
	found := false

	for _, direction := range [][2]int{
		{
			1,
			0,
		},

		{
			-1,
			0,
		},

		{
			0,
			1,
		},

		{
			0,
			-1,
		},

		{
			1,
			1,
		},

		{
			-1,
			-1,
		},

		{
			1,
			-1,
		},

		{
			-1,
			1,
		},
	} {
		x := position.X + 2*direction[0]
		y := position.Y + 2*direction[1]
		midX := position.X + direction[0]
		midY := position.Y + direction[1]

		if !level.Walkable(x, y) || !level.Walkable(midX, midY) {
			continue
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			continue
		}

		if _, occupied := level.ActorAt(midX, midY); occupied {
			continue
		}

		destinationX, destinationY = x, y
		found = true
		break
	}

	if !found {
		t.Fatal("no open two-step path for allied pursuit")
	}

	var worm akara.Entity

	for _, candidate := range g.stores.Actors.Entities() {
		if candidate == g.player || candidate == ally {
			continue
		}

		candidatePosition, exists := g.stores.Positions.Get(candidate)

		if exists && candidatePosition.LevelID == position.LevelID {
			worm = candidate
			break
		}
	}

	if worm == 0 {
		t.Fatal("no existing hostile for allied pursuit")
	}

	if err := level.MoveActor(worm, destinationX, destinationY); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	ai, found := g.stores.AI.Get(ally)

	if !found ||
		ai.Behavior != "seek" ||
		ai.TargetX == 0 || ai.TargetY == 0 {
		t.Fatalf("allied AI did not acquire a target: %+v", ai)
	}

	if _, found := g.stores.Positions.Get(ally); !found {
		t.Fatal("ally lost its position after shared movement")
	}

	rollback()
	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
}

func TestAnimateArmourCreatesDefiningItem(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	grantSummonForTest(t, g, "SPELL_ANIMATE_ARMOUR")

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_ANIMATE_ARMOUR",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Animate Armour spent no time")
	}

	store := g.scripts.Components()["magic.summon"]

	if len(store.Entities()) != 1 {
		t.Fatalf("got %d animated armours; events: %+v", len(store.Entities()), result.Events)
	}

	creature := store.Entities()[0]
	actor, _ := g.stores.Actors.Get(creature)

	if actor.KindID != "MONS_ANIMATED_ARMOUR" {
		t.Fatalf("summoned %s, want animated armour", actor.KindID)
	}

	found := false

	for _, item := range g.stores.CarriedBy.Entities() {
		carrier, _ := g.stores.CarriedBy.Get(item)

		if carrier.Holder == creature {
			defining, _ := g.stores.Items.Get(item)
			found = defining.KindID == "ARM_ROBE"
		}
	}

	if !found {
		t.Fatal("animated armour has no summoned robe copy")
	}
}

func TestSimulacrumRejectsInvalidTargetWithoutTime(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	grantSummonForTest(t, g, "SPELL_SIMULACRUM")

	before := g.currentAut
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SIMULACRUM",
		DX:      -1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || g.currentAut != before {
		t.Fatalf("invalid Simulacrum target spent %d aut", result.Spent)
	}
}

func TestSimulacrumRemembersBaseMonster(t *testing.T) {
	g, err := newScenario(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_SUMMONER",
	}, "", "Tester", ordinaryMonsterScenarioID)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	grantSummonForTest(t, g, "SPELL_SIMULACRUM")

	rat := ratID(t, g)
	playerPosition, _ := g.stores.Positions.Get(g.player)
	ratPosition, _ := g.stores.Positions.Get(rat)
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SIMULACRUM",
		DX:      ratPosition.X - playerPosition.X,
		DY:      ratPosition.Y - playerPosition.Y,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Simulacrum spent no time")
	}

	mark := g.scripts.Components()["magic.summon_mark"]

	if _, found := mark.Get(rat); !found {
		t.Fatalf("rat was not marked; events: %+v", result.Events)
	}

	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 0

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	derived := g.scripts.Components()["magic.summon_simulacrum"]

	if len(derived.Entities()) == 0 {
		t.Fatal("marked rat left no simulacrum")
	}

	for _, entity := range derived.Entities() {
		state, _ := derived.Get(entity)
		base, _ := state.Get("base_kind_id")
		summon, _ := g.scripts.Components()["magic.summon"].Get(entity)
		expires, _ := summon.Get("expires_aut")

		if base != "MONS_RAT" || expires != int64(0) {
			t.Fatalf("derived form = %v with expiry %v", base, expires)
		}
	}
}

func TestLightningSpireKeepsPowerAndActs(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	grantSummonForTest(t, g, "SPELL_SUMMON_LIGHTNING_SPIRE")

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUMMON_LIGHTNING_SPIRE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Lightning Spire spent no time")
	}

	store := g.scripts.Components()["magic.summon_spire"]

	if len(store.Entities()) != 1 {
		t.Fatalf("got %d lightning spires; events: %+v", len(store.Entities()), result.Events)
	}

	state, _ := store.Get(store.Entities()[0])
	power, _ := state.Get("power")

	if power.(int64) <= 0 {
		t.Fatalf("spire lost its spell power: %v", power)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
}

func TestDragonCallKeepsTimedPlayerStatus(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	grantSummonForTest(t, g, "SPELL_DRAGON_CALL")

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_DRAGON_CALL",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Dragon Call spent no time")
	}

	status, found := g.scripts.Components()["magic.summon_dragon_call"].Get(g.player)

	if !found {
		t.Fatal("Dragon Call did not retain its duration")
	}

	ends, _ := status.Get("ends_aut")
	next, _ := status.Get("next_aut")

	if ends.(int64) <= int64(g.currentAut) || next.(int64) <= int64(g.currentAut) {
		t.Fatalf("Dragon Call timers expired immediately: ends=%v next=%v", ends, next)
	}
}

func TestFulminantPrismPlacesExactCellAndCharges(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	grantSummonForTest(t, g, "SPELL_FULMINANT_PRISM")
	before := g.currentAut
	occupied, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_FULMINANT_PRISM",
	})

	if err != nil {
		t.Fatal(err)
	}

	if occupied.Spent != 0 || g.currentAut != before {
		t.Fatal("prism cast onto player spent time")
	}

	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]
	var dx int
	var dy int
	found := false

	for x := -4; x <= 4 && !found; x++ {
		for y := -4; y <= 4; y++ {
			if x == 0 && y == 0 {
				continue
			}

			if !level.Walkable(position.X+x, position.Y+y) {
				continue
			}

			if _, occupied := level.ActorAt(position.X+x, position.Y+y); occupied {
				continue
			}

			dx = x
			dy = y
			found = true
			break
		}
	}

	if !found {
		t.Fatal("no open prism cell within source range")
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_FULMINANT_PRISM",
		DX:      dx,
		DY:      dy,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Fulminant Prism did not spend time")
	}

	store := g.scripts.Components()["magic.summon_construct"]

	if len(store.Entities()) != 1 {
		t.Fatalf("got %d prisms; events: %+v", len(store.Entities()), result.Events)
	}

	prism := store.Entities()[0]
	placed, _ := g.stores.Positions.Get(prism)

	if placed.X != position.X+dx || placed.Y != position.Y+dy {
		t.Fatalf("prism placed at (%d,%d), wanted (%d,%d)",
			placed.X, placed.Y, position.X+dx, position.Y+dy)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
}

func TestFoxfireAndBallLightningCreateShortLivedActors(t *testing.T) {
	for _, spell := range []struct {
		id   string
		kind string
		want int
	}{
		{
			"SPELL_FOXFIRE",
			"MONS_FOXFIRE",
			2,
		},

		{
			"SPELL_CONJURE_BALL_LIGHTNING",
			"MONS_BALL_LIGHTNING",
			3,
		},
	} {
		t.Run(spell.id, func(t *testing.T) {
			g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()
			grantSummonForTest(t, g, spell.id)

			result, err := g.Step(Command{
				Kind:    CommandForceCast,
				SpellID: spell.id,
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent == 0 {
				t.Fatal("construct spell did not spend time")
			}

			store := g.scripts.Components()["magic.summon_construct"]

			if got := len(store.Entities()); got == 0 || got > spell.want {
				t.Fatalf("got %d constructs, want 1..%d; events: %+v",
					got, spell.want, result.Events)
			}

			for _, entity := range store.Entities() {
				actor, _ := g.stores.Actors.Get(entity)

				if actor.KindID != spell.kind {
					t.Fatalf("construct kind = %s, want %s", actor.KindID, spell.kind)
				}
			}

			if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func TestGuardianGolemBondsNearbySummon(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	grantSummonForTest(t, g, "SPELL_SUMMON_GUARDIAN_GOLEM")

	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]
	found := false

	for y := 1; y < len(level.terrain)-1 && !found; y++ {
		for x := 1; x < level.width-1; x++ {
			if !level.Walkable(x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			free := 0

			for dy := -1; dy <= 1; dy++ {
				for dx := -1; dx <= 1; dx++ {
					if dx == 0 && dy == 0 {
						continue
					}

					if level.Walkable(x+dx, y+dy) {
						if _, occupied := level.ActorAt(x+dx, y+dy); !occupied {
							free++
						}
					}
				}
			}

			if free >= 3 {
				if err := level.MoveActor(g.player, x, y); err != nil {
					t.Fatal(err)
				}

				found = true
				break
			}
		}
	}

	if !found {
		t.Fatal("no open cell for two nearby summons")
	}

	for _, id := range []string{
		"SPELL_SUMMON_SMALL_MAMMAL",
		"SPELL_SUMMON_GUARDIAN_GOLEM",
	} {
		result, err := g.Step(Command{
			Kind:    CommandForceCast,
			SpellID: id,
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent == 0 {
			t.Fatalf("%s spent no time", id)
		}
	}

	bonds := g.scripts.Components()["magic.summon_bond"]

	if len(bonds.Entities()) != 1 {
		t.Fatalf("got %d injury bonds, want one", len(bonds.Entities()))
	}

	bond, _ := bonds.Get(bonds.Entities()[0])
	guardian, _ := bond.Get("guardian")
	actor, exists := g.stores.Actors.Get(guardian.(akara.Entity))

	if !exists || actor.KindID != "MONS_GUARDIAN_GOLEM" {
		t.Fatalf("bond guardian = %v, actor = %v", guardian, actor)
	}

	ally := bonds.Entities()[0]
	allyHealth, _ := g.stores.Health.Get(ally)
	guardianHealth, _ := g.stores.Health.Get(guardian.(akara.Entity))
	beforeGuardian := guardianHealth.Current
	beforeAlly := allyHealth.Current

	allyHealth.Current -= 6

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if allyHealth.Current != beforeAlly-3 ||
		guardianHealth.Current != beforeGuardian-3 {
		t.Fatalf("bond split got ally %d/%d, guardian %d/%d",
			allyHealth.Current, beforeAlly-3,
			guardianHealth.Current, beforeGuardian-3)
	}
}

func TestSpellforgedServitorSelectsKnownBolt(t *testing.T) {
	g, err := NewDungeonGame(43, "SP_HUMAN", "JOB_SUMMONER", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	grantSummonForTest(t, g, "SPELL_SPELLFORGED_SERVITOR")

	before := g.currentAut
	withoutSpell, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SPELLFORGED_SERVITOR",
	})

	if err != nil {
		t.Fatal(err)
	}

	if withoutSpell.Spent != 0 || g.currentAut != before {
		t.Fatal("servitor without an attack spell spent time")
	}

	grantSummonForTest(t, g, "SPELL_STONE_ARROW")
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SPELLFORGED_SERVITOR",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("servitor with Stone Arrow spent no time")
	}

	store := g.scripts.Components()["magic.summon_servitor"]

	if len(store.Entities()) != 1 {
		t.Fatalf("got %d servitors; events: %+v", len(store.Entities()), result.Events)
	}

	state, _ := store.Get(store.Entities()[0])
	spellID, _ := state.Get("spell_id")

	if spellID != "SPELL_STONE_ARROW" {
		t.Fatalf("servitor spell = %v, want Stone Arrow", spellID)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
}

func TestFireStormVortexBurnsOnContactAndLeavesCloud(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	ratPosition, _ := g.stores.Positions.Get(rat)
	level := g.levels[ratPosition.LevelID]
	var x int
	var y int
	found := false

	for _, offset := range [][2]int{
		{
			-1,
			0,
		},

		{
			1,
			0,
		},

		{
			0,
			-1,
		},

		{
			0,
			1,
		},

		{
			-1,
			-1,
		},

		{
			1,
			-1,
		},

		{
			-1,
			1,
		},

		{
			1,
			1,
		},
	} {
		x, y = ratPosition.X+offset[0], ratPosition.Y+offset[1]

		if !level.Walkable(x, y) {
			continue
		}

		if _, occupied := level.ActorAt(x, y); !occupied {
			found = true
			break
		}
	}

	if !found {
		t.Fatal("no free cell beside vortex target")
	}

	definition, err := testCatalog(t).Monster("MONS_FIRE_VORTEX")

	if err != nil {
		t.Fatal(err)
	}

	vortex, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Actors.Set(vortex, ecs.Actor{
		KindID: "MONS_FIRE_VORTEX",
		Speed:  definition.Speed,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(vortex, ecs.Health{
		Current: 30,
		Max:     30,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.AI.Set(vortex, ecs.MonsterAI{Behavior: "wander"}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.MonsterEnergy.Set(vortex, ecs.MonsterEnergy{}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Combat.Set(vortex, ecs.Combatant{}); err != nil {
		t.Fatal(err)
	}

	if err := level.PlaceActor(vortex, x, y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["magic.summon"].Set(vortex, map[string]any{
		"owner":       g.player,
		"source_id":   "SPELL_FIRE_STORM",
		"expires_aut": int64(g.currentAut + 90),
		"heads":       int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Current = 500
	ratHealth.Max = 500

	for attempt := 0; attempt < 20; attempt++ {
		_, err := g.runAction(vortex, ecs.Intent{
			Kind: ecs.IntentMelee,
			DX:   ratPosition.X - x,
			DY:   ratPosition.Y - y,
		}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		if _, alive := g.stores.Actors.Get(vortex); !alive {
			break
		}
	}

	if _, alive := g.stores.Actors.Get(vortex); alive {
		t.Fatal("fire vortex survived repeated contact")
	}

	if ratHealth.Current >= 500 {
		t.Fatal("fire vortex contact dealt no fire damage")
	}

	if !cloudAtForTest(g, x, y, "CLOUD_FIRE") {
		t.Fatal("dying fire vortex left no fire cloud")
	}
}
