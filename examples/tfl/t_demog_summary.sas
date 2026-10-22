/******************************************************************************
* Program:    t_demog_summary.sas
* Purpose:    Generate a demographics summary table from ADSL
*             (Table 14.1.1 — Subject Demographics and Baseline Characteristics)
* Study:      CDISCPILOT01
* Input:      ADSL
* Output:     Demographics summary table (RTF)
*
* Notes:      This is a TEACHING EXAMPLE using CDISCPILOT01 data.
*             It demonstrates how to create a standard demographics table
*             with continuous stats and categorical counts.
******************************************************************************/

/* ── Setup ──────────────────────────────────────────────────────────────── */
%let adam_path = /path/to/cdiscpilot01/adam;  /* CUSTOMIZE this path */

libname adam xport "&adam_path" access=readonly;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 1: READ AND PREPARE DATA
   ══════════════════════════════════════════════════════════════════════════ */

data work.adsl;
    set adam.adsl;
    where ITTFL = "Y";  /* ITT population per SAP */
run;

/* Get big-N counts per treatment group for column headers */
proc sql noprint;
    select count(*) into :n_pbo  trimmed from work.adsl where TRT01PN = 1;
    select count(*) into :n_low  trimmed from work.adsl where TRT01PN = 2;
    select count(*) into :n_high trimmed from work.adsl where TRT01PN = 3;
    select count(*) into :n_tot  trimmed from work.adsl;
quit;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 2: CONTINUOUS VARIABLES — Age
   ──────────────────────────────────────────────────────────────────────────
   Standard display: N, Mean (SD), Median, Min, Max
   Formatting per SAP: Mean to 1 decimal, SD to 2 decimals
   ══════════════════════════════════════════════════════════════════════════ */

/* Calculate stats by treatment group */
proc means data=work.adsl noprint;
    class TRT01PN;
    var AGE;
    output out=work.age_stats
        n=n mean=mean std=std median=median min=min max=max;
run;

/* Format for display */
data work.age_display;
    set work.age_stats;
    where TRT01PN ^= . or _TYPE_ = 0;

    length col $30 param $40 stat $20;
    param = "Age (years)";

    /* N */
    stat = "n";
    col = strip(put(n, 8.0));
    ord1 = 1; ord2 = 1;
    output;

    /* Mean (SD) */
    stat = "Mean (SD)";
    col = catx(" ", strip(put(mean, 8.1)),
                    cats("(", strip(put(std, 8.2)), ")"));
    ord1 = 1; ord2 = 2;
    output;

    /* Median */
    stat = "Median";
    col = strip(put(median, 8.1));
    ord1 = 1; ord2 = 3;
    output;

    /* Min, Max */
    stat = "Min, Max";
    col = catx(", ", strip(put(min, 8.1)), strip(put(max, 8.1)));
    ord1 = 1; ord2 = 4;
    output;

    keep TRT01PN param stat col ord1 ord2;
run;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 3: CATEGORICAL VARIABLES — Sex, Race, Ethnicity
   ──────────────────────────────────────────────────────────────────────────
   Standard display: n (xx.x%)
   ══════════════════════════════════════════════════════════════════════════ */

/* Sex */
proc freq data=work.adsl noprint;
    tables TRT01PN * SEX / outpct out=work.sex_freq;
run;

data work.sex_display;
    set work.sex_freq;
    length col $30 param $40 stat $20;
    param = "Sex";
    stat  = SEX;
    col   = catx(" ", strip(put(COUNT, 8.)),
                      cats("(", strip(put(PCT_ROW, 5.1)), ")"));
    ord1 = 2;
    if      SEX = "F" then ord2 = 1;
    else if SEX = "M" then ord2 = 2;
    keep TRT01PN param stat col ord1 ord2;
run;

/* Race */
proc freq data=work.adsl noprint;
    tables TRT01PN * RACE / outpct out=work.race_freq;
run;

data work.race_display;
    set work.race_freq;
    length col $30 param $40 stat $40;
    param = "Race";
    stat  = RACE;
    col   = catx(" ", strip(put(COUNT, 8.)),
                      cats("(", strip(put(PCT_ROW, 5.1)), ")"));
    ord1 = 3;
    if      RACE = "WHITE"                       then ord2 = 1;
    else if RACE = "BLACK OR AFRICAN AMERICAN"   then ord2 = 2;
    else if RACE = "ASIAN"                       then ord2 = 3;
    else                                              ord2 = 4;
    keep TRT01PN param stat col ord1 ord2;
run;

/* Ethnicity */
proc freq data=work.adsl noprint;
    tables TRT01PN * ETHNIC / outpct out=work.eth_freq;
run;

data work.eth_display;
    set work.eth_freq;
    length col $30 param $40 stat $50;
    param = "Ethnicity";
    stat  = ETHNIC;
    col   = catx(" ", strip(put(COUNT, 8.)),
                      cats("(", strip(put(PCT_ROW, 5.1)), ")"));
    ord1 = 4;
    if      ETHNIC = "HISPANIC OR LATINO"     then ord2 = 1;
    else if ETHNIC = "NOT HISPANIC OR LATINO" then ord2 = 2;
    keep TRT01PN param stat col ord1 ord2;
run;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 4: COMBINE AND TRANSPOSE
   ══════════════════════════════════════════════════════════════════════════ */

data work.all_stats;
    set work.age_display
        work.sex_display
        work.race_display
        work.eth_display;
run;

proc sort data=work.all_stats;
    by ord1 ord2 TRT01PN;
run;

/* Transpose: one row per parameter/stat, columns for each treatment */
proc transpose data=work.all_stats out=work.report_data prefix=trt;
    by ord1 ord2 param stat;
    id TRT01PN;
    var col;
run;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 5: PRODUCE THE TABLE
   ══════════════════════════════════════════════════════════════════════════ */

options nodate nonumber;
ods listing close;
ods rtf file="t_demog_summary.rtf" style=journal;

title1 "Table 14.1.1";
title2 "Summary of Demographics and Baseline Characteristics";
title3 "ITT Population";

proc report data=work.report_data nowd split="|";
    columns ord1 ord2 param stat trt1 trt2 trt3;

    define ord1  / order noprint;
    define ord2  / order noprint;
    define param / order "Parameter"
                   style(column)=[width=2in];
    define stat  / display "Statistic"
                   style(column)=[width=2in];
    define trt1  / display "Placebo|(N=&n_pbo.)"
                   style(column)=[width=1.2in just=c];
    define trt2  / display "Xanomeline|Low Dose|(N=&n_low.)"
                   style(column)=[width=1.2in just=c];
    define trt3  / display "Xanomeline|High Dose|(N=&n_high.)"
                   style(column)=[width=1.2in just=c];

    compute after ord1;
        line " ";
    endcomp;
run;

footnote1 "Source: ADSL (ITT Population)";
footnote2 "Percentages are based on the number of subjects in each treatment group.";

ods rtf close;
ods listing;

/*
   ═══════════════════════════════════════════════════════════════
   NEXT STEPS (in a real study):
   1. Compare output against the mock shell from your TFL spec
   2. Verify numbers match the QC programmer's independent output
   3. Check rounding rules against the SAP
   4. Review with your lead before finalizing
   ═══════════════════════════════════════════════════════════════
*/
