package terminal

import (
	"fmt"
	"os"
	"time"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/content"
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
)

type equipmentTick struct {
	id uint64
}

type menuWeaponOption struct {
	ID          string
	Name        string
	Restriction string
}

// AppModel owns terminal navigation; the Game owns every turn-changing state.
type AppModel struct {
	catalog             content.Catalog
	choices             map[script.ChoiceKey]script.Choice
	supportedStarts     map[script.ChoiceKey]bool
	presentation        content.PresentationArtifact
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

	notice          string
	confirm         confirmation
	dropQuantity    string
	pendingDoor     game.CommandKind
	equipmentTickID uint64
	aimKind         game.CommandKind
	aimItemID       uint64
	aimX            int
	aimY            int
}

func NewAppModel(catalog content.Catalog, seed uint64, savePath string) (*AppModel, error) {
	rules, err := modfs.Load("")

	if err != nil {
		return nil, err
	}

	return NewAppModelWithRules(
		catalog,
		seed,
		savePath,
		rules,
		game.RestorePolicy{},
	)
}

func NewAppModelWithRules(
	catalog content.Catalog,
	seed uint64,
	savePath string,
	rules modfs.Ruleset,
	policy game.RestorePolicy,
) (*AppModel, error) {
	projected, choices, err := script.ProjectCharacterCatalog(catalog, rules)

	if err != nil {
		return nil, err
	}

	if len(projected.Presentation().SpeciesGroups) < 3 {
		return nil, fmt.Errorf("catalog lacks console presentation")
	}

	presentationWorld := akara.NewWorld()
	presentationRuntime, err := script.NewCatalog(presentationWorld, rules)

	if err != nil {
		presentationWorld.Close()

		return nil, err
	}

	supportedStarts, err := projectSupportedStarts(presentationRuntime, projected)

	if err != nil {
		presentationRuntime.Close()
		presentationWorld.Close()

		return nil, err
	}

	return &AppModel{
		catalog:         projected,
		choices:         choices,
		supportedStarts: supportedStarts,
		presentation:    projected.Presentation(),

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
	if m.game != nil && m.game.View().EquipmentDelay != nil {
		return m.nextEquipmentTick()
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
	}

	return m, nil
}

func (m *AppModel) handleKey(key string) tea.Cmd {
	if _, valid := ComputeLayout(m.width, m.height); !valid {
		return nil
	}

	switch m.screen {
	case ScreenStartup:
		return m.handleStartupKey(key)

	case ScreenSpecies, ScreenBackground:
		m.handleCharacterChoiceKey(key)

	case ScreenWeapon:
		m.handleWeaponKey(key)

	case ScreenName:
		m.handleNameKey(key)

	case ScreenPlay:
		return m.handlePlayKey(key)

	case ScreenStatChoice:
		m.handleStatChoiceKey(key)

	case ScreenInventory:
		m.handleModalKey(key)

	case ScreenSkills:
		m.handleSkillsKey(key)

	case ScreenQuaff:
		return m.handleQuaffKey(key)

	case ScreenDrop:
		return m.handleDropKey(key)

	case ScreenWield:
		return m.handleWieldKey(key)

	case ScreenWear, ScreenTakeOff:
		return m.handleArmourKey(key)

	case ScreenThrow:
		return m.handleThrowKey(key)

	case ScreenAim:
		return m.handleAimKey(key)

	case ScreenConfirm:
		return m.handleConfirmKey(key)

	case ScreenDeath:
		if key == "esc" || key == "enter" {
			m.returnToStartup()
		}

	case ScreenHelp:
		if key == "esc" {
			m.screen = m.previous
			m.notice = ""
		} else {
			m.notice = "This help control is unavailable in the Go port."
		}
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

	case ScreenInventory, ScreenSkills, ScreenQuaff, ScreenDrop,
		ScreenWield, ScreenWear, ScreenTakeOff, ScreenThrow:
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

		case ScreenQuaff:
			DrawQuaff(canvas, view, m.presentationPolicy)

		case ScreenDrop:
			DrawDrop(canvas, view, m.dropQuantity, m.presentationPolicy)

		case ScreenWield:
			DrawWield(canvas, view, m.presentationPolicy)

		case ScreenWear, ScreenTakeOff:
			DrawArmour(canvas, view, m.screen == ScreenTakeOff, m.presentationPolicy)

		case ScreenThrow:
			drawInventoryModal(canvas, view, "throw", "", m.presentationPolicy)
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
		m.catalog,
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
