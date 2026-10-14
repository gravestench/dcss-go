package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	issues := 0

	for _, root := range []string{"cmd", "internal", "scripts"} {
		err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
			if walkErr != nil {
				return walkErr
			}

			if entry.IsDir() || !strings.HasSuffix(path, ".go") {
				return nil
			}

			found, err := checkFile(path)
			issues += found

			return err
		})

		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}

	if issues > 0 {
		os.Exit(1)
	}
}

func checkFile(path string) (int, error) {
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, path, nil, 0)

	if err != nil {
		return 0, err
	}

	issues := 0
	report := func(pos token.Pos, message string) {
		fmt.Printf("%s: %s\n", fset.Position(pos), message)
		issues++
	}
	checkStatements := func(statements []ast.Stmt) {
		for index := 1; index < len(statements); index++ {
			previous := statements[index-1]
			next := statements[index]

			if isControl(next) && !isControl(previous) &&
				fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
				report(next.Pos(), "leave a blank line before the control block")
			}

			if _, returns := next.(*ast.ReturnStmt); returns && !isControl(previous) &&
				fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
				report(next.Pos(), "leave a blank line before the return")
			}

			if isControl(previous) &&
				fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
				report(next.Pos(), "leave a blank line after the control block")
			}
		}
	}

	ast.Inspect(file, func(node ast.Node) bool {
		switch value := node.(type) {
		case *ast.BlockStmt:
			if len(value.List) > 0 && sameLine(fset, value.Lbrace, value.Rbrace) {
				report(value.Lbrace, "expand this inline block")
			}

			checkStatements(value.List)

		case *ast.CaseClause:
			checkStatements(value.Body)

		case *ast.CommClause:
			checkStatements(value.Body)

		case *ast.CompositeLit:
			if len(value.Elts) < 2 {
				break
			}

			keyedFields := true

			for _, element := range value.Elts {
				_, keyed := element.(*ast.KeyValueExpr)
				keyedFields = keyedFields && keyed
			}

			_, named := value.Type.(*ast.Ident)
			_, qualified := value.Type.(*ast.SelectorExpr)
			_, anonymous := value.Type.(*ast.StructType)
			_, generic := value.Type.(*ast.IndexExpr)
			_, genericList := value.Type.(*ast.IndexListExpr)

			if (len(value.Elts) >= 4 || keyedFields || named || qualified ||
				anonymous || generic || genericList) &&
				entriesShareLine(fset, value) {
				report(value.Lbrace, "put literal entries on separate lines")
			}
		}

		return true
	})

	return issues, nil
}

func sameLine(fset *token.FileSet, left, right token.Pos) bool {
	return fset.Position(left).Line == fset.Position(right).Line
}

func entriesShareLine(fset *token.FileSet, literal *ast.CompositeLit) bool {
	if sameLine(fset, literal.Lbrace, literal.Elts[0].Pos()) ||
		sameLine(fset, literal.Elts[len(literal.Elts)-1].End()-1, literal.Rbrace) {
		return true
	}

	for index := 1; index < len(literal.Elts); index++ {
		if sameLine(fset, literal.Elts[index-1].End()-1, literal.Elts[index].Pos()) {
			return true
		}
	}

	return false
}

func isControl(statement ast.Stmt) bool {
	switch statement.(type) {
	case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt,
		*ast.SwitchStmt, *ast.TypeSwitchStmt, *ast.SelectStmt:
		return true
	}

	return false
}
