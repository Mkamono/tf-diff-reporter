package model

// Difference represents a single difference detected by jd
type Difference struct {
	Path      string      // JSON Pointer format path (e.g., "/resource/local_file/config/0/content")
	Op        string      // "add", "remove", "replace"
	FromValue interface{} // Old value (for remove/replace)
	ToValue   interface{} // New value (for add/replace)
	Ignored   bool        // Whether this is in ignore.json
	Reason    string      // Ignore reason from ignore.json
}

// IgnoreRule represents a single rule in ignore.json
type IgnoreRule struct {
	Path    string `json:"path"`
	Comment string `json:"comment"`
}

// EnvironmentDiff represents differences for a single environment compared to base
type EnvironmentDiff struct {
	EnvName           string
	UnknownDiffs      []Difference
	AcknowledgedDiffs []Difference
}

// MergedComparisonResult is the final report for all environments
type MergedComparisonResult struct {
	BaseEnv                string
	CompareEnvs            []EnvironmentDiff
	TotalUnknownDiffs      int
	TotalAcknowledgedDiffs int
	Reversed               bool // Whether comparison direction is reversed
}
