# =============================================================================
# Program:    t_demog_summary.R
# Purpose:    Generate a demographics summary table from ADSL
#             (Table 14.1.1 — Subject Demographics and Baseline Characteristics)
# Study:      CDISCPILOT01
# Input:      ADSL
# Output:     Demographics summary table
#
# Notes:      This is a TEACHING EXAMPLE using CDISCPILOT01 data.
#             Uses the {gt} package for table formatting, but {rtables}
#             and {tfrmt} are also common in pharma — ask your team which
#             they prefer.
# =============================================================================

library(dplyr)
library(tidyr)
library(haven)
library(gt)

# ── Step 1: Read ADSL and filter to analysis population ──────────────────────

adam_path <- "path/to/cdiscpilot01/adam"  # CUSTOMIZE this path

adsl <- read_xpt(file.path(adam_path, "adsl.xpt")) |>
  filter(ITTFL == "Y")  # ITT population per SAP

# Big-N counts for column headers
n_counts <- adsl |>
  count(TRT01P, TRT01PN) |>
  arrange(TRT01PN)

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2: CONTINUOUS VARIABLES — Age
# ──────────────────────────────────────────────────────────────────────────────
# Standard display: N, Mean (SD), Median, Min, Max
# ══════════════════════════════════════════════════════════════════════════════

age_stats <- adsl |>
  group_by(TRT01P, TRT01PN) |>
  summarise(
    `n`          = as.character(n()),
    `Mean (SD)`  = paste0(sprintf("%.1f", mean(AGE)),
                          " (", sprintf("%.2f", sd(AGE)), ")"),
    `Median`     = sprintf("%.1f", median(AGE)),
    `Min, Max`   = paste0(sprintf("%.1f", min(AGE)),
                          ", ", sprintf("%.1f", max(AGE))),
    .groups = "drop"
  ) |>
  pivot_longer(cols = c(`n`, `Mean (SD)`, `Median`, `Min, Max`),
               names_to = "stat",
               values_to = "value") |>
  pivot_wider(names_from = c(TRT01P, TRT01PN),
              values_from = value) |>
  mutate(param = "Age (years)",
         ord1 = 1,
         ord2 = row_number())

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3: CATEGORICAL VARIABLES — Sex, Race, Ethnicity
# ──────────────────────────────────────────────────────────────────────────────
# Standard display: n (xx.x%)
# ══════════════════════════════════════════════════════════════════════════════

# Helper function: count and format as "n (xx.x%)"
cat_summary <- function(data, var, param_label, ord1_val) {
  var_sym <- rlang::sym(var)

  data |>
    group_by(TRT01P, TRT01PN) |>
    count(!!var_sym) |>
    mutate(
      pct = n / sum(n) * 100,
      value = paste0(n, " (", sprintf("%.1f", pct), ")")
    ) |>
    ungroup() |>
    select(TRT01P, TRT01PN, stat = !!var_sym, value) |>
    pivot_wider(names_from = c(TRT01P, TRT01PN),
                values_from = value,
                values_fill = "0 (0.0)") |>
    mutate(param = param_label,
           ord1 = ord1_val,
           ord2 = row_number())
}

sex_stats  <- cat_summary(adsl, "SEX",    "Sex",       2)
race_stats <- cat_summary(adsl, "RACE",   "Race",      3)
eth_stats  <- cat_summary(adsl, "ETHNIC", "Ethnicity", 4)

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4: COMBINE ALL STATISTICS
# ══════════════════════════════════════════════════════════════════════════════

all_stats <- bind_rows(age_stats, sex_stats, race_stats, eth_stats) |>
  arrange(ord1, ord2)

# Clean up column names for display
# Columns are named like "Placebo_1", "Xanomeline Low Dose_2", etc.
trt_cols <- n_counts |>
  mutate(col_name = paste0(TRT01P, "_", TRT01PN),
         header   = paste0(TRT01P, "\n(N=", n, ")"))

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5: CREATE THE TABLE
# ══════════════════════════════════════════════════════════════════════════════

report_data <- all_stats |>
  select(param, stat, starts_with("Placebo"), starts_with("Xanomeline"))

# Rename columns for cleaner display
col_names <- names(report_data)
new_names <- col_names
for (i in seq_len(nrow(trt_cols))) {
  idx <- which(col_names == trt_cols$col_name[i])
  if (length(idx) > 0) new_names[idx] <- trt_cols$header[i]
}
names(report_data) <- new_names

# Build the gt table
demog_table <- report_data |>
  gt(groupname_col = "param") |>
  tab_header(
    title = "Table 14.1.1",
    subtitle = "Summary of Demographics and Baseline Characteristics — ITT Population"
  ) |>
  cols_label(
    stat = "Statistic"
  ) |>
  cols_align(
    align = "center",
    columns = -c(stat)
  ) |>
  cols_align(
    align = "left",
    columns = stat
  ) |>
  tab_footnote(
    footnote = "Source: ADSL (ITT Population). Percentages based on treatment group N."
  ) |>
  tab_options(
    table.font.size = px(12),
    heading.title.font.size = px(14),
    heading.subtitle.font.size = px(12)
  )

# Display the table
demog_table

# ── Save the table ───────────────────────────────────────────────────────────
# gtsave(demog_table, filename = "t_demog_summary.html")
# gtsave(demog_table, filename = "t_demog_summary.rtf")

# ══════════════════════════════════════════════════════════════════════════════
# NEXT STEPS (in a real study):
# 1. Compare output against the mock shell from your TFL spec
# 2. Verify numbers match the QC programmer's independent output
# 3. Check rounding rules against the SAP
# 4. Review with your lead before finalizing
# ══════════════════════════════════════════════════════════════════════════════
