---
name: seqfu-cat
description: Concatenate, filter, rename, and enrich FASTA/FASTQ files. Supports length filtering, base trimming, sequence renaming with prefixes, adding metadata (length, GC, quality) to comments, and limiting output by count or total bases. Use when processing or preparing sequence datasets.
license: MIT
compatibility: opencode
---

# seqfu cat

Concatenate and manipulate one or more FASTA/FASTQ files. The Swiss-army knife for
sequence preprocessing.

## Key Flags

### Filtering
| Flag | Description |
|------|-------------|
| `-m, --min-len INT` | Discard sequences shorter than INT |
| `-x, --max-len INT` | Discard sequences longer than INT |
| `--max-ns INT` | Discard sequences with more than INT Ns |
| `--max-bp INT` | Stop after INT bases from each file |
| `-n, --num INT` | Print at most INT sequences per file |

### Renaming
| Flag | Description |
|------|-------------|
| `-p, --prefix STRING` | Rename sequences as PREFIX + sequential number |
| `-b, --basename` | Prepend input filename to sequence name |
| `-s, --strip-comments` | Remove sequence comments |

### Metadata enrichment
| Flag | Description |
|------|-------------|
| `--add-len` | Append sequence length to comment |
| `--add-gc` | Append GC content (%) to comment |
| `--add-name` | Append original name to comment |

### Trimming
| Flag | Description |
|------|-------------|
| `--trim-front INT` | Remove INT bases from start |
| `--trim-rear INT` | Remove INT bases from end |

## Examples

```bash
# Filter by length and concatenate
seqfu cat -m 500 -x 50000 assembly1.fa assembly2.fa > merged.fa

# Rename all sequences with prefix
seqfu cat -p "sample1_" reads.fq > renamed.fq

# Add filename prefix and length annotation
seqfu cat -b --add-len *.fasta > annotated.fa

# Limit to first 10000 bases per file
seqfu cat --max-bp 10000 *.fq > subsampled.fq

# Remove short reads and strip comments
seqfu cat -m 50 -s reads.fq.gz > clean.fq
```
