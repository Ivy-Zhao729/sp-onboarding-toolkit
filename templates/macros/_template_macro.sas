/******************************************************************************
* Macro:      _template_macro.sas
* Purpose:    Standard utility macro template — replace with your company's
*             macro library entries
* Author:     <!-- CUSTOMIZE: Your name -->
* Date:       <!-- CUSTOMIZE: Date created -->
*
* CUSTOMIZE: Replace this entire file with your organization's standard
*            macros. Common examples include:
*            - %demog       (demographics summary table)
*            - %ae_summary  (adverse event summary)
*            - %pkparam     (PK parameter calculations)
*            - %fmt_decimal (decimal alignment formatting)
*            - %pgm_header  (standard program header)
*
******************************************************************************/

/* Example: A simple formatting macro as a starting point */

%macro fmt_stat(value=, dec=1);
    /* Format a numeric value to a specified number of decimal places */
    /* Usage: %fmt_stat(value=mean_val, dec=1) */
    strip(put(&value., 8.&dec.))
%mend fmt_stat;
