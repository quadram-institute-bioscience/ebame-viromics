---
name: seqfu-head
description: Print the first N sequences from FASTA/FASTQ files, analogous to Unix head but for sequences. Supports sampling every Nth sequence and sequence renaming. Use when the user needs a subset or preview of a sequence file.
license: MIT
compatibility: opencode
---

# seqfu head

Print the first N sequences from FASTA/FASTQ files.

## Key Flags

| Flag | Description |
|------|-------------|
| `-n, --num INT` | Number of sequences to print [default: 10] |
| `-k, --skip INT` | Print one every SKIP sequences (sampling) |
| `-p, --prefix STRING` | Rename output sequences with prefix + number |
| `-b, --basename` | Prepend input basename to sequence name |
| `--fasta` | Force FASTA output |
| `--fastq` | Force FASTQ output |

## Examples

```bash
# First 10 sequences (default)
seqfu head reads.fq

# First 1000 sequences
seqfu head -n 1000 reads.fq.gz > subset.fq

# Every 4th sequence from the first 100
seqfu head -n 100 -k 4 reads.fq > sampled.fq

# Quick stats preview
seqfu head -n 500 assembly.fa | seqfu stats -n
```

## See Also

- `seqfu tail` — last N sequences
- `seqfu cat -n INT` — limit per input file
