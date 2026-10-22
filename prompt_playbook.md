# Prompt Playbook: Ready-to-Use Recipes for New Statistical Programmers

> **How to use this guide:** Copy any prompt below, replace the `[bracketed]` placeholders with your actual study details, and paste it into the Claude sidebar in VS Code. These prompts are designed to give you the kind of guidance a senior SP would give — so you can keep moving without waiting for someone to be available.

---

## 1. SDTM Mapping: "Where does this CRF variable go?"

This is the most common question when you're new to SDTM. Use this when you have a raw/source variable and need to figure out which SDTM domain and variable it maps to.

### Prompt
```
I have a raw CRF variable from my source data:
- CRF form/page: [e.g., Vital Signs, Demographics, Medical History]
- Source variable name: [e.g., BP_POS]
- Source variable label: [e.g., "Was blood pressure taken while sitting or standing?"]
- Possible values: [e.g., SITTING, STANDING]

Based on CDISC SDTM IG 3.4:
1. Which SDTM domain should this map to?
2. What is the target SDTM variable name?
3. Is there controlled terminology I need to apply?
4. Show me the mapping logic in [SAS / R].
```

### When to use
- You're building an SDTM mapping for the first time
- You found a variable in the raw data and the annotated CRF doesn't make the mapping obvious
- You want to double-check your mapping before QC

---

## 2. ADaM Derivation: "How do I derive this analysis variable?"

ADaM derivations are where most new SPs spend their time. Use this when you need to create or debug a derived variable in an ADaM dataset.

### Prompt
```
I am working on the [ADSL / ADAE / ADVS / ADLB / ADPC / ADTTE] dataset.

I need to derive [variable name, e.g., TRTEMFL / AVISIT / BASE / CHG / AVAL]:
- The derivation rule from my ADaM spec says: "[paste the spec text or describe in plain English]"
- The source SDTM variables I'm working with are: [e.g., AESTDTC, TRTSDT, TRTEDT]
- My study uses [SAS / R].

Please:
1. Walk me through the derivation logic step by step
2. Write the code
3. Explain any assumptions (like date imputation or baseline definition)
4. Tell me what to check to make sure it's correct
```

### Common use cases
- Baseline flag (ABLFL) and baseline value (BASE) derivation
- Treatment-emergent flag (TRTEMFL) in ADAE
- Analysis visit windowing (AVISIT/AVISITN) in BDS datasets
- Change from baseline (CHG) and percent change (PCHG)
- Time-to-event variables (AVAL, CNSR) in ADTTE

---

## 3. PK/PD Concentration Data: "How do I set up my PC/PP or ADPC/ADPP?"

PK datasets have unique challenges — nominal vs. actual time, dose normalization, BLQ handling. Use this when working on pharmacokinetic data.

### Prompt
```
I am working on a [PC / PP / ADPC / ADPP] dataset for a PK study.

I need to [describe what you need, e.g.,:
- Calculate actual elapsed time from first/last dose
- Handle BLQ (below limit of quantification) values
- Derive Cmax / Tmax / AUC parameters
- Set up the ADPC BDS structure]

The relevant variables I have are: [e.g., PCDTC, PCTPT, PCTPTNUM, EXSTDTC, EXENDTC]

My study design: [e.g., single dose / multiple dose / crossover]

In [SAS / R], show me:
1. The derivation logic
2. Clean, well-commented code
3. Any CDISC-specific requirements I should be aware of
```

---

## 4. TFL Formatting: "How do I make this table look right?"

Clinical tables have very specific formatting rules — decimal alignment, n (%) display, proper headers and footnotes. Use this when your output doesn't match the mock shell.

### Prompt
```
I am generating a [table / listing / figure] in [SAS / R].

The table shows [describe content, e.g., "summary statistics for vital signs by treatment group and visit"].

I need to format:
- Continuous variables: [e.g., N, Mean (1 decimal), SD (2 decimals), Median (1 decimal), Min, Max]
- Categorical variables: [e.g., n (xx.x%)]
- The mock shell shows: [describe or paste the expected layout]

My source ADaM dataset is: [e.g., ADVS]

Please provide:
1. The formatting code using [PROC REPORT / sprintf / gt / rtables]
2. How to align decimals properly
3. How to handle missing values in the display
```

### Tips
- Always ask your lead for the mock shell (TFL specification) before you start programming
- Rounding rules should come from the SAP — don't guess

---

## 5. Debugging: "My program runs but the numbers don't match"

The most frustrating scenario for new SPs. Use this before you spend hours staring at the code.

### Prompt
```
My [SDTM / ADaM / TFL] program runs without errors, but the output doesn't match what's expected.

Here's what I see:
- Expected: [describe the expected result, e.g., "154 subjects in ADSL"]
- Actual: [describe what your program produces, e.g., "I'm getting 158 subjects"]
- The difference seems to be in: [if you have any idea, describe it]

Here's the relevant section of my code:
[paste the specific code section — NOT the entire program]

Can you:
1. Walk through the logic and identify where records might be gained or lost
2. Suggest a debugging approach (specific PROC FREQ, counts, or checks to run)
3. Tell me what's the most common cause of this kind of discrepancy
```

### Tips
- Always paste the **specific section** of code that's relevant, not your entire 500-line program
- Include the key variables and merge/join conditions
- Never paste real patient data — use USUBJID counts or summary numbers only

---

## 6. Code Review Prep: "Is my program ready for QC?"

Use this before you hand your program off for quality control. It's like having a senior SP do a quick pre-review.

### Prompt
```
I'm about to submit my [SDTM / ADaM / TFL] program for QC.

The program creates: [dataset name, e.g., ADSL]
Key derivations include: [list the main variables you derived]

Can you review my code for:
1. Common clinical programming mistakes (wrong merge keys, missing records, type mismatches)
2. CDISC compliance issues (non-standard variables, missing required variables)
3. Hardcoded values that should be data-driven
4. Missing sort orders or duplicate record issues

Here's my code:
[paste the code]
```

---

## 7. Understanding Specifications: "I don't understand what this spec is asking"

Specs are written by senior programmers or biostatisticians and can be hard to parse when you're new. Use this to translate spec language into plain English and code.

### Prompt
```
I'm reading the [SDTM / ADaM] specification for my study and I don't understand this derivation rule:

Variable: [e.g., AVISIT]
Derivation text from spec: "[paste the exact text from the spec]"

Can you:
1. Explain what this means in plain English
2. Give me an example with sample data showing input → output
3. Show me how to implement it in [SAS / R]
4. Flag anything that seems ambiguous that I should clarify with my lead
```

---

## 8. Controlled Terminology: "What codelist value should I use?"

CDISC controlled terminology has hundreds of codelists. Use this when you're not sure which codelist applies or what the correct value is.

### Prompt
```
I need to assign controlled terminology for:
- SDTM domain: [e.g., AE]
- Variable: [e.g., AESEV]
- The raw data value is: [e.g., "Mild"]

Based on current CDISC controlled terminology:
1. What is the correct codelist name?
2. What is the correct submission value?
3. Are there any common mapping pitfalls for this variable?
```

---

## Quick Reference: When to Use Which Prompt

| Situation | Prompt # |
|---|---|
| "I have a raw variable and don't know where it goes in SDTM" | 1 |
| "I need to derive a variable in ADaM" | 2 |
| "I'm working on PK concentration data" | 3 |
| "My table doesn't look right" | 4 |
| "My numbers don't match" | 5 |
| "Is my code ready for QC?" | 6 |
| "I don't understand what the spec is telling me" | 7 |
| "Which codelist value do I use?" | 8 |

---

> **Remember:** These prompts are starting points. The more context you give Claude — your therapeutic area, study phase, specific spec text, relevant variables — the better the answer. And always verify AI suggestions against your study specifications and with your QC programmer.
