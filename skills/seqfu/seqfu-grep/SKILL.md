---
name: seqfu-grep
description: Filter and extract sequences from FASTA/FASTQ files by name, regex pattern, or oligonucleotide sequence (with IUPAC degenerate base support, reverse complement matching, and mismatch tolerance). Use when the user needs to select specific sequences or find sequences containing a motif or primer.
license: MIT
compatibility: opencode
---

# seqfu grep

Select sequences from FASTA/FASTQ files by name match or oligonucleotide search.

## Key Flags

| Flag | Description |
|------|-------------|
| `-n, --name STRING` | Match string in sequence name (exact substring) |
| `-r, --regex PATTERN` | Regex match against sequence name |
| `-o, --oligo IUPAC` | Search for DNA oligo (IUPAC degenerate bases, scans both strands) |
| `-c, --comment` | Also search in sequence comments |
| `--max-mismatches INT` | Allow up to INT mismatches in oligo search [default: 0] |
| `-v, --invert-match` | Print sequences that do NOT match |
| `-l, --list FILE` | File of names to match (one per line) |

## IUPAC Degenerate Bases

`N`=any, `W`=A/T, `R`=A/G, `Y`=C/T, `S`=G/C, `M`=A/C, `K`=G/T, `B`=not A, `D`=not C, `H`=not G, `V`=not T

## Examples

```bash
# Select sequences whose name contains "contig_1"
seqfu grep -n "contig_1" assembly.fa

# Regex: select sequences named with a number > 100
seqfu grep -r "contig_[1-9][0-9]{2,}" assembly.fa

# Find sequences containing a primer (with degenerate bases, both strands)
seqfu grep -o CCTACGGGNGGCWGCAG reads.fq

# Allow 1 mismatch
seqfu grep -o ATCGATCG --max-mismatches 1 reads.fa

# Exclude matched sequences
seqfu grep -v -n "contamination" sequences.fasta

# Match from a list file
seqfu grep -l names.txt sequences.fasta
```
