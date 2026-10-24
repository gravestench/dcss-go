package terminal

import (
	"fmt"
	"os"
	"time"

	tea "charm.land/bubbletea/v2"
	"crawl/internal/game"
	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/script"
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
	ScreenVictory
	ScreenLeft
	ScreenQuaff
	ScreenStatChoice
	ScreenDrop
	ScreenWield
	ScreenWear
	ScreenTakeOff
	ScreenPutOn
	ScreenRemoveJewellery
	ScreenThrow
	ScreenAim
	ScreenSpells
	ScreenAbilities
	ScreenAbilityConfirm
	ScreenActionConfirm
	ScreenEvokeWand
	ScreenRead
	ScreenSelection
	ScreenShop
	ScreenEvokeItem
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

type automationTick struct {
	id uint64
}

type visualTick struct{}

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

	notice              string
	confirm             confirmation
	dropQuantity        string
	pendingDoor         game.CommandKind
	equipmentTickID     uint64
	spellTickID         uint64
	vampireTickID       uint64
	automationTickID    uint64
	automationState     map[string]any
	visualTickPending   bool
	aimKind             game.CommandKind
	aimItemID           uint64
	aimSpellID          string
	aimAbilityID        string
	pendingAbilityID    string
	pendingAction       game.Command
	pendingActionPrompt string
	pendingSelection    *game.SelectionRequest
	selectionPage       int
	aimX                int
	aimY                int
	spellMode           string
	shopSort            string
	shopSelected        map[uint64]game.ShopSelection
	shopFocus           int
	shopConfirming      bool
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
			return m.withVisualTick(m.nextEquipmentTick())
		}

		if view.LearningRemaining > 0 {
			return m.withVisualTick(m.nextSpellTick())
		}
	}

	return m.withVisualTick(nil)
}

func (m *AppModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case tea.KeyPressMsg:
		if m.automationState != nil {
			m.stopAutomation()

			return m, m.withVisualTick(nil)
		}

		return m, m.withVisualTick(m.handleKey(msg.String()))

	case visualTick:
		m.visualTickPending = false

		return m, m.withVisualTick(nil)

	case equipmentTick:
		if msg.id != m.equipmentTickID ||
			m.screen != ScreenPlay ||
			m.game == nil || m.game.View().EquipmentDelay == nil {
			return m, nil
		}

		return m, m.withVisualTick(m.stepPlayCommand(game.Command{
			Kind: game.CommandContinueEquipment,
		}))

	case spellTick:
		if msg.id != m.spellTickID ||
			m.screen != ScreenPlay ||
			m.game == nil || m.game.View().LearningRemaining == 0 {
			return m, nil
		}

		return m, m.withVisualTick(m.stepPlayCommand(
			game.Command{Kind: game.CommandWait}))

	case vampireTick:
		if msg.id != m.vampireTickID ||
			m.screen != ScreenPlay ||
			m.game == nil || m.game.View().VampireRitualRemaining == 0 {
			return m, nil
		}

		return m, m.withVisualTick(m.stepPlayCommand(
			game.Command{Kind: game.CommandWait}))

	case automationTick:
		if msg.id != m.automationTickID ||
			m.automationState == nil || m.screen != ScreenPlay ||
			m.game == nil {
			return m, nil
		}

		return m, m.withVisualTick(m.advanceAutomation())
	}

	return m, m.withVisualTick(nil)
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

	case ScreenShop:
		return m.handleShopKey(key)

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

	case ScreenRead:
		return m.routeInventoryInput("read", key)

	case ScreenSelection:
		return m.routeInput("selection", key, map[string]any{
			"options":      selectionOptions(m.selectionPageOptions()),
			"has_previous": m.selectionPage > 0,
			"has_next":     m.selectionHasNext(),
		})

	case ScreenEvokeWand:
		return m.routeInventoryInput("evoke_wand", key)

	case ScreenEvokeItem:
		return m.routeInventoryInput("evoke_item", key)

	case ScreenDrop:
		return m.routeInventoryInput("drop", key)

	case ScreenWield:
		return m.routeInventoryInput("wield", key)

	case ScreenWear:
		return m.routeInventoryInput("wear", key)

	case ScreenTakeOff:
		return m.routeInventoryInput("take_off", key)

	case ScreenPutOn:
		return m.routeInventoryInput("put_on", key)

	case ScreenRemoveJewellery:
		return m.routeInventoryInput("remove_jewellery", key)

	case ScreenThrow:
		return m.routeInventoryInput("throw", key)

	case ScreenAim:
		return m.routeInput("aim", key, map[string]any{
			"casting": m.aimSpellID != "",
			"evoking": m.aimKind == game.CommandEvokeWand ||
				m.aimKind == game.CommandEvokeItem,

			"reading": m.pendingSelection != nil &&
				m.pendingSelection.Kind == "cell",
		})

	case ScreenSpells:
		return m.routeSpellInput(key)

	case ScreenAbilities:
		return m.routeAbilityInput(key)

	case ScreenAbilityConfirm:
		return m.routeInput("ability_confirm", key)

	case ScreenActionConfirm:
		return m.routeInput("action_confirm", key)

	case ScreenConfirm:
		return m.routeConfirmationInput(key)

	case ScreenDeath:
		return m.routeInput("death", key)

	case ScreenVictory, ScreenLeft:
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

	case ScreenInventory, ScreenSkills, ScreenMutations, ScreenQuaff, ScreenRead, ScreenSelection,
		ScreenEvokeWand, ScreenEvokeItem, ScreenDrop,
		ScreenWield, ScreenWear, ScreenTakeOff, ScreenPutOn,
		ScreenRemoveJewellery, ScreenThrow, ScreenSpells,
		ScreenAbilities, ScreenAbilityConfirm, ScreenActionConfirm:
		m.drawGameMenu(canvas)

	case ScreenHelp:
		DrawHelp(canvas, m.presentationPolicy)
		m.drawModalNotice(canvas)

	case ScreenShop:
		m.drawShop(canvas)

	case ScreenConfirm:
		m.drawConfirm(canvas)

	case ScreenDeath:
		m.drawStatus(canvas, "death")

	case ScreenVictory:
		m.drawStatus(canvas, "victory")

	case ScreenLeft:
		m.drawStatus(canvas, "left")
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

		case ScreenRead:
			drawInventoryModal(canvas, view, "read", "", m.presentationPolicy)

		case ScreenSelection:
			m.drawSelection(canvas)

		case ScreenEvokeWand:
			drawInventoryModal(canvas, view, "evoke_wand", "", m.presentationPolicy)

		case ScreenEvokeItem:
			drawInventoryModal(canvas, view, "evoke_item", "", m.presentationPolicy)

		case ScreenDrop:
			DrawDrop(canvas, view, m.dropQuantity, m.presentationPolicy)

		case ScreenWield:
			DrawWield(canvas, view, m.presentationPolicy)

		case ScreenWear, ScreenTakeOff:
			DrawArmour(canvas, view, m.screen == ScreenTakeOff, m.presentationPolicy)

		case ScreenPutOn:
			drawInventoryModal(canvas, view, "put_on", "", m.presentationPolicy)

		case ScreenRemoveJewellery:
			drawInventoryModal(canvas, view, "remove_jewellery", "", m.presentationPolicy)

		case ScreenThrow:
			drawInventoryModal(canvas, view, "throw", "", m.presentationPolicy)

		case ScreenSpells:
			DrawSpells(canvas, view, m.spellMode, m.presentationPolicy)

		case ScreenAbilities:
			DrawAbilities(canvas, m.presentationPolicy)

		case ScreenAbilityConfirm:
			DrawAbilityConfirmation(canvas, m.presentationPolicy, m.pendingAbilityID)

		case ScreenActionConfirm:
			DrawActionConfirmation(canvas, m.presentationPolicy,
				m.pendingActionPrompt)
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

// Only visible animated cells need idle redraws. The source UI stream
// changes their colour without taking a game turn or changing a save.
func visibleAnimatedColor(view game.View) bool {
	for _, entity := range view.Entities {
		if entity.AnimatedColor {
			return true
		}
	}

	for _, cloud := range view.Clouds {
		if cloud.AnimatedColor {
			return true
		}
	}

	return false
}

// A single pending timer animates the dungeon only while it is on screen.
// Key actions restart it when a random-colour actor enters the current view.
func (m *AppModel) withVisualTick(command tea.Cmd) tea.Cmd {
	if m.visualTickPending || m.game == nil {
		return command
	}

	showDungeon := m.screen == ScreenPlay ||
		m.screen == ScreenAim ||
		m.screen == ScreenStatChoice

	if !showDungeon {
		return command
	}

	if !visibleAnimatedColor(m.game.View()) {
		return command
	}

	m.visualTickPending = true

	animation := tea.Tick(160*time.Millisecond, func(time.Time) tea.Msg {
		return visualTick{}
	})

	if command == nil {
		return animation
	}

	return tea.Batch(command, animation)
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

	view := restored.View()
	m.afterStep(game.StepResult{View: view})

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
