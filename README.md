# code-sample
Stata/Python code for cleaning and analyzing VAT reform
# Fiscal Incentives, Allocative Efficiency, and the Unified National Market: Evidence from China's VAT Reform

Replication code for a staggered difference-in-differences analysis of how China's 2012–2016 VAT reform (replacing the business tax) affected firm productivity and cross-regional investment.

## Overview

China's replacement of the business tax with a value-added tax (VAT) turned local governments' largest wholly owned tax into one shared with the central government (75:25 initially). This project studies how this recentralization of tax revenue affected local government intervention in markets and the allocative efficiency of firms.

**Research question:** Did the reform raise firm productivity, through which channels, and how did local governments respond to the loss of revenue?

**Design:** Staggered DID on Chinese A-share listed firms, 2008–2023.
- **Treatment group:** transport and modern-service ("1+6") firms reformed in 2012–2014. Treatment year is 2012 for Shanghai, 2013 for eight early provinces, and 2014 for the rest.
- **Control group:** manufacturing industries with below-average dependence on services, built from the 2010 input–output table, to limit industry spillovers.
- **Outcome:** firm TFP (Levinsohn–Petrin; Olley–Pakes and GMM as robustness checks).

## Main Findings

| Result | Estimate |
|---|---|
| Baseline effect on TFP (TWFE, firm and year FE) | 0.155** |
| Callaway–Sant'Anna average treatment effect | 0.119*** |
| Event study: first vs. fifth post-reform period | 0.063 → 0.220 |
| Non-SOEs vs. local SOEs | 0.270 vs. 0.132 |
| Low vs. high initial market segmentation | 0.227 vs. 0.113 |
| New subsidiary in another region | +0.040*** |

- The reform raised TFP, with no pre-trends, and the effect builds up over time.
- Effects are larger for non-state-owned firms and in less segmented regions.
- Mechanisms: lower tax burdens and easier financing gave firms the means to expand across regions, while weaker local incentives to protect the tax base lowered the barriers to doing so.
- Local governments did not tighten tax enforcement, but tax rebates and bank credit shifted toward local SOEs, which likely dampened the efficiency gains.

## Repository Structure

```
├── code/
│   ├── 01_clean_data.[do/py/R]          # Merge firm data, winsorize at 1%/99%, construct variables
│   ├── 02_build_control_group.[...]     # Input–output table, direct consumption coefficients
│   ├── 03_estimate_tfp.[...]            # TFP: LP (baseline), OP, GMM
│   ├── 04_baseline_did.[...]            # TWFE and PSM-DID (Table 3)
│   ├── 05_robustness.[...]              # Placebo, spillovers, alternative samples (Tables 4–5)
│   ├── 06_callaway_santanna.[...]       # Heterogeneity-robust estimator and event study
│   ├── 07_heterogeneity.[...]           # Ownership and segmentation, permutation tests (Table 6)
│   └── 08_mechanisms.[...]              # Tax, rebates, financing, land, competition (Tables 7–10)
├── data/
│   ├── raw/                             # Not included (see Data)
│   └── clean/
├── output/
│   ├── tables/
│   └── figures/
└── README.md
```

## Data

The raw data are **not included** because they come from licensed databases.

| Data | Source |
|---|---|
| Firm financials, ownership, subsidiaries | CSMAR, Wind, annual reports |
| Local land supply and other regional data | EPS database |
| Input–output coefficients | 2010 Input–Output Table of China |
| Marketization index | NERI Marketization Index of China's Provinces (Wang et al., 2021) |
| Reform timeline | State Administration of Taxation, Ministry of Finance notices |

To replicate, obtain the data from these sources and place the files in `data/raw/`.

## Methods

- Two-way fixed effects DID (firm and year FE), with province, industry and year FE as an alternative; standard errors clustered at the province level
- Propensity score matching DID (cross-sectional and year-by-year matching)
- Callaway and Sant'Anna (2021) estimator and event study
- Placebo test (1,000 random draws) and permutation tests for subsample differences
- Robustness: indirect consumption coefficients, industry linkage, last reform batch (2016), sample through 2016, exclusion of firms that changed industry, main business or province

## How to Run

1. Clone the repository.
2. Place the raw data in `data/raw/`.
3. Set the working directory at the top of the first script.
4. Run the scripts in `code/` in numerical order.

**Requirements:** [e.g., Stata 17 with `reghdfe`, `csdid`, `psmatch2`, `estout`, `levpet` / Python 3.11 with pandas, linearmodels, statsmodels / R 4.3 with `did`, `fixest`]

## Notes

- All continuous variables are winsorized at the 1st and 99th percentiles.
- The paper reports results in 10 tables and several figures. The scripts above map to them as indicated in the comments.

## Author

Xinle Yang
