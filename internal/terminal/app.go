package terminal

import (
	"fmt"
	"os"
	"time"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/save"
	"dcrawl-go/internal/script"
	"github.com/gravestench/akara"
)

type ScreenID uint8

type confirmation uint8

const (
	confirmNone confirmation = iota
	confirmSave
	confirmAbandon
)

const (
	ScreenStartup ScreenID = iota
	ScreenSpecies
	ScreenBackground
	ScreenWeapon
	ScreenName
	ScreenPlay
	ScreenInventory
	ScreenSkills
	ScreenMutations
	ScreenHelp
	ScreenConfirm
	ScreenDeath
	ScreenQuaff
	ScreenStatChoice
	ScreenDrop
	ScreenWield
	ScreenWear
	ScreenTakeOff
	ScreenThrow
	ScreenAim
	ScreenSpells
	ScreenAbilities
	ScreenAbilityConfirm
	ScreenSpellConfirm
	ScreenEvokeWand
)

type equipmentTick struct {
	id uint64
}

type spellTick struct {
	id uint64
}

type vampireTick struct {
	id uint64
}

type menuWeaponOption struct {
	ID          string
	Name        string
	Restriction string
}

// AppModel owns terminal navigation; the Game owns every turn-changing state.
type AppModel struct {
	choices             map[script.ChoiceKey]script.Choice
	presentation        script.MenuPresentation
	seed                uint64
	savePath            string
	rules               modfs.Ruleset
	restorePolicy       game.RestorePolicy
	game                *game.Game
	presentationWorld   *akara.World
	presentationRuntime *script.Runtime

	screen       ScreenID
	previous     ScreenID
	weaponReturn ScreenID
	width        int
	height       int

	name             string
	speciesID        string
	jobID            string
	weaponID         string
	options          []menuWeaponOption
	focus            int
	skillFocusAction bool
	mutationPage     int
	mutationListPage int
	mutationPages    int
	mutationSelected string
	mutationOptions  map[string]string

	notice             string
	confirm            confirmation
	dropQuantity       string
	pendingDoor        game.CommandKind
	equipmentTickID    uint64
	spellTickID        uint64
	vampireTickID      uint64
	aimKind            game.CommandKind
	aimItemID          uint64
	aimSpellID         string
	aimAbilityID       string
	pendingAbilityID   string
	pendingSpell       game.Command
	pendingSpellPrompt string
	aimX               int
	aimY               int
	spellMode          string
}

func NewAppModel(seed uint64, savePath string) (*AppModel, error) {
	rules, err := modfs.Load()

	if err != nil {
		return nil, err
	}

	return NewAppModelWithRules(
		seed,
		savePath,
		rules,
		game.RestorePolicy{},
	)
}

func NewAppModelWithRules(
	seed uint64,
	savePath string,
	rules modfs.Ruleset,
	policy game.RestorePolicy,
) (*AppModel, error) {
	presentation, choices, err := script.ProjectCharacterMenu(rules)

	if err != nil {
		return nil, err
	}

	if len(presentation.SpeciesGroups) < 3 {
		return nil, fmt.Errorf("catalog lacks console presentation")
	}

	presentationWorld := akara.NewWorld()
	presentationRuntime, err := script.NewCatalog(presentationWorld, rules)

	if err != nil {
		presentationWorld.Close()

		return nil, err
	}

	return &AppModel{
		choices:      choices,
		presentation: presentation,

		seed:                seed,
		savePath:            savePath,
		rules:               rules,
		restorePolicy:       policy,
		presentationWorld:   presentationWorld,
		presentationRuntime: presentationRuntime,
		screen:              ScreenStartup,
		width:               79,
		height:              24,
	}, nil
}

func (m *AppModel) presentationPolicy(name string, input map[string]any) (map[string]any, error) {
	if m.game != nil {
		return m.game.PresentationPolicy(name, input)
	}

	return m.presentationRuntime.Policy(name, input)
}

func (m *AppModel) Init() tea.Cmd {
	if m.game != nil {
		view := m.game.View()

		if view.EquipmentDelay != nil {
			return m.nextEquipmentTick()
		}

		if view.LearningRemaining > 0 {
			return m.nextSpellTick()
		}
	}

	return nil
}

func (m *AppModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case tea.KeyPressMsg:
		return m, m.handleKey(msg.String())

	case equipmentTick:
		if msg.id != m.equipmentTickID ||
			m.screen != ScreenPlay ||
			m.game == nil || m.game.View().EquipmentDelay == nil {
			return m, nil
		}

		return m, m.stepPlayCommand(game.Command{
			Kind: game.CommandContinueEquipment,
		})

	case spellTick:
		if msg.id != m.spellTickID ||
			m.screen != ScreenPlay ||
			m.game == nil || m.game.View().LearningRemaining == 0 {
			return m, nil
		}

		return m, m.stepPlayCommand(game.Command{Kind: game.CommandWait})

	case vampireTick:
		if msg.id != m.vampireTickID ||
			m.screen != ScreenPlay ||
			m.game == nil || m.game.View().VampireRitualRemaining == 0 {
			return m, nil
		}

		return m, m.stepPlayCommand(game.Command{Kind: game.CommandWait})
	}

	return m, nil
}

func (m *AppModel) handleKey(key string) tea.Cmd {
	if _, valid := ComputeLayout(m.width, m.height); !valid {
		return nil
	}

	switch m.screen {
	case ScreenStartup:
		return m.routePregameInput("startup", key)

	case ScreenSpecies:
		return m.routePregameInput("species", key)

	case ScreenBackground:
		return m.routePregameInput("background", key)

	case ScreenWeapon:
		return m.routePregameInput("weapon", key)

	case ScreenName:
		return m.routePregameInput("name", key)

	case ScreenPlay:
		return m.handlePlayKey(key)

	case ScreenStatChoice:
		return m.routeInput("stat_choice", key)

	case ScreenInventory:
		return m.routeInput("modal", key)

	case ScreenSkills:
		return m.routeSkillInput(key)

	case ScreenMutations:
		return m.handleMutationInput(key)

	case ScreenQuaff:
		return m.routeInventoryInput("quaff", key)

	case ScreenEvokeWand:
		return m.routeInventoryInput("evoke_wand", key)

	case ScreenDrop:
		return m.routeInventoryInput("drop", key)

	case ScreenWield:
		return m.routeInventoryInput("wield", key)

	case ScreenWear:
		return m.routeInventoryInput("wear", key)

	case ScreenTakeOff:
		return m.routeInventoryInput("take_off", key)

	case ScreenThrow:
		return m.routeInventoryInput("throw", key)

	case ScreenAim:
		return m.routeInput("aim", key, map[string]any{
			"casting": m.aimSpellID != "",
			"evoking": m.aimKind == game.CommandEvokeWand,
		})

	case ScreenSpells:
		return m.routeSpellInput(key)

	case ScreenAbilities:
		return m.routeAbilityInput(key)

	case ScreenAbilityConfirm:
		return m.routeInput("ability_confirm", key)

	case ScreenSpellConfirm:
		return m.routeInput("spell_confirm", key)

	case ScreenConfirm:
		return m.routeConfirmationInput(key)

	case ScreenDeath:
		return m.routeInput("death", key)

	case ScreenHelp:
		return m.routeInput("help", key)
	}

	return nil
}

func (m *AppModel) renderCanvas() *Canvas {
	canvas := NewCanvas(m.width, m.height)
	layout, ok := ComputeLayout(m.width, m.height)

	if !ok {
		m.drawStatus(canvas, "small_terminal")

		return canvas
	}

	switch m.screen {
	case ScreenStartup:
		m.drawStartup(canvas)

	case ScreenSpecies, ScreenBackground:
		m.drawCharacterChoice(canvas)

	case ScreenWeapon:
		m.drawWeapon(canvas)

	case ScreenName:
		m.drawName(canvas)

	case ScreenPlay, ScreenStatChoice, ScreenAim:
		if m.game != nil {
			DrawPlay(canvas, layout, m.game.View(), m.notice, m.presentationPolicy)
		}

		if m.screen == ScreenAim && m.game != nil {
			m.drawAim(canvas, layout)
		}

		if m.screen == ScreenStatChoice && m.game != nil {
			m.drawStatus(canvas, "stat_choice")
		}

	case ScreenInventory, ScreenSkills, ScreenMutations, ScreenQuaff, ScreenEvokeWand, ScreenDrop,
		ScreenWield, ScreenWear, ScreenTakeOff, ScreenThrow, ScreenSpells,
		ScreenAbilities, ScreenAbilityConfirm, ScreenSpellConfirm:
		m.drawGameMenu(canvas)

	case ScreenHelp:
		DrawHelp(canvas, m.presentationPolicy)
		m.drawModalNotice(canvas)

	case ScreenConfirm:
		m.drawConfirm(canvas)

	case ScreenDeath:
		m.drawStatus(canvas, "death")
	}

	return canvas
}

func (m *AppModel) drawStatus(canvas *Canvas, kind string) {
	result := runPresentation(m.presentationPolicy, "presentation.status", map[string]any{
		"kind":   kind,
		"height": canvas.height,
		"notice": m.notice,
	})

	drawPresentation(canvas, fullRegion(canvas), result)
}

func (m *AppModel) drawGameMenu(canvas *Canvas) {
	if m.game != nil {
		view := m.game.View()

		switch m.screen {
		case ScreenInventory:
			DrawInventory(canvas, view, m.presentationPolicy)

		case ScreenSkills:
			DrawSkills(canvas, view, m.skillFocusAction, m.presentationPolicy)

		case ScreenMutations:
			DrawMutations(canvas, m.mutationPage, m.mutationSelected,
				m.presentationPolicy)

		case ScreenQuaff:
			DrawQuaff(canvas, view, m.presentationPolicy)

		case ScreenEvokeWand:
			drawInventoryModal(canvas, view, "evoke_wand", "", m.presentationPolicy)

		case ScreenDrop:
			DrawDrop(canvas, view, m.dropQuantity, m.presentationPolicy)

		case ScreenWield:
			DrawWield(canvas, view, m.presentationPolicy)

		case ScreenWear, ScreenTakeOff:
			DrawArmour(canvas, view, m.screen == ScreenTakeOff, m.presentationPolicy)

		case ScreenThrow:
			drawInventoryModal(canvas, view, "throw", "", m.presentationPolicy)

		case ScreenSpells:
			DrawSpells(canvas, view, m.spellMode, m.presentationPolicy)

		case ScreenAbilities:
			DrawAbilities(canvas, m.presentationPolicy)

		case ScreenAbilityConfirm:
			DrawAbilityConfirmation(canvas, m.presentationPolicy, m.pendingAbilityID)

		case ScreenSpellConfirm:
			DrawSpellConfirmation(canvas, m.presentationPolicy,
				m.pendingSpellPrompt)
		}
	}

	m.drawModalNotice(canvas)
}

func (m *AppModel) nextEquipmentTick() tea.Cmd {
	m.equipmentTickID++
	id := m.equipmentTickID

	return tea.Tick(80*time.Millisecond, func(time.Time) tea.Msg {
		return equipmentTick{id: id}
	})
}

func (m *AppModel) nextSpellTick() tea.Cmd {
	m.spellTickID++
	id := m.spellTickID

	return tea.Tick(80*time.Millisecond, func(time.Time) tea.Msg {
		return spellTick{id: id}
	})
}

func (m *AppModel) nextVampireTick() tea.Cmd {
	m.vampireTickID++
	id := m.vampireTickID

	return tea.Tick(80*time.Millisecond, func(time.Time) tea.Msg {
		return vampireTick{id: id}
	})
}

func (m *AppModel) View() (view tea.View) {
	defer func() {
		if failure := recover(); failure != nil {
			view = tea.NewView(fmt.Sprintf("Lua presentation error: %v", failure))
			view.AltScreen = true
		}
	}()

	view = tea.NewView(m.renderCanvas().Styled())

	view.AltScreen = true

	return view
}

func (m *AppModel) Close() error {
	var err error

	if m.game != nil {
		err = m.game.Close()
		m.game = nil
	}

	if m.presentationRuntime != nil {
		m.presentationRuntime.Close()
		m.presentationRuntime = nil
	}

	if m.presentationWorld != nil {
		m.presentationWorld.Close()
		m.presentationWorld = nil
	}

	return err
}

func (m *AppModel) savedRunExists() bool {
	_, err := os.Stat(m.savePath)

	return err == nil
}

func (m *AppModel) loadSavedRun() {
	snapshot, err := save.Read(m.savePath)

	if err != nil {
		m.notice = fmt.Sprintf("Load failed: %v", err)

		return
	}

	restored, err := game.RestoreWithRules(
		snapshot,
		m.rules,
		m.restorePolicy,
	)

	if err != nil {
		m.notice = fmt.Sprintf("Load failed: %v", err)

		return
	}

	if m.game != nil {
		_ = m.game.Close()
	}

	m.game = restored
	m.screen = ScreenPlay

	if restored.View().PendingStatLevel != 0 {
		m.screen = ScreenStatChoice
	}

	m.notice = ""
}

func (m *AppModel) returnToStartup() {
	if m.game != nil {
		_ = m.game.Close()
	}

	m.game = nil

	m.screen = ScreenStartup
	m.previous = ScreenStartup
	m.weaponReturn = ScreenStartup

	m.name = ""

	m.speciesID = ""
	m.jobID = ""
	m.weaponID = ""

	m.options = nil

	m.focus = 0
	m.notice = ""

	m.confirm = confirmNone
	m.pendingDoor = 0
}
