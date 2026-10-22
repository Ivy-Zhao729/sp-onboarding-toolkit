/******************************************************************************
* Program:    _template_tfl.sas
* Purpose:    TFL output template — replace with your company's standard
*             reporting macros and structure
* Study:      <!-- CUSTOMIZE: Insert study ID -->
* Output:     <!-- CUSTOMIZE: Table/Figure/Listing number and title -->
* Input:      <!-- CUSTOMIZE: Source ADaM dataset(s) -->
* Author:     <!-- CUSTOMIZE: Your name -->
* Date:       <!-- CUSTOMIZE: Date created -->
*
* Modification History:
* Date        Author      Description
* ---------   --------    ------------------------------------------------
*
******************************************************************************/

/* ── CUSTOMIZE: Set your libnames and output destination ────────────────── */
libname adam "<!-- path to ADaM data -->";

/* CUSTOMIZE: ODS setup for your company's output format */
ods listing close;
ods rtf file="<!-- path to output -->/<!-- output filename -->.rtf"
    style=<!-- CUSTOMIZE: your company's ODS style -->;

/* ── Step 1: Read source ADaM data and apply population filter ──────────── */
data work.analysis;
    set adam.<!-- ADaM dataset -->;
    where <!-- CUSTOMIZE: population flag, e.g., SAFFL = "Y" -->;
run;

/* ── Step 2: Calculate summary statistics ───────────────────────────────── */
/*
   CUSTOMIZE: This section depends entirely on your mock shell.

   For continuous variables (N, Mean, SD, Median, Min, Max):
   proc means data=work.analysis noprint;
       class TRT01A;
       var AVAL;
       output out=work.stats n=n mean=mean std=std median=median min=min max=max;
   run;

   For categorical variables (n, %):
   proc freq data=work.analysis noprint;
       tables TRT01A * AVALC / outpct out=work.freq;
   run;
*/

/* ── Step 3: Format results for display ─────────────────────────────────── */
/*
   CUSTOMIZE: String formatting per your mock shell and SAP rounding rules.

   Common formats:
   - Mean (1 decimal):     meanc = strip(put(mean, 8.1));
   - SD (2 decimals):      sdc   = strip(put(std, 8.2));
   - n (%):                nptc  = catx(" ", put(count, 3.), cats("(", put(pct, 5.1), ")"));
   - Min, Max:             rangec = catx(", ", put(min, 8.1), put(max, 8.1));
*/

/* ── Step 4: Output the table ───────────────────────────────────────────── */
/*
   CUSTOMIZE: Replace with your company's reporting macro or PROC REPORT.

   proc report data=work.report nowd split="~";
       column param stat trt1 trt2 trt3;
       define param / group "Parameter";
       define stat  / group "Statistic";
       define trt1  / display "Placebo~(N=xx)";
       define trt2  / display "Low Dose~(N=xx)";
       define trt3  / display "High Dose~(N=xx)";
   run;
*/

ods rtf close;
ods listing;
