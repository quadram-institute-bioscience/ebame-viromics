---
name: seqfu-derep
description: Deduplicate (dereplicate) FASTA/FASTQ sequences, collapsing identical sequences and annotating cluster sizes in USEARCH-compatible format (size=N). Supports minimum size filtering, MD5 naming, and JSON metadata export. Can aggregate size annotations from pre-dereplicated inputs. Use for amplicon workflows, deduplication before clustering, or collapsing PCR duplicates.
license: MIT
compatibility: opencode
---

# seqfu derep

Dereplication: collapse identical sequences, keep track of cluster sizes.

Output sequences are renamed with `size=N` annotation (USEARCH/VSEARCH compatible).

## Key Flags

| Flag | Description |
|------|-------------|
| `-p, --prefix STRING` | Sequence name prefix [default: `seq`] |
| `-k, --keep-name` | Use the first observed sequence name instead of renaming |
| `-m, --min-size INT` | Only output clusters with size >= INT |
| `-5, --md5` | Use MD5 hash of sequence as name |
| `-j, --json FILE` | Save dereplication metadata to JSON |
| `--add-size` | Sum existing `size=N` annotations from pre-dereplicated inputs |

## Output Format

```
>seq1;size=42
ATCGATCG...
```

## Examples

```bash
# Basic dereplication
seqfu derep sequences.fa > derep.fa

# Keep only sequences seen >= 5 times
seqfu derep -m 5 sequences.fa > abundant.fa

# MD5 names + JSON metadata
seqfu derep -5 -j metadata.json sequences.fa > derep.fa

# Aggregate sizes from multiple pre-dereplicated files
seqfu derep --add-size sample1_derep.fa sample2_derep.fa > combined_derep.fa

# Typical amplicon workflow
seqfu cat -m 100 reads.fq --fasta | seqfu derep -m 2 > derep.fa
```
