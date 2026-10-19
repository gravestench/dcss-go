// crawl-mod creates sparse Lua mod files in the same paths the game loads.
package main

import (
	"bufio"
	"embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"text/template"
)

//go:embed templates/*
var templates embed.FS

type kindSpec struct {
	directory string
	category  string
	template  string
	idPrefix  string
}

var kinds = map[string]kindSpec{
	"artefact": {
		directory: "content/artefacts",
		category:  "ARTEFACTS",
		template:  "content.lua.tmpl",
		idPrefix:  "UNRAND_",
	},

	"branch": {
		directory: "content/branches",
		category:  "BRANCHES",
		template:  "content.lua.tmpl",
		idPrefix:  "BRANCH_",
	},

	"cloud": {
		directory: "content/clouds",
		category:  "CLOUDS",
		template:  "content.lua.tmpl",
		idPrefix:  "CLOUD_",
	},

	"item": {
		directory: "content/items",
		category:  "ITEMS",
		template:  "content.lua.tmpl",
		idPrefix:  "ITEM_",
	},

	"weapon": {
		directory: "content/items",
		category:  "ITEMS",
		template:  "content.lua.tmpl",
		idPrefix:  "WPN_",
	},

	"unique-item": {
		directory: "content/artefacts",
		category:  "ARTEFACTS",
		template:  "content.lua.tmpl",
		idPrefix:  "UNRAND_",
	},

	"job": {
		directory: "content/jobs",
		category:  "JOBS",
		template:  "content.lua.tmpl",
		idPrefix:  "JOB_",
	},

	"monster-beam": {
		directory: "content/monster_beams",
		category:  "MONSTER_BEAMS",
		template:  "content.lua.tmpl",
		idPrefix:  "SPELL_",
	},

	"monster-spellbook": {
		directory: "content/monster_spellbooks",
		category:  "MONSTER_SPELLBOOKS",
		template:  "content.lua.tmpl",
		idPrefix:  "MST_",
	},

	"monster": {
		directory: "content/monsters",
		category:  "MONSTERS",
		template:  "content.lua.tmpl",
		idPrefix:  "MONS_",
	},

	"mutation": {
		directory: "content/mutations",
		category:  "MUTATIONS",
		template:  "content.lua.tmpl",
		idPrefix:  "MUT_",
	},

	"shop": {
		directory: "content/shops",
		category:  "SHOPS",
		template:  "content.lua.tmpl",
		idPrefix:  "SHOP_",
	},

	"species": {
		directory: "content/species",
		category:  "SPECIES",
		template:  "content.lua.tmpl",
		idPrefix:  "SP_",
	},

	"spell": {
		directory: "content/spells",
		category:  "SPELLS",
		template:  "content.lua.tmpl",
		idPrefix:  "SPELL_",
	},

	"trap": {
		directory: "content/traps",
		category:  "TRAPS",
		template:  "content.lua.tmpl",
		idPrefix:  "TRAP_",
	},

	"component": {
		directory: "schemas",
		category:  "",
		template:  "component.lua.tmpl",
		idPrefix:  "",
	},

	"system": {
		directory: "systems",
		category:  "",
		template:  "system.lua.tmpl",
		idPrefix:  "",
	},

	"policy": {
		directory: "policy",
		category:  "",
		template:  "policy.lua.tmpl",
		idPrefix:  "",
	},

	"player-effect": {
		directory: "policy/magic/effects",
		category:  "",
		template:  "effect.lua.tmpl",
		idPrefix:  "",
	},

	"player-spell-effect": {
		directory: "policy/magic/effects",
		category:  "",
		template:  "effect.lua.tmpl",
		idPrefix:  "",
	},

	"monster-effect": {
		directory: "policy/combat/monster_spells",
		category:  "",
		template:  "effect.lua.tmpl",
		idPrefix:  "",
	},

	"monster-spell-effect": {
		directory: "policy/combat/monster_spells",
		category:  "",
		template:  "effect.lua.tmpl",
		idPrefix:  "",
	},

	"vault": {
		directory: "vaults/arrival",
		category:  "",
		template:  "vault.des.tmpl",
		idPrefix:  "",
	},
}

var slugPattern = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)

var idPattern = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_.]*$`)

type options struct {
	modDir    string
	kind      string
	name      string
	area      string
	family    string
	namespace string
	id        string
	withHook  bool
}

type templateData struct {
	Name      string
	Slug      string
	ID        string
	Category  string
	Namespace string
	WithHook  bool
	Family    string
}

type outputFile struct {
	path     string
	template string
}

func prompt(reader *bufio.Reader, writer io.Writer, label, value string) (string, error) {
	if value != "" {
		return value, nil
	}

	if _, err := fmt.Fprintf(writer, "%s: ", label); err != nil {
		return "", err
	}

	line, err := reader.ReadString('\n')

	if err != nil &&
		!errors.Is(err, io.EOF) {
		return "", err
	}

	return strings.TrimSpace(line), nil
}

func prepare(opts options) ([]outputFile, templateData, error) {
	spec, found := kinds[opts.kind]

	if !found {
		return nil, templateData{}, fmt.Errorf("unknown kind %q", opts.kind)
	}

	if opts.modDir == "" {
		return nil, templateData{}, errors.New("mod directory is required")
	}

	slug := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(opts.name), "-", "_"))
	slug = strings.ReplaceAll(slug, " ", "_")

	if !slugPattern.MatchString(slug) {
		return nil, templateData{}, fmt.Errorf("invalid name %q: use letters, digits, and underscores", opts.name)
	}

	namespace := opts.namespace

	if namespace == "" {
		namespace = "my_mod"
	}

	if !slugPattern.MatchString(namespace) {
		return nil, templateData{}, fmt.Errorf("invalid namespace %q", namespace)
	}

	area := opts.area

	if area == "" {
		area = "custom"
	}

	if opts.kind == "policy" && !slugPattern.MatchString(area) {
		return nil, templateData{}, fmt.Errorf("invalid policy area %q", area)
	}

	family := opts.family

	if family == "" {
		family = "arrival"
	}

	if opts.kind == "vault" &&
		family != "arrival" &&
		family != "shop" {
		return nil, templateData{}, fmt.Errorf("unsupported vault family %q", family)
	}

	id := opts.id

	if id == "" {
		if spec.category == "" {
			id = namespace + "." + slug
		} else {
			id = spec.idPrefix + strings.ToUpper(slug)
		}
	}

	if !idPattern.MatchString(id) {
		return nil, templateData{}, fmt.Errorf("invalid id %q", id)
	}

	rel := filepath.Join(spec.directory, slug+".lua")

	if opts.kind == "policy" {
		rel = filepath.Join(spec.directory, area, slug+".lua")
	}

	if opts.kind == "vault" {
		rel = filepath.Join("vaults", family, slug+".des")
	}

	files := []outputFile{
		{
			path:     filepath.Join(opts.modDir, rel),
			template: spec.template,
		},
	}

	if opts.kind == "vault" && opts.withHook {
		files = append(files, outputFile{
			path:     filepath.Join(opts.modDir, "policy/generation/vaults", family, slug+".lua"),
			template: "vault_hook.lua.tmpl",
		})
	}

	data := templateData{
		Name:      opts.name,
		Slug:      slug,
		ID:        id,
		Category:  spec.category,
		Namespace: namespace,
		WithHook:  opts.withHook,
		Family:    family,
	}

	return files, data, nil
}

func create(opts options, writer io.Writer) error {
	files, data, err := prepare(opts)

	if err != nil {
		return err
	}

	if err := os.MkdirAll(opts.modDir, 0o755); err != nil {
		return err
	}

	root, err := os.Lstat(opts.modDir)

	if err != nil {
		return err
	}

	if !root.IsDir() {
		return fmt.Errorf("mod directory is not a real directory: %s", opts.modDir)
	}

	// Check every output before writing any file, including existing symlinks.
	for _, file := range files {
		if err := checkParents(opts.modDir, file.path); err != nil {
			return err
		}

		if _, err := os.Lstat(file.path); err == nil {
			return fmt.Errorf("refusing to overwrite %s", file.path)
		} else if !errors.Is(err, fs.ErrNotExist) {
			return err
		}

		if _, err := fmt.Fprintf(writer, "create %s\n", file.path); err != nil {
			return err
		}
	}

	for _, file := range files {
		if err := os.MkdirAll(filepath.Dir(file.path), 0o755); err != nil {
			return err
		}

		content, err := fs.ReadFile(templates, "templates/"+file.template)

		if err != nil {
			return err
		}

		parsed, err := template.New(file.template).Parse(string(content))

		if err != nil {
			return err
		}

		target, err := os.OpenFile(file.path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o644)

		if err != nil {
			return err
		}

		executeErr := parsed.Execute(target, data)
		closeErr := target.Close()

		if executeErr != nil {
			return executeErr
		}

		if closeErr != nil {
			return closeErr
		}
	}

	return nil
}

func checkParents(root, path string) error {
	relative, err := filepath.Rel(root, filepath.Dir(path))

	if err != nil ||
		relative == ".." ||
		strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return fmt.Errorf("path escapes mod directory: %s", path)
	}

	current := root

	for _, part := range strings.Split(relative, string(filepath.Separator)) {
		if part == "." {
			continue
		}

		current = filepath.Join(current, part)
		info, err := os.Lstat(current)

		if errors.Is(err, fs.ErrNotExist) {
			continue
		}

		if err != nil {
			return err
		}

		if !info.IsDir() {
			return fmt.Errorf("mod path parent is not a directory: %s", current)
		}
	}

	return nil
}

func run(args []string, input io.Reader, output io.Writer) error {
	flags := flag.NewFlagSet("crawl-mod", flag.ContinueOnError)
	flags.SetOutput(output)
	opts := options{}
	flags.StringVar(&opts.modDir, "mod-dir", "", "directory for the new sparse mod")
	flags.StringVar(&opts.kind, "kind", "", "content type, component, system, policy, effect, or vault")
	flags.StringVar(&opts.name, "name", "", "human-readable name (used for the filename)")
	flags.StringVar(&opts.area, "area", "custom", "policy subdirectory")
	flags.StringVar(&opts.family, "family", "arrival", "vault family: arrival or shop")
	flags.StringVar(&opts.namespace, "namespace", "my_mod", "component/system namespace")
	flags.StringVar(&opts.id, "id", "", "override the generated catalog or component ID")
	flags.BoolVar(&opts.withHook, "with-hook", false, "create a separate Lua vault hook")

	if err := flags.Parse(args); err != nil {
		return err
	}

	reader := bufio.NewReader(input)
	var err error

	for _, field := range []struct {
		label string
		value *string
	}{
		{
			label: "Mod directory",
			value: &opts.modDir,
		},

		{
			label: "Kind",
			value: &opts.kind,
		},

		{
			label: "Name",
			value: &opts.name,
		},
	} {
		*field.value, err = prompt(reader, output, field.label, *field.value)

		if err != nil {
			return err
		}
	}

	return create(opts, output)
}

func main() {
	if err := run(os.Args[1:], os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
