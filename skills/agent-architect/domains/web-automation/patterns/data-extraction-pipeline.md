# Data Extraction Pipeline Pattern

## Purpose

Structure web data extraction as a clear ETL (Extract-Transform-Validate-Load) pipeline with reporting at each stage.

## When to Apply

Apply to agents that extract structured data from web sources and produce organized output (files, databases, reports).

## Implementation

### Pipeline Stages

```markdown
## Data Pipeline

### Stage 1: Extract
- Fetch raw data from source (HTML, JSON, API response)
- Apply rate limiting (see rate-limiting pattern)
- Store raw response for debugging if needed

### Stage 2: Transform
- Parse raw data into structured format
- Normalize fields (dates, currencies, names, encoding)
- Handle missing or malformed fields

### Stage 3: Validate
- Check required fields are present and non-empty
- Validate field formats (email, URL, date, numeric ranges)
- Flag items that fail validation (do not silently drop them)

### Stage 4: Load
- Write validated data to output format (JSON, CSV, database)
- Include metadata (source URL, extraction timestamp, validation status)
- Generate summary report
```

### Pipeline Summary Report

```markdown
## Pipeline Report

Report at completion:

| Stage | Input | Output | Dropped | Flagged |
|-------|-------|--------|---------|---------|
| Extract | [total URLs] | [responses received] | [failed requests] | — |
| Transform | [responses] | [parsed items] | [unparseable] | — |
| Validate | [parsed items] | [valid items] | — | [flagged items] |
| Load | [valid items] | [written records] | [write failures] | — |

**Total:** [N] items extracted from [M] sources in [duration]
**Success rate:** [percentage]
```

### Field Mapping

```markdown
## Field Mapping

Define explicit mapping from source to output:

| Source Field | Output Field | Transform | Required |
|-------------|-------------|-----------|----------|
| [raw field] | [clean field] | [transform function] | Yes/No |

Unmapped source fields are ignored. Missing required fields cause the item to be flagged.
```

## Configuration Table

Include in the agent definition:

```markdown
| Setting | Default | Description |
|---------|---------|-------------|
| output_format | json | Output file format (json, csv) |
| include_metadata | true | Include source URL and timestamp per record |
| flag_threshold | 0.2 | If >20% items flagged, stop and report |
| batch_size | 100 | Items per output file (0 = single file) |
```
