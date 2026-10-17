---
name: seqfu-sort
description: Sort FASTA/FASTQ sequences by length in descending order (longest first). Supports ascending order and optional sequence renaming. Use when the user needs sequences ordered by length, for example before assembly or dereplication workflows.
license: MIT
compatibility: opencode
---

# seqfu sort

Sort sequences by length. By default, sorts descending (longest first).

## Key Flags

| Flag | Description |
|------|-------------|
| `--asc` | Ascending order (shortest first) |
| `-p, --prefix STRING` | Rename sorted sequences with prefix + number |
| `-s, --strip-comments` | Remove sequence comments in output |

## Examples

```bash
# Sort assembly contigs by length (longest first)
seqfu sort assembly.fa > sorted.fa

# Shortest first
seqfu sort --asc reads.fq > sorted_asc.fq

# Sort and rename
seqfu sort -p "contig_" assembly.fa > renamed_sorted.fa

# Sort then take top 100 longest sequences
seqfu sort assembly.fa | seqfu head -n 100 > longest100.fa
```

## Notes

- All sequences are loaded into memory for sorting; use with care on very large files.
- Combine with `seqfu derep` first if the input may contain duplicates.
