# ==========================================================
# 02_cross_era_simulation.R
# Clash of Eras: UCL Poisson Model
# Simulates hypothetical cross-era matchups using the Poisson
# distribution, and builds scoreline, W/D/L, and round-robin
# standings visuals.
#
# Requires 01_parameter_estimation.R to have been run first
# (reads output/era_ratings.rds).
# ==========================================================

# install.packages(c("dplyr", "tidyr", "ggplot2", "reshape2"))

library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)

# ---- Load ratings computed in script 01 ----
ratings <- readRDS("output/era_ratings.rds")

# Baseline lambda (goals scored) — recomputed here so this script can also
# run standalone without re-running script 01.
df <- readr::read_csv("data/ucl_analysis_sample.csv")
baseline_gf <- sum(df$goals_scored) / sum(df$match_played)

# ---- Function: compute lambda1, lambda2 for a matchup ----
get_lambdas <- function(e1, e2) {
  a1 <- ratings$attack[ratings$era == e1]; d1 <- ratings$defense[ratings$era == e1]
  a2 <- ratings$attack[ratings$era == e2]; d2 <- ratings$defense[ratings$era == e2]
  lam1 <- a1 * d2 * baseline_gf
  lam2 <- a2 * d1 * baseline_gf
  list(lam1 = lam1, lam2 = lam2)
}

# ---- Function: build scoreline probability matrix (0 to 5+) ----
score_matrix <- function(lam1, lam2, maxg = 5) {
  p1 <- dpois(0:(maxg - 1), lam1); p1 <- c(p1, 1 - sum(p1))
  p2 <- dpois(0:(maxg - 1), lam2); p2 <- c(p2, 1 - sum(p2))
  M <- outer(p1, p2)
  rownames(M) <- c(0:(maxg - 1), paste0(maxg, "+"))
  colnames(M) <- c(0:(maxg - 1), paste0(maxg, "+"))
  M
}

# ---- Function: Win/Draw/Loss from matrix ----
get_wdl <- function(M) {
  win  <- sum(M[lower.tri(M)])
  draw <- sum(diag(M))
  loss <- sum(M[upper.tri(M)])
  c(win = win, draw = draw, loss = loss)
}

matchups <- list(c("Era A", "Era B"), c("Era B", "Era C"), c("Era A", "Era C"))

# ==========================================================
# Run simulation for all matchups
# ==========================================================
heatmap_list <- list()
wdl_results <- data.frame()

for (m in matchups) {
  e1 <- m[1]; e2 <- m[2]
  lams <- get_lambdas(e1, e2)
  M <- score_matrix(lams$lam1, lams$lam2)
  wdl <- get_wdl(M)

  wdl_results <- rbind(wdl_results, data.frame(
    matchup = paste(e1, "vs", e2),
    lam1 = lams$lam1, lam2 = lams$lam2,
    win = wdl["win"], draw = wdl["draw"], loss = wdl["loss"]
  ))

  df_long <- melt(M)
  colnames(df_long) <- c("g1", "g2", "prob")
  df_long$matchup <- paste(e1, "-", e2)
  heatmap_list[[paste(e1, e2)]] <- df_long
}

heatmap_all <- bind_rows(heatmap_list)
write.csv(wdl_results, "output/wdl_results.csv", row.names = FALSE)
print(wdl_results)

# ==========================================================
# VISUAL 1: Scoreline heatmap grid (3 matchups)
# ==========================================================
ggplot(heatmap_all, aes(x = g2, y = g1, fill = prob)) +
  geom_tile(color = "#1e1e1e") +
  geom_text(aes(label = sprintf("%.1f", prob * 100)), color = "white", size = 3.2) +
  facet_wrap(~matchup, ncol = 3) +
  scale_fill_gradient(low = "#1F4E8C", high = "#E8871E", name = "Prob (%)") +
  labs(title = "Scoreline Probability Matrices", x = "Opponent Goals", y = "Team Goals") +
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#1e1e1e", color = NA),
    panel.background = element_rect(fill = "#1e1e1e", color = NA),
    strip.background = element_rect(fill = "#333333", color = NA),
    strip.text = element_text(color = "white", face = "bold"),
    text = element_text(color = "white"),
    axis.text = element_text(color = "white"),
    plot.title = element_text(face = "bold", hjust = 0.5, color = "white"),
    legend.text = element_text(color = "white"),
    legend.title = element_text(color = "white"),
    panel.grid = element_blank()
  )

ggsave("output/scoreline_heatmaps.png", width = 11, height = 4.2, dpi = 300)

# ==========================================================
# VISUAL 2: Win / Draw / Loss grouped bar chart
# ==========================================================
wdl_long <- wdl_results %>%
  select(matchup, win, draw, loss) %>%
  pivot_longer(cols = c(win, draw, loss), names_to = "outcome", values_to = "prob") %>%
  mutate(outcome = recode(outcome, win = "Team 1 Win", draw = "Draw", loss = "Team 2 Win"))

ggplot(wdl_long, aes(x = matchup, y = prob, fill = outcome)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(aes(label = sprintf("%.0f%%", prob * 100)),
            position = position_dodge(width = 0.75), vjust = -0.4, color = "white", size = 3.5) +
  scale_fill_manual(values = c("Team 1 Win" = "#1F4E8C", "Draw" = "#CCCCCC", "Team 2 Win" = "#E8871E")) +
  labs(title = "Win / Draw / Loss Probabilities Across Matchups", x = NULL, y = "Probability", fill = NULL) +
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

ggsave("output/wdl_probabilities.png", width = 7.5, height = 4.5, dpi = 300)

# ==========================================================
# VISUAL 3: Round-robin standings
# ==========================================================
points <- data.frame(era = c("Era A", "Era B", "Era C"), points = c(0, 0, 0))
for (i in 1:nrow(wdl_results)) {
  e1 <- strsplit(wdl_results$matchup[i], " vs ")[[1]][1]
  e2 <- strsplit(wdl_results$matchup[i], " vs ")[[1]][2]
  points$points[points$era == e1] <- points$points[points$era == e1] + 2 * wdl_results$win[i] + wdl_results$draw[i]
  points$points[points$era == e2] <- points$points[points$era == e2] + 2 * wdl_results$loss[i] + wdl_results$draw[i]
}
points <- points %>% arrange(desc(points))
write.csv(points, "output/round_robin_standings.csv", row.names = FALSE)
print(points)

ggplot(points, aes(x = reorder(era, points), y = points, fill = era)) +
  geom_col(width = 0.55) +
  geom_text(aes(label = sprintf("%.2f pts", points)), hjust = -0.15, color = "white", size = 4.5) +
  coord_flip() +
  scale_fill_manual(values = c("Era A" = "#1F4E8C", "Era B" = "#888888", "Era C" = "#E8871E")) +
  labs(title = "Simulated Round-Robin Standings", x = NULL, y = "Expected Points") +
  theme_minimal(base_size = 13) +
  theme(
    plot.background = element_rect(fill = "#1e1e1e", color = NA),
    panel.background = element_rect(fill = "#1e1e1e", color = NA),
    panel.grid.major = element_line(color = "#3a3a3a"),
    panel.grid.minor = element_blank(),
    text = element_text(color = "white"),
    axis.text = element_text(color = "white"),
    plot.title = element_text(face = "bold", hjust = 0.5, color = "white"),
    legend.position = "none"
  )

ggsave("output/round_robin_standings.png", width = 7, height = 4, dpi = 300)
