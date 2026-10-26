# 02_histogram.R -- Question 2: weighted histogram of annual earnings on a log10 scale
# Run from the repository root:  Rscript scripts/02_histogram.R
library(ggplot2)
library(scales)

person <- read.csv("data/pslm_person_subset.csv")
hh     <- read.csv("data/pslm_hh_subset.csv")
hh <- hh[, c("hhid", "hhweight", "prov_code", "urban_rural")]
d  <- merge(person, hh, by = "hhid", all.x = TRUE)
earners <- subset(d, prov_code == 3 & urban_rural == 2 &
                     age >= 15 & age <= 64 & earn_annual > 0)

# weighted p-th quantile, exactly as defined in the assignment:
# sort by x, cumulative share of weight, smallest x whose share >= p
wquantile <- function(x, w, p) {
  o <- order(x); x <- x[o]; w <- w[o]
  share <- cumsum(w) / sum(w)
  x[which(share >= p)[1]]
}

x <- earners$earn_annual
w <- earners$hhweight

n_earners <- nrow(earners)
med_w   <- wquantile(x, w, 0.5)
med_u   <- median(x)
p10     <- wquantile(x, w, 0.1)
p90     <- wquantile(x, w, 0.9)
ratio   <- round(p90 / p10, 2)

# keep earners between Rs 10,000 and Rs 10,000,000 (log10 4.0 to 7.0)
inside   <- x >= 1e4 & x <= 1e7
n_excl   <- sum(!inside)
lx <- log10(x[inside]); lw <- w[inside]

# bins 0.1 wide in log10 units; the last bin includes 7.0
breaks <- seq(4, 7, by = 0.1)
bin <- cut(lx, breaks = breaks, include.lowest = TRUE, right = FALSE)
wbin <- tapply(lw, bin, sum); wbin[is.na(wbin)] <- 0
# density per log10 unit: weight share of the bin divided by bin width (0.1)
hist_df <- data.frame(mid = breaks[-length(breaks)] + 0.05,
                      density = as.numeric(wbin) / sum(lw) / 0.1)

rs <- function(v) paste0("Rs ", comma(round(v)))
lab <- function(v) paste0("Rs ", comma(v))

p <- ggplot(hist_df, aes(mid, density)) +
  geom_col(width = 0.1, fill = "#4C78A8", colour = "white", linewidth = 0.2) +
  geom_vline(xintercept = log10(c(med_w, p90)), linetype = "dashed", colour = "#B22222") +
  annotate("text", x = log10(med_w) - 0.04, y = max(hist_df$density) * 1.02, hjust = 1,
           label = paste0("Weighted median\n", rs(med_w)), colour = "#B22222", size = 3.6) +
  annotate("text", x = log10(p90) + 0.04, y = max(hist_df$density) * 1.02, hjust = 0,
           label = paste0("90th percentile\n", rs(p90)), colour = "#B22222", size = 3.6) +
  scale_x_continuous(breaks = 4:7, labels = lab(10^(4:7)), limits = c(4, 7),
                     expand = expansion(mult = 0.05)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = paste0("Half of Sindh's urban earners make under ", rs(med_w),
                      " a year; the top tenth make over ", rs(p90)),
       x = "Annual earnings (rupees, log scale)",
       y = "Density per log10 unit",
       caption = paste0("Source: PSLM 2019-20 person and household files. Sample: ",
                        comma(n_earners), " earners aged 15-64 in urban Sindh with earnings > 0.\n",
                        n_excl, " earners outside Rs 10,000-10,000,000 are excluded from the bars. ",
                        "Weighted by household weight (hhweight); lines are weighted percentiles.")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold", size = 12.5),
        plot.caption = element_text(hjust = 0, size = 8.5, colour = "grey30"),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.margin = margin(10, 20, 10, 10))

dir.create("figures", showWarnings = FALSE)
ggsave("figures/histogram.svg", p, width = 9, height = 5.5)

cat("earners:", n_earners, "\n")
cat("weighted median:", med_w, " unweighted median:", med_u, "\n")
cat("p10:", p10, " p90:", p90, " ratio:", sprintf("%.2f", ratio), "\n")
cat("excluded:", n_excl, "\n")
