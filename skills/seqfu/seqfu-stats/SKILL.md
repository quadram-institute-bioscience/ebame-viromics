---
name: seqfu-stats
description: Compute sequence statistics for FASTA/FASTQ files including read counts, total bases, N50, N75, N90, auN, min/max/average lengths, and GC content. Supports TSV, JSON, pretty table, and MultiQC output formats. Use when the user needs assembly quality metrics, dataset summaries, or MultiQC-compatible reports.
license: MIT
compatibility: opencode
---

# seqfu stats

Compute statistics for one or more FASTA/FASTQ files (including gzip-compressed).

## Key Flags

| Flag | Description |
|------|-------------|
| `-n, --nice` | Pretty terminal table output |
| `-j, --json` | JSON output |
| `-T, --interactive-table` | TUI with sortable columns |
| `-s, --sort-by KEY` | Sort by: filename, counts, n50, tot, avg, min, max, aun |
| `-r, --reverse` | Reverse sort order |
| `--multiqc FILE` | Write MultiQC-compatible TSV |
| `--gc` | Include GC content column |

## Output Fields

`File`, `#Seq`, `Total`, `Avg`, `N50`, `N75`, `N90`, `auN`, `Min`, `Max`

## Examples

```bash
# Pretty table for a single file
seqfu stats assembly.fa -n

# JSON output
seqfu stats reads.fq.gz -j

# Sort multiple files by N50, descending
seqfu stats *.fa --sort-by n50 -r -n

# Generate MultiQC report
seqfu stats *.fastq --multiqc multiqc_seqfu_mqc.tsv

# From stdin
cat assembly.fa | seqfu stats -n
```
