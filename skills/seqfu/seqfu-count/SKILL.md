---
name: seqfu-count
description: Count the number of sequences in FASTA/FASTQ files with automatic paired-end detection (R1/R2 pairing). Supports multithreaded processing, sortable output, and an interactive TUI table. Use when the user needs to know how many reads or sequences are in one or more files.
license: MIT
compatibility: opencode
---

# seqfu count

Count sequences in FASTA/FASTQ files. Automatically pairs R1/R2 files and reports
combined counts.

## Key Flags

| Flag | Description |
|------|-------------|
| `-u, --unpair` | Report R1 and R2 files separately (disable auto-pairing) |
| `-s, --sort MODE` | Sort output: `input`, `name`, `counts`, `none` |
| `-r, --reverse` | Reverse sort order |
| `-t, --threads INT` | Parallel processing threads |
| `-T, --interactive-table` | Interactive TUI table (sortable columns) |
| `-f, --format` | Output format: `default`, `tsv`, `json` |

## Auto-pairing

Files matching `_R1.`/`_R2.` or `_1.`/`_2.` patterns are automatically paired. The
reported count is the number of read **pairs**.

## Examples

```bash
# Count reads in all FASTQ files
seqfu count data/*.fastq

# Show R1/R2 separately instead of as pairs
seqfu count -u data/*.fq.gz

# Sort by count, highest first
seqfu count -s counts -r *.fastq

# Multithreaded
seqfu count -t 8 data/*.fq.gz

# Interactive table
seqfu count -T data/
```
