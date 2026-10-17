---
name: visidata
description: Answer questions about and guide interactive use of VisiData (vd), the keyboard-driven terminal spreadsheet and data explorer. Covers launching files, navigation, selecting/filtering/sorting/deleting rows, column typing and derived columns, searching, editing cells, frequency/pivot/describe sheets, joining datasets, saving output, batch replay with .vdj command logs, shell pipes, macros, customization, and supported formats.
license: MIT
compatibility: opencode
metadata:
  audience: users
  workflow: data-exploration
  opencode/slash: "true"
  opencode/autoinvoke: "true"
---

## What I do

- Explain VisiData keybindings, commands, and CLI options
- Give step-by-step keystroke sequences for common data tasks (filter, sort, group, join, save)
- Provide non-interactive / batch invocations and command-log replay commands
- Point to the right helper sheet (Columns, Frequency, Describe, Sheets, Options, CommandLog)

VisiData is **keyboard-driven**: almost every action is a single keystroke or short
sequence. Use this reference as the source of truth for VisiData CLI usage.

## When to use me

Use this when the user asks how to do something in VisiData (`vd`), needs
keybindings or commands, or wants to script/batch VisiData. Ask a clarifying
question if it is unclear whether they are working interactively or in batch mode.

---

## Mental Model & Key Concepts

- **`g` prefix** = "global" / "apply to all" variant of a command.
- **`z` prefix** = "zoom" / "fine-grained" / "expression-based" variant.
- **`Shift+key`** opens named helper sheets (Columns, Frequency, Describe, Sheets, etc.).
- **Key columns** (set with `!`) define the identity of a row — used for sorting by multiple columns, joins, frequency grouping.
- **Selected rows** (highlighted) are the target of bulk operations. Many commands have an "apply to selected" form.
- **Column types** matter for sorting and arithmetic. Always set type (`#` int, `%` float, `@` date, `$` currency, `~` string) before sorting or computing on a column.
- Undo is available with `Ctrl+Z`. Redo with `Ctrl+Y`.

---

## Launching VisiData

```bash
vd file.csv                  # open a CSV file
vd file.tsv                  # open a TSV file
vd file.json                 # open JSON
vd file.xlsx                 # open Excel (requires openpyxl)
vd -f csv file.txt           # force filetype
vd database.sqlite           # open SQLite
vd postgres://user:pass@host/db   # open PostgreSQL
find . | vd                  # pipe any text stream in
ls -al | vd -f fixed --skip 1 --headers 0   # fixed-width with options
vd -b -p commands.vdj in.csv -o out.tsv     # batch: replay cmdlog, save output
```

**Exit:**
- `q` — quit current sheet (repeat until all sheets gone = exits VisiData)
- `gq` — quit all sheets immediately
- `Ctrl+Q` — abort (outputs current sheet if stdout is redirected)

**Options at launch:**
- `--filetype` / `-f` — force file type
- `--skip N` — skip N header lines
- `--headers N` — treat first N rows as header
- `--delimiter` — set delimiter character
- `-o file` — output file when saving

---

## Navigation

### Moving the cursor

| Key(s) | Action |
|--------|--------|
| `h j k l` | left / down / up / right (vim-style) |
| `←↑→↓ PgUp PgDn Home End` | standard arrow keys |
| `gh gj gk gl` | jump to leftmost / bottom / top / rightmost |
| `<` `>` | move up/down to next **different** value in current column |
| `{` `}` | move up/down to next **selected** row |
| `gg` | go to first row |
| `G` | go to last row |
| `z r N` | go to row number N (0-based; negative counts from end) |
| `z c N` | go to column number N (0-based) |

### Jumping by name/key

- `c` *name* — go to column by name
- `r` *key* — go to row by key value

---

## Sheets

Sheets are like "views" or "tabs". Multiple sheets can be open simultaneously.

| Key | Action |
|-----|--------|
| `Shift+S` | open **Sheets Sheet** (all sheets ever opened) |
| `z Shift+S` | open **Sheets Stack** (active sheets, most recent first) |
| `Enter` (on Sheets Sheet) | jump to that sheet |
| `Ctrl+^` | toggle between current and previous sheet |
| `q` | close current sheet |

### Special helper sheets (opened from any sheet)

| Key | Sheet |
|-----|-------|
| `Shift+C` | **Columns Sheet** — manage all columns (type, width, name, aggregators) |
| `Shift+F` | **Frequency Table** — group by current column, count occurrences |
| `Shift+I` | **Describe Sheet** — descriptive statistics for all columns |
| `Shift+O` | **Options Sheet** — view/edit all options |
| `Shift+D` | **CommandLog Sheet** — history of all commands run |
| `z Ctrl+H` | **Commands Sheet** — reference of all available commands |
| `gm` | **Macros Sheet** — list of saved macros |

---

## Rows — Selecting, Filtering, Sorting, Moving

### Selecting rows

Selection is the basis for all bulk operations. Selected rows are highlighted.

| Key | Action |
|-----|--------|
| `s` | select current row |
| `u` | unselect current row |
| `t` | toggle selection of current row |
| `gs` | select **all** rows |
| `gu` | unselect **all** rows |
| `gt` | toggle selection of **all** rows |
| `\|` *regex* | select rows matching regex in **current column** |
| `g\|` *regex* | select rows matching regex in **any visible column** |
| `z\|` *expr* | select rows matching Python expression (column names as variables) |
| `\\` *regex* | **unselect** rows matching regex in current column |
| `g\\` *regex* | unselect rows matching regex in any visible column |
| `z\\` *expr* | unselect rows matching Python expression |
| `,` | select rows matching **current cell value** in current column |
| `g,` | select rows matching the **entire current row** in all visible columns |
| `z,` | select rows matching current cell's **typed value** |

**Example — select rows where column "Status" equals "active":**
1. Move cursor to `Status` column.
2. Move cursor to a cell containing `active`.
3. Press `,` to select all rows with `active` in that column.

**Example — select rows using a Python expression:**
- `z|` then type `Units > 10 and Item == 'Binder'`

### Filtering rows (keeping only selected)

After selecting rows, choose one of:

| Key | Action |
|-----|--------|
| `"` | open a **new sheet** with only selected rows (edits propagate to source) |
| `g"` | open a new sheet with **all rows**, selected rows stay selected |
| `z"` | open a **copy** with selected rows (edits do NOT affect source) |
| `gz"` | open a copy with all rows (edits DO affect source) |
| `gd` | **delete** selected rows from current sheet |

**How to hide/delete all rows where the active column does NOT match a pattern:**
1. `|` *pattern* — select rows that **do** match the pattern in current column.
2. `gt` — toggle selection (now rows that did NOT match are selected).
3. `gd` — delete the selected (non-matching) rows.

**Alternative — keep only matching rows:**
1. `|` *pattern* — select matching rows.
2. `"` — open new sheet with only those rows.

### Deleting rows

| Key | Action |
|-----|--------|
| `d` | mark current row for deletion |
| `gd` | delete all selected rows |
| `z Ctrl+T` | undo last delete |

### Sorting rows

Always **set column type first** for correct sorting of numbers/dates.

| Key | Action |
|-----|--------|
| `[` | sort ascending by current column (replaces existing sort) |
| `]` | sort descending by current column |
| `g[` | sort ascending by **all key columns** |
| `g]` | sort descending by all key columns |
| `z[` | sort ascending, **adding** to existing sort criteria |
| `z]` | sort descending, adding to existing criteria |

**Multi-column sort:**
- Method 1: Press `!` on each column to make it a key column, then `g[`/`g]`.
- Method 2: Sort primary column with `[`, sort secondary column with `z[`.

### Moving rows

| Key | Action |
|-----|--------|
| `J` / `K` | move current row down / up one position |
| `gJ` / `gK` | move current row to bottom / top |

### Copying/pasting rows

| Key | Action |
|-----|--------|
| `y` | copy current row to clipboard |
| `gy` | copy all selected rows to clipboard |
| `p` / `Shift+P` | paste after / before current row |

### Row height

- `v` — toggle multi-line rows (shows full cell content without truncation)

---

## Columns — Hiding, Typing, Renaming, Deriving

### Basic column manipulation

| Key | Action |
|-----|--------|
| `!` | make current column a **key column** (pins left, used for sort/join/group) |
| `H` / `L` | slide column one position left / right |
| `gH` / `gL` | slide column all the way left / right |
| `-` | **hide** current column (sets width to 0) |
| `gv` | **unhide all** hidden columns |
| `_` | expand current column to fit content |
| `g_` | expand all visible columns to fit content |
| `z_` *N* | set current column width to N characters |

**To hide multiple columns at once:**
1. `Shift+C` — open Columns Sheet.
2. Select target column rows with `s`/`t`.
3. Move cursor to `width` column, press `ge` then `0`.

**To unhide a specific hidden column:**
1. `Shift+C` — open Columns Sheet.
2. Find the column row, move to `width`, press `e` and enter a positive number.

### Column types

Always set the type before sorting numerically or using arithmetic.

| Key | Type |
|-----|------|
| `~` | string (default) |
| `#` | integer |
| `%` | float |
| `$` | currency (strips non-numeric chars, parses as float) |
| `@` | date (ISO8601) |
| `z#` | vlen (length of value) |
| `z~` | anytype |

**Set type for multiple columns:**
1. `Shift+C` — Columns Sheet.
2. Select columns with `s`/`t`.
3. Press `g#`, `g%`, `g@`, etc.

### Renaming columns

| Key | Action |
|-----|--------|
| `^` | edit name of current column |
| `z^` | set column name to current cell's value |
| `g^` | set names of all unnamed visible columns from selected rows |

### Splitting a column

| Key | Action |
|-----|--------|
| `:` *regex* | split column at regex pattern → creates multiple new columns |
| `;` *regex* | extract capture groups from column → new columns per group |
| `*` *regex* `Tab` *repl* | replace regex match with replacement (new column) |
| `g*` *regex* `Tab` *repl* | replace in-place in selected rows of current column |

### Creating derived columns

- `=` *expr* — add new column from Python expression; column names are variables.
  - `name=expr` to name it: e.g., `total=Units*Unit_Cost`
  - Available variables: column names, `sheet`, `col`, `row`, `curcol`, `cursorCol`, `currow`
- `g=` *expr* — set current column for all selected rows to evaluated expression
- `z=` *expr* — set current cell to evaluated expression

**Examples:**
- `= Units > 10` → boolean column; then `|` `True` to select matches
- `= Year + '-' + Month + '-' + Day` → concatenate columns into a date string
- `= curcol.casefold()` → lowercase the current column's value

### Expanding nested columns (JSON/dict/list cells)

| Key | Action |
|-----|--------|
| `(` | expand current column (one level) |
| `g(` | expand all visible columns fully |
| `z(` *N* | expand current column to depth N |
| `)` | collapse (unexpand) current column |

### Format display

| Column type | Option | Default |
|-------------|--------|---------|
| int | `disp_int_fmt` | `{:.0f}` |
| float | `disp_float_fmt` | `{:.02f}` |
| currency | `disp_currency_fmt` | `%0.2f` |
| date | `disp_date_fmt` | `%Y-%m-%d` |

- `Alt++` / `Alt+-` — increase/decrease decimal precision of current column

---

## Searching & Matching

| Key | Action |
|-----|--------|
| `/` *regex* | search **down** in current column |
| `?` *regex* | search **up** in current column |
| `g/` *regex* | search down across **all visible** columns |
| `g?` *regex* | search up across all visible columns |
| `n` / `Shift+N` | next / previous match |
| `z/` *expr* | search down by Python expression |
| `z?` *expr* | search up by Python expression |

Searches highlight matches (like vim's `hlsearch`).

- `highlight-col` — highlight regex in current column without moving
- `highlight-sheet` — highlight regex in all columns without moving
- `highlight-clear` — clear all highlights

**Find a command's longname:**
1. `z Ctrl+H` — open Commands Sheet.
2. `/` in the `keystrokes` column, type the keystroke.
3. Move to `longname` column to see it.

---

## Editing Cells

| Key | Action |
|-----|--------|
| `e` | edit current cell |
| `ge` *text* | set current column for **selected rows** to *text* |
| `d` | delete (mark) current row |
| `gd` | delete all selected rows |
| `a` | add blank row |
| `ga` *N* | add N blank rows |
| `za` | add blank column |
| `zd` | set current cell to `None` |
| `gzd` | set current column in selected rows to `None` |

**While editing a cell:**

| Key | Action |
|-----|--------|
| `Enter` | accept |
| `Ctrl+C` / `Esc` | cancel |
| `Ctrl+O` | open in `$EDITOR` |
| `Ctrl+A` / `Ctrl+E` | beginning / end of line |
| `Shift+↓` / `Shift+↑` | save and move to cell below/above |
| `Shift+→` / `Shift+←` | save and move to cell right/left |
| `Tab` / `Shift+Tab` | save and move right/left (wraps to next row) |

**Bulk corrections (unifying inconsistent values):**
1. Select rows with inconsistent values.
2. Move cursor to a row with the correct value.
3. `ge`, edit if needed, press `Enter` — all selected cells in that column get that value.

**Substitute text with regex (in-place in selected rows):**
`g*` → enter *find_regex* `Tab` *replacement* `Enter`

---

## Grouping, Frequency Tables & Statistics

### Aggregators (summary statistics)

Add aggregators to columns before opening a Frequency or Pivot table.

| Key | Action |
|-----|--------|
| `+` *agg* | add aggregator to current column |
| `z+` *agg* | display aggregator result over **selected rows** immediately |

Available aggregators: `min`, `max`, `avg`/`mean`, `mode`, `median`, `q3`/`q4`/`q5`/`q10`, `sum`, `distinct`, `count`, `keymax`, `list`, `stdev`

When aggregators are set, an **aggregation bar** appears at the bottom showing live results.

### Frequency Table (`Shift+F`)

Groups rows by the current column and counts occurrences.

| Key | Action |
|-----|--------|
| `Shift+F` | open Frequency Table for current column |
| `g Shift+F` | open Frequency Table grouped by **all key columns** |
| `z Shift+F` | one-line summary for all rows and selected rows |

**On the Frequency Table:**

| Key | Action |
|-----|--------|
| `Enter` | open source rows in current bin |
| `g Enter` | open source rows from all selected bins |
| `z Enter` | open source rows **excluding** current bin |
| `gz Enter` | open source rows excluding selected bins |

Selecting rows on the Frequency Table also selects the corresponding source rows.

### Pivot Table (`Shift+W`)

Groups by key columns, summarizes current column.

1. Mark grouping columns as key columns with `!`.
2. Add aggregator to the value column with `+`.
3. Move to the pivot column, press `Shift+W`.

### Describe Sheet (`Shift+I`)

Shows descriptive statistics (count, nulls, min, max, mean, etc.) for each column.

- `zs` on a cell — select the null rows for that column on the source sheet
- `zEnter` — open a copy of source sheet with the rows described in that cell

### Combining cells across matching rows

To go from multiple rows per key to one row with combined values (e.g., `A: 1;2`):
1. On the value column: `+` → `list`
2. `Shift+F` on the key column
3. `=` → `';'.join(value_list)` to create a joined column

---

## Joining Datasets

1. Open datasets: `vd d1.csv d2.csv` or use `o` to open additional files.
2. `Shift+S` — Sheets Sheet.
3. On each sheet, press `!` on the shared/key columns.
4. Return to Sheets Sheet, select sheets with `s`.
5. `&` — choose join type:

| Join type | Description |
|-----------|-------------|
| `inner` | rows matching keys on all sheets |
| `outer` | all rows from first sheet |
| `full` | all rows from all sheets (union) |
| `diff` | rows NOT in all sheets |
| `extend` | all rows, retain first sheet's type |
| `merge` | merge differences from other sheets into first |
| `append` | all rows from all sheets; all columns |
| `concat` | all rows from all sheets; columns and types from first sheet |

**Append two datasets:**
1. `Shift+S`, select both sheets with `s`.
2. `&` → `append`.

The `append`/`concat` join types add a hidden `origin_sheet` column (unhide with `gv`).

---

## Saving & Output

| Key | Action |
|-----|--------|
| `Ctrl+S` | save current sheet |
| `g Ctrl+S` | save all sheets |
| `z Ctrl+S` | commit deferred changes (SQLite/DuckDB) or save options |
| `Ctrl+D` | save command log to `.vdj` |
| `Shift+D` | open CommandLog Sheet, then `Ctrl+S` to save |

**Save formats:** VisiData saves as TSV by default; use a filename with the desired extension (`.csv`, `.json`, `.html`, `.md`, etc.) to save in that format.

**Options:**
- `save_filetype` — default save format
- `--save-filetype` on the command line

**Batch output (non-interactive):**
```bash
vd -b input.csv -p commands.vdj -o output.tsv
```
- `-b` — batch mode (no UI)
- `-p` — replay command log
- `-o` — output file

---

## Pipes & Batch Mode

VisiData works in pipelines:

```bash
# Filter rows interactively in a pipeline
mysql < query.sql | vd | awk '{print $1}'

# Interactive process killer
ps -ef | vd | tail -n +2 | xargs kill

# Output single column as plain text
vd data.csv --save-filetype txt | lpr
```

- When stdout is redirected: `Ctrl+Q` outputs the current sheet; `q`/`gq` outputs nothing.
- Use `vd -o-` to send output to terminal explicitly.

---

## Macros & Session Replay

### Recording macros

1. `m` — start recording.
2. Execute the commands to record.
3. `m` — stop recording; enter a keystroke or longname to bind it to.

- `gm` — open Macros Sheet (list all saved macros).
- Macros support `{param}` and `{param=default}` placeholders in inputs for parameterized runs.

### Saving and replaying sessions

1. `Ctrl+D` — save command log to `file.vdj`.
2. `gq` — quit.
3. `vd -p file.vdj` — replay the session.

**Replay on a different file:**
1. Edit the `.vdj`: remove the `open-file` line, blank out all `"sheet"` values.
2. `vd -b -p commands.vdj newfile.csv -o output.tsv`

**Command log formats:**
- `.vd` — TSV format
- `.vdj` — JSON Lines format (recommended)
- `.vdx` — simplified human-readable text format

---

## Customization

Configuration goes in `~/.visidatarc` (plain Python).

### Key bindings

```python
# Bind globally
bindkey('Alt+d', 'delete-row')

# Bind for a specific sheet type
TableSheet.bindkey('i', 'edit-cell')
TableSheet.unbindkey('i')  # unbind first if needed
```

Find a command's longname: execute it and read the lower-right status, or open `z Ctrl+H` (Commands Sheet).

### Options

```python
options.quitguard = True          # confirm before quitting unsaved sheets
options.wrap = True               # wrap text in TextSheet
options.disp_date_fmt = '%m/%d/%Y'
options.numeric_binning = True    # bin numerics in frequency tables
options.null_value = ''           # what counts as null
```

Set options from CLI: `vd --disp-date-fmt='%m/%d/%Y' file.csv`

Set options interactively: `Shift+O` (Options Sheet), then `z Ctrl+S` to save to config.

### Creating new commands

```python
Sheet.addCommand('Ctrl+D', 'scroll-halfpage-down',
    'cursorDown(nScreenRows//2); sheet.topRowIndex += nScreenRows//2',
    'scroll down half a page')
```

Or interactively: `define-command` → `longname execstr`

### Custom aggregators

```python
vd.aggregator('iqr', lambda vals: max(vals)-min(vals), type=float)
```

---

## Supported Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| CSV | `.csv` | `csv_delimiter`, `csv_quotechar` options |
| TSV | `.tsv` | Default save format |
| JSON | `.json` / `.jsonl` | Supports cell expansion with `(` |
| Excel | `.xlsx` / `.xls` | requires `openpyxl`/`xlrd` |
| SQLite | `.sqlite` / `.db` | `z Ctrl+S` to commit changes |
| DuckDB | `.duckdb` | requires `duckdb` |
| Parquet | `.parquet` | requires `pyarrow` |
| PostgreSQL | `postgres://...` | |
| MySQL | `mysql://...` | requires `mysqlclient` |
| Fixed-width | — | `-f fixed --skip 1 --headers 0` |
| HTML | `.html` | loads all `<table>` elements |
| YAML | `.yaml` | requires `PyYAML` |
| XML | `.xml` | requires `lxml` |
| Markdown | `.md` | save only |
| Pandas | any | `-f pandas data.parquet` |
| ZIP / TAR | `.zip` / `.tar` | browse archive members |
| Shapefile | `.shp` | geographic data |
| PNG | `.png` | image data exploration |

---

## Quick-Answer Cookbook

### How do I hide/delete all rows where the current column does NOT match a pattern?

```
| pattern     ← select rows that DO match
gt           ← toggle selection (now non-matching rows are selected)
gd           ← delete the non-matching rows
```

Or to **keep** only matching rows in a new sheet:
```
| pattern     ← select matching rows
"            ← open new sheet with only those rows
```

### How do I filter to rows matching a complex condition?

```
z| Units > 10 and Item == 'Binder'    ← select by Python expression
"                                      ← open filtered sheet
```

### How do I sort by multiple columns?

```
!            ← mark first column as key column
!            ← mark second column as key column
g[           ← sort ascending by all key columns
```

Or: sort primary column with `[`, sort secondary with `z[`.

### How do I delete duplicate rows?

1. `Shift+F` on the relevant column → opens Frequency Table.
2. On Frequency Table, `Enter` on a bin with count > 1 to see duplicates.
3. Back on source, use `z|` or `,` to select duplicates and `gd` to delete.

### How do I rename a column?

Move cursor to the column, press `^`, type new name, press `Enter`.

### How do I add a column that combines two existing columns?

```
= FirstName + ' ' + LastName
```
Then `^` to rename it.

### How do I find the sum/average of a column?

```
#            ← set column type to int (or % for float)
z+ sum       ← display sum of selected rows in status bar
```
Or add aggregator to column (`+` `sum`) and open Frequency Table (`Shift+F`) to see per-group totals.

For the whole column, `z Shift+F` opens a one-line summary.

### How do I extract part of a column using regex?

```
; (regex with capture groups)    ← creates new columns for each capture group
```

Example: extract year from `2024-03-15`:
```
; (\d{4})-\d{2}-\d{2}
```

### How do I replace text in a column?

On selected rows, in-place:
```
gs           ← select all rows
g* old Tab new Enter
```

### How do I copy a sheet to a new CSV file?

```
Ctrl+S       ← type filename with .csv extension
```

### How do I select all rows where a column is null/empty?

Move to an empty cell in the column, press `,` (selects all display-matching cells).
Or: `z|` then `not ColumnName` (for string columns).

### How do I join two files on a common column?

```bash
vd file1.csv file2.csv
```
1. On each sheet, press `!` on the shared column.
2. `Shift+S` → select both sheets with `s`.
3. `&` → choose `inner` (or other join type).

### How do I group and count by a column?

Move cursor to the column, press `Shift+F` → opens Frequency Table with counts.

### How do I pipe VisiData in a shell pipeline?

```bash
cat data.csv | vd | head       # filter interactively, output via Ctrl+Q
ps -ef | vd | tail -n +2 | xargs kill
```
Use `Ctrl+Q` to quit and send current sheet to stdout.

### How do I undo a change?

`Ctrl+Z` — undo last action.
`Ctrl+Y` — redo.

### How do I open a sheet in read-only (exploration) mode?

VisiData is always non-destructive on the source file until you explicitly save (`Ctrl+S`). Navigate and explore freely.

### How do I view a specific row's full content?

- `v` — toggle multi-line rows.
- `e` on a cell, then `Ctrl+O` to open in `$EDITOR`.
- `Enter` on a row (in many sheet types) — dives into that row's detail.

### How do I create a pivot table?

1. `!` on the row-grouping column.
2. `+` *aggregator* on the value column.
3. Move cursor to the column you want pivoted across the top.
4. `Shift+W` — opens Pivot Table.

### How do I run VisiData non-interactively / in batch mode?

```bash
vd -b -p commands.vdj input.csv -o output.csv
```

Record the commands first with `Ctrl+D` (saves to `.vdj`), then replay with `-p`.
