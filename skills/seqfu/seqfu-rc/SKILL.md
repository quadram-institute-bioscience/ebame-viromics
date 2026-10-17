---
name: seqfu-rc
description: Reverse complement DNA/RNA sequences from FASTA/FASTQ files or directly from command-line strings. Supports IUPAC degenerate bases (N, W, R, Y, S, M, K, B, D, H, V). Use when the user needs to reverse complement a primer, probe, or sequence file.
license: MIT
compatibility: opencode
---

# seqfu rc

Reverse complement nucleotide sequences. Handles IUPAC degenerate bases correctly.

## Key Flags

| Flag | Description |
|------|-------------|
| `-s, --seq-name NAME` | Name to assign when input is a raw string [default: `string`] |
| `--strip-comments` | Remove sequence comments in output |

## Examples

```bash
# Reverse complement a sequence string directly
seqfu rc CCTACGGGNGGCWGCAG

# Multiple strings
seqfu rc ATCGATCG GCTAGCTA

# Reverse complement a FASTA file
seqfu rc primers.fa

# RC of all reads in a FASTQ
seqfu rc reads.fq.gz > rc_reads.fq

# Use in primer design: get reverse primer from forward sequence
seqfu rc GGACTACHVGGGTATCTAATCC
```

## Notes

- When given a raw string argument (not a file), outputs a FASTA record.
- To check if a sequence is its own reverse complement (palindrome), compare output.
