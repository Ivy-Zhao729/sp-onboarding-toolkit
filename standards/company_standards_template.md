# Company Programming Standards Template

> **Instructions:** Replace this file with your organization's programming standards.
> This template shows the sections that are most useful for new SPs to have documented.

---

## General Conventions

### Program Headers
<!-- CUSTOMIZE: Describe your required program header format -->
- Every program must include: program name, purpose, study ID, author, creation date, modification history.

### Variable Naming
<!-- CUSTOMIZE: Your naming conventions -->
- SAS: All SDTM/ADaM variable names in UPPERCASE
- R: Follow tidyverse naming conventions for intermediate variables; final CDISC variables in UPPERCASE

### Code Style
<!-- CUSTOMIZE: Your style preferences -->
- Maximum line length: 80 characters
- Indentation: 4 spaces (no tabs)
- One statement per line

---

## Folder Structure

<!-- CUSTOMIZE: Replace with your actual folder structure -->
```
/study/
├── protocol/
├── pgm/
│   ├── sdtm/
│   ├── adam/
│   └── tfl/
├── data/
│   ├── raw/
│   ├── sdtm/
│   └── adam/
├── output/
│   ├── tables/
│   ├── figures/
│   └── listings/
├── macros/
├── specs/
└── validation/
```

---

## QC Process

<!-- CUSTOMIZE: Describe your QC workflow -->
1. Primary programmer creates the program and output
2. QC programmer independently derives the results
3. PROC COMPARE / diffdf is run to verify match
4. Both programmers sign off before the output is final

---

## Macro Library

<!-- CUSTOMIZE: List your standard macros and their purposes -->
| Macro Name | Purpose | Location |
|---|---|---|
| `%example1` | Description | `/macros/example1.sas` |
| `%example2` | Description | `/macros/example2.sas` |

---

## CDISC Versions in Use

<!-- CUSTOMIZE: Specify the standards your organization follows -->
- SDTM Implementation Guide: v3.4
- ADaM Implementation Guide: v1.3
- Controlled Terminology: [specify package date]
- Define-XML: v2.0
