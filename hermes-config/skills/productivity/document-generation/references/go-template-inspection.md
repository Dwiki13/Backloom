# Go Template Inspection & Debugging Scripts

## dump_template.go — Full Template Structure Dumper

Run this after ANY template update to verify cell positions and merged ranges:

```go
package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/xuri/excelize/v2"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run dump_template.go <path-to-xlsx>")
		os.Exit(1)
	}

	f, err := excelize.OpenFile(os.Args[1])
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}
	defer f.Close()

	sheet := f.GetSheetName(0)
	fmt.Printf("=== Sheet: %s ===\n\n", sheet)

	rows, _ := f.GetRows(sheet)
	for i, row := range rows {
		for j, cell := range row {
			if cell != "" {
				col, _ := excelize.ColumnNumberToName(j + 1)
				fmt.Printf("%s%d: %s\n", col, i+1, cell)
			}
		}
	}

	fmt.Println("\n=== Merged Cells ===")
	merges, _ := f.GetMergeCells(sheet)
	for _, m := range merges {
		start := m.GetStartAxis()
		end := m.GetEndAxis()
		fmt.Printf("%s → %s\n", start, end)
	}
}
```

Usage:
```bash
cd /root/.hermes/docgen && go run dump_template.go ../templates/Quotation HAS.xlsx
```

## verify_output.go — Output File Checker

After generating a document, verify the output matches expectations:

```go
package main

import (
	"fmt"
	"os"

	"github.com/xuri/excelize/v2"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run verify_output.go <path-to-xlsx>")
		os.Exit(1)
	}

	f, err := excelize.OpenFile(os.Args[1])
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}
	defer f.Close()

	sheet := f.GetSheetName(0)
	rows, _ := f.GetRows(sheet)

	// Checkrows 14-50
	for i := 13; i < 50 && i < len(rows); i++ {
		for j, cell := range rows[i] {
			if cell != "" {
				col, _ := excelize.ColumnNumberToName(j + 1)
				fmt.Printf("%s%d: %s\n", col, i+1, cell)
			}
		}
	}
}
```

## Quick Fix Workflow

When KII says "template updated":

1. Download new template to `/root/.hermes/templates/`
2. Run dump: `cd /root/.hermes/docgen && go run dump_template.go ../templates/Quotation HAS.xlsx`
3. Compare output against `template-row-mappings.md`
4. Update cell references in `generator.go` functions
5. Recompile: `go build -o docgen .`
6. Test: `./docgen --config test-quotation-kii.yaml`
7. Verify output: `go run verify_output.go ../output/<file>.xlsx`
8. Only then use in production
