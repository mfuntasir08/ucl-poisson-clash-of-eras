# ==========================================================
# 01_parameter_estimation.R
# Clash of Eras: UCL Poisson Model
# Calculates baseline lambdas and Attack/Defense ratings
# per era for UCL champion teams.
# ==========================================================

# ---- Packages (install once if missing) ----
# install.packages(c("dplyr", "readr", "tidyr", "ggplot2"))

library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)

# ---- Load data ----
df <- read_csv("data/ucl_analysis_sample.csv")

# ---- Baseline lambdas ----
# Two separate baselines are used because total goals scored and total
# goals conceded across the dataset are NOT equal (the dataset includes
# qualifying team-seasons, not a fully closed round-robin league).
baseline_lambda_gf <- sum(df$goals_scored)   / sum(df$match_played)   # goals scored baseline
baseline_lambda_ga <- sum(df$goals_conceded) / sum(df$match_played)   # goals conceded baseline

cat("Baseline lambda (scored)  :", round(baseline_lambda_gf, 4), "\n")
cat("Baseline lambda (conceded):", round(baseline_lambda_ga, 4), "\n")

# ---- Attack / Defense ratings per era (champions only) ----
results <- df %>%
  filter(champions == 1) %>%
  mutate(era_short = case_when(
    grepl("Era A", era) ~ "Era A",
    grepl("Era B", era) ~ "Era B",
    grepl("Era C", era) ~ "Era C"
  )) %>%
  group_by(era_short) %>%
  summarise(
    lam_gf  = weighted.mean(goals_pm, w = match_played),
    lam_ga  = weighted.mean(conceded_pm, w = match_played),
    attack  = lam_gf / baseline_lambda_gf,
    defense = lam_ga / baseline_lambda_ga
  ) %>%
  rename(era = era_short)

print(results)

# Save for downstream scripts
saveRDS(results, "output/era_ratings.rds")
write_csv(results, "output/era_ratings.csv")

# ==========================================================
# Visual: Attack & Defense ratings bar chart
# ==========================================================
ratings_long <- results %>%
  select(era, attack, defense) %>%
  pivot_longer(cols = c(attack, defense), names_to = "metric", values_to = "rating") %>%
  mutate(
    era = factor(era, levels = c("Era A", "Era B", "Era C")),
    metric = recode(metric, attack = "Attack Rating", defense = "Defense Rating")
  )

ggplot(ratings_long, aes(x = era, y = rating, fill = metric)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_hline(yintercept = 1.0, linetype = "dashed", color = "grey70", linewidth = 0.6) +
  geom_text(aes(label = sprintf("%.2f", rating)),
            position = position_dodge(width = 0.7), vjust = -0.5,
            color = "white", size = 4) +
  scale_fill_manual(values = c("Attack Rating" = "#1F4E8C", "Defense Rating" = "#E8871E")) +
  labs(
    title = "Attack & Defense Ratings of Champions by Era",
    x = NULL, y = "Rating (relative to baseline)", fill = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.background = element_rect(fill = "#1e1e1e", color = NA),
    panel.background = element_rect(fill = "#1e1e1e", color = NA),
    panel.grid.major = element_line(color = "#3a3a3a"),
    panel.grid.minor = element_blank(),
    text = element_text(color = "white"),
    axis.text = element_text(color = "white"),
    plot.title = element_text(face = "bold", hjust = 0.5, color = "white"),
    legend.position = "top",
    legend.text = element_text(color = "white")
  )

ggsave("output/attack_defense_ratings.png", width = 7, height = 4.5, dpi = 300)
