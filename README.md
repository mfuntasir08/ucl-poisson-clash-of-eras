[README.md](https://github.com/user-attachments/files/31270021/README.md)
# Clash of Eras: UCL Poisson Model

Simulating hypothetical "dream matches" between UEFA Champions League champions from three different eras (1993–2020), using a Poisson probability model.

> What would happen if the 2005 Champions League-winning Liverpool played Klopp's 2019 champions? This project answers that kind of question statistically — using the same Poisson-based Attack/Defense framework that underpins the well-known Dixon-Coles football score prediction model.

## Overview

- **Course:** Probability Distributions (STA293)
- **Dataset:** 118 UCL team-seasons (1993–2020), champions vs non-winners
- **Eras:**
  - Era A (1993–2001) — Early Champions League era
  - Era B (2002–2010) — Mid-2000s tactical era
  - Era C (2011–2020) — High-scoring modern dominance era

## Method

1. **Baseline lambdas** — separate league-average scoring and conceding rates per match, computed across all team-seasons.
2. **Attack / Defense ratings** — each era's champions' scoring/conceding rate, normalized against the relevant baseline.
3. **Cross-era simulation** — for each matchup, expected goals (λ) are derived from Attack × Defense × baseline, then the Poisson distribution is applied per team to build a full scoreline probability matrix.
4. **Round-robin standings** — Win/Draw/Loss probabilities from all 3 matchups are combined into a mini league table (2 pts win, 1 pt draw) to determine the most dominant era.

## Results

| Era | Attack Rating | Defense Rating |
|---|---|---|
| Era A | 1.28 | 0.68 |
| Era B | 1.04 | 0.59 |
| Era C | 1.62 | 0.73 |

**Round-robin standings:** Era C (2.25 pts) > Era A (1.93 pts) > Era B (1.82 pts)

Era C's dominance is driven almost entirely by attacking output rather than defensive improvement — defense ratings stayed roughly flat across all three eras, while attack ratings climbed sharply in the modern era.

## Repository Structure

```
├── data/
│   └── ucl_analysis_sample.csv       # 118 UCL team-seasons, 1993–2020
├── scripts/
│   ├── 01_parameter_estimation.R     # Baseline lambdas + Attack/Defense ratings
│   └── 02_cross_era_simulation.R     # Poisson simulation, heatmaps, W/D/L, standings
├── output/                           # Generated plots and result tables (created on run)
└── README.md
```

## Requirements

```r
install.packages(c("dplyr", "readr", "tidyr", "ggplot2", "reshape2"))
```

## How to Run

1. Clone the repo and open it as your R working directory.
2. Run `scripts/01_parameter_estimation.R` first — this computes baseline lambdas and Attack/Defense ratings, saving them to `output/era_ratings.csv`.
3. Run `scripts/02_cross_era_simulation.R` — this simulates all three cross-era matchups and generates the scoreline heatmaps, Win/Draw/Loss chart, and round-robin standings chart in `output/`.

## Model Note

This project uses an **independent Poisson Attack-Defense model** — the same foundation the Dixon-Coles model (Dixon & Coles, 1997) is built on. It does not include the Dixon-Coles low-score correlation adjustment (τ), which corrects probabilities for low-scoring results (0-0, 1-0, 0-1, 1-1) using an additional correlation parameter (ρ). That refinement is a natural extension for future work.

## Author

Muntasir Islam — Data Science and Analytics, East West University
