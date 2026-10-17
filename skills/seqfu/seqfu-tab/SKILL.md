---
name: seqfu-tab
description: Convert FASTA/FASTQ files to/from tab-separated (TSV) format for use in spreadsheet tools, awk, cut, or other text-processing pipelines. Detabulation converts TSV back to FASTA/FASTQ. Use when integrating sequence data with text-processing tools or when writing custom per-record transformations.
license: MIT
compatibility: opencode
---

# seqfu tab

Convert FASTA/FASTQ ↔ TSV (tabular) format.

Also available as `seqfu tabulate`.

## TSV Format

```
name\tsequence\tquality   (FASTQ)
name\tsequence            (FASTA)
```

## Key Flags

| Flag | Description |
|------|-------------|
| `-d, --detabulate` | Convert TSV → FASTA/FASTQ (reverse operation) |
| `-i, --interleaved` | Input is interleaved paired-end |
| `-c, --comment-sep CHAR` | Separator between name and comment [default: tab] |
| `-s, --field-sep CHAR` | Field separator [default: tab] |
| `--header` | Print header row |

## Examples

```bash
# FASTQ to TSV
seqfu tab reads.fq > reads.tsv

# TSV back to FASTQ
seqfu tab -d reads.tsv > reads.fq

# Pipe through awk to filter by sequence length
seqfu tab reads.fq | awk -F'\t' 'length($2) >= 100' | seqfu tab -d > filtered.fq

# Compress tabular output
seqfu tab reads.fq | gzip > reads.tab.gz

# In a pipeline with custom processing
seqfu interleave -1 r1.fq -2 r2.fq | seqfu tab | CUSTOM_STEP | seqfu tab -d
```
