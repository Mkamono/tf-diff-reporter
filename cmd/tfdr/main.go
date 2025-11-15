package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/Mkamono/tf-diff-reporter/internal/diff"
	"github.com/Mkamono/tf-diff-reporter/internal/hcl"
	"github.com/Mkamono/tf-diff-reporter/internal/model"
	"github.com/Mkamono/tf-diff-reporter/internal/report"
	"github.com/Mkamono/tf-diff-reporter/internal/tools"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]

	switch command {
	case "compare":
		runCompare(os.Args[2:])
	case "help", "-h", "--help":
		printUsage()
	default:
		fmt.Printf("Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}

func runCompare(args []string) {
	// Check required tools
	if err := tools.CheckRequiredTools(); err != nil {
		log.Fatalf("Required tool check failed: %v", err)
	}

	fs := flag.NewFlagSet("compare", flag.ContinueOnError)
	ignoreFile := fs.String("i", ".tfdr/ignore.json", "Path to ignore file (--ignore)")
	outputDir := fs.String("o", ".tfdr/reports", "Output directory for reports (--output-dir)")
	reverse := fs.Bool("r", false, "Reverse comparison order: use second env as base instead of first")

	if err := fs.Parse(args); err != nil {
		log.Fatalf("Failed to parse flags: %v", err)
	}

	dirs := fs.Args()

	// Determine base and compare directories
	var baseDir string
	var compareDirs []string

	if len(dirs) == 0 {
		// Auto-detect directories
		var allDirs []string
		entries, err := os.ReadDir(".")
		if err != nil {
			log.Fatalf("Failed to read current directory: %v", err)
		}

		for _, entry := range entries {
			if entry.IsDir() && !strings.HasPrefix(entry.Name(), ".") {
				allDirs = append(allDirs, entry.Name())
			}
		}

		if len(allDirs) < 2 {
			log.Fatal("At least 2 environment directories are required")
		}

		sort.Strings(allDirs)
		baseDir = allDirs[0]
		compareDirs = allDirs[1:]
	} else {
		if len(dirs) < 2 {
			log.Fatal("At least 2 environments must be specified")
		}

		baseDir = dirs[0]
		compareDirs = dirs[1:]
	}

	// Reverse: reverse the order of compare directories
	// This way each compare directory will be shown in reverse order
	if *reverse {
		for i, j := 0, len(compareDirs)-1; i < j; i, j = i+1, j-1 {
			compareDirs[i], compareDirs[j] = compareDirs[j], compareDirs[i]
		}
	}

	// Validate directories exist
	if err := validateDirs(baseDir, compareDirs); err != nil {
		log.Fatalf("Directory validation failed: %v", err)
	}

	// Convert to absolute paths
	var err error
	baseDir, err = filepath.Abs(baseDir)
	if err != nil {
		log.Fatalf("Failed to get absolute path for %s: %v", baseDir, err)
	}

	for i, dir := range compareDirs {
		absDir, err := filepath.Abs(dir)
		if err != nil {
			log.Fatalf("Failed to get absolute path for %s: %v", dir, err)
		}
		compareDirs[i] = absDir
	}

	// Load ignore rules and create output directory
	ignoreManager := diff.NewIgnoreManager()
	if err := ignoreManager.LoadFromFile(*ignoreFile); err != nil {
		log.Fatalf("Failed to load ignore file: %v", err)
	}
	fmt.Printf("[DEBUG] Ignore file loaded from: %s\n", *ignoreFile)
	fmt.Printf("[DEBUG] Number of rules loaded: %d\n", ignoreManager.RuleCount())

	if err := os.MkdirAll(*outputDir, 0755); err != nil {
		log.Fatalf("Failed to create output directory: %v", err)
	}

	// Convert base environment HCL/tf files to JSON
	baseJSONPath, err := hcl.ConvertDirectory(baseDir)
	if err != nil {
		log.Fatalf("Failed to convert base environment from %s: %v", baseDir, err)
	}
	defer os.Remove(baseJSONPath)

	baseDirName := filepath.Base(baseDir)
	comparator := diff.NewComparator(ignoreManager)

	// Compare base against each target environment
	mergedResult := model.MergedComparisonResult{
		BaseEnv:     baseDirName,
		CompareEnvs: []model.EnvironmentDiff{},
	}

	for _, compareDir := range compareDirs {
		compareJSONPath, err := hcl.ConvertDirectory(compareDir)
		if err != nil {
			log.Fatalf("Failed to convert environment from %s: %v", compareDir, err)
		}
		defer os.Remove(compareJSONPath)

		// Get diffs using jd
		// When reversed, swap the comparison order: compare -> base (instead of base -> compare)
		var jdDiffs []tools.JDDiff
		if *reverse {
			jdDiffs, err = tools.ExecuteJD(compareJSONPath, baseJSONPath)
		} else {
			jdDiffs, err = tools.ExecuteJD(baseJSONPath, compareJSONPath)
		}
		if err != nil {
			log.Fatalf("Failed to execute jd: %v", err)
		}

		// Classify diffs as acknowledged or unknown
		compareDirName := filepath.Base(compareDir)
		unknown, acknowledged := comparator.ClassifyDiffs(jdDiffs)

		envDiff := model.EnvironmentDiff{
			EnvName:           compareDirName,
			UnknownDiffs:      unknown,
			AcknowledgedDiffs: acknowledged,
		}
		mergedResult.CompareEnvs = append(mergedResult.CompareEnvs, envDiff)
		mergedResult.TotalUnknownDiffs += len(unknown)
		mergedResult.TotalAcknowledgedDiffs += len(acknowledged)
	}

	// Generate and save markdown report
	mdFormatter := report.NewMarkdownFormatter()
	reportContent, err := mdFormatter.FormatMerged(mergedResult)
	if err != nil {
		log.Fatalf("Failed to format report: %v", err)
	}

	reportPath := filepath.Join(*outputDir, "comparison-report.md")
	if err := os.WriteFile(reportPath, []byte(reportContent), 0644); err != nil {
		log.Fatalf("Failed to write report: %v", err)
	}

	fmt.Printf("Report saved to: %s\n", reportPath)

	// Exit with code 1 if unknown differences found
	if mergedResult.TotalUnknownDiffs > 0 {
		os.Exit(1)
	}
}

func validateDirs(baseDir string, compareDirs []string) error {
	if _, err := os.Stat(baseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", baseDir)
	}

	for _, dir := range compareDirs {
		if _, err := os.Stat(dir); os.IsNotExist(err) {
			return fmt.Errorf("directory does not exist: %s", dir)
		}
	}

	return nil
}

func printUsage() {
	fmt.Println(`tf-diff-reporter - Terraform environment comparison tool (Markdown output only)

Usage:
  tf-diff-reporter compare [OPTIONS] [DIR_1 (base)] [DIR_2] [DIR_3] ...

Options:
  -i, --ignore FILE     Path to ignore file (default: .tfdr/ignore.json)
  -o, --output-dir DIR  Output directory for reports (default: .tfdr/reports)
  -r, --reverse         Reverse: use last environment as base, others vs it

Examples:
  # Compare env1 vs env2 and env3 (env1 is base)
  tf-diff-reporter compare env1 env2 env3

  # Compare env2, env1 vs env3 (env3 is base)
  tf-diff-reporter compare -r env1 env2 env3

  # Auto-detect environments (sorted alphabetically, first is base)
  tf-diff-reporter compare

  # Auto-detect with reverse (last is base)
  tf-diff-reporter compare -r

  # Custom ignore file and output directory
  tf-diff-reporter compare -i my-ignore.json -o my-reports env1 env2`)
}
