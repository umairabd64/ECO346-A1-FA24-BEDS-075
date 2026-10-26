# 03_scatter.R -- Question 3: earnings against age, with weighted band means
# Run from the repository root:  Rscript scripts/03_scatter.R
library(ggplot2)
library(scales)

person <- read.csv("data/pslm_person_subset.csv")
hh     <- read.csv("data/pslm_hh_subset.csv")
hh <- hh[, c("hhid", "hhweight", "prov_code", "urban_rural")]
d  <- merge(person, hh, by = "hhid", all.x = TRUE)
earners <- subset(d, prov_code == 3 & urban_rural == 2 &
                     age >= 15 & age <= 64 & earn_annual > 0)

# five-year age bands 15-19, ..., 60-64; plotted at the midpoint (17, 22, ..., 62)
earners$band <- cut(earners$age, breaks = seq(15, 65, by = 5), right = FALSE,
                    labels = paste0(seq(15, 60, by = 5), "-", seq(19, 64, by = 5)))
bands <- do.call(rbind, lapply(split(earners, earners$band), function(g) {
  data.frame(band = g$band[1],
             n = nrow(g),
             mean_earn = sum(g$hhweight * g$earn_annual) / sum(g$hhweight))
}))
bands$mid  <- seq(17, 62, by = 5)
bands$thin <- bands$n < 30
bands$mean_earn <- round(bands$mean_earn)          # nearest whole rupee

dir.create("figures", showWarnings = FALSE)
write.csv(bands[, c("band", "n", "mean_earn")], "figures/band_table_R.csv", row.names = FALSE)

top <- bands[which.max(bands$mean_earn), ]
rs  <- function(v) paste0("Rs ", comma(round(v)))
lab <- function(v) paste0("Rs ", comma(v))
n_out <- sum(earners$earn_annual < 1e4 | earners$earn_annual > 1e7)

set.seed(346)   # fixed seed so the jitter is the same every run
p <- ggplot(earners, aes(age, earn_annual)) +
  geom_jitter(width = 0.4, height = 0, alpha = 0.18, size = 1.1, colour = "grey35") +
  geom_line(data = bands, aes(mid, mean_earn), colour = "#B22222", linewidth = 0.9) +
  geom_point(data = bands, aes(mid, mean_earn, shape = thin), colour = "#B22222",
             fill = "#B22222", size = 3.6, stroke = 1.1) +
  scale_shape_manual(values = c(`FALSE` = 21, `TRUE` = 1), guide = "none") +
  annotate("segment", x = top$mid - 6, xend = top$mid - 0.7, y = top$mean_earn * 3,
           yend = top$mean_earn * 1.12, colour = "#B22222",
           arrow = arrow(length = unit(0.12, "inches"))) +
  annotate("label", x = top$mid - 6, y = top$mean_earn * 3, hjust = 1,
           label = paste0("Highest band mean: ages ", top$band, "\n", rs(top$mean_earn)),
           colour = "#B22222", fill = "white", label.size = 0, size = 3.6) +
  scale_x_continuous(limits = c(14.5, 64.5), breaks = seq(15, 65, 10),
                     expand = expansion(mult = 0)) +
  scale_y_log10(breaks = 10^(4:7), labels = lab(10^(4:7)), minor_breaks = NULL) +
  coord_cartesian(ylim = c(1e4, 1e7)) +
  labs(title = paste0("In urban Sindh, average earnings climb with age and peak at ages ",
                      top$band),
       x = "Age (years)", y = "Annual earnings (rupees, log scale)",
       caption = paste0("Source: PSLM 2019-20 person and household files. Sample: ",
                        comma(nrow(earners)), " earners aged 15-64 in urban Sindh with earnings > 0.\n",
                        n_out, " earners outside the Rs 10,000-10,000,000 axis are not shown. ",
                        "Grey dots: individual earners (jittered, semi-transparent).\n",
                        "Red markers: weighted mean (hhweight) of each five-year band at its midpoint.\n",
                        "Hollow markers: bands with fewer than 30 unweighted observations.")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 12.5),
        plot.caption = element_text(hjust = 0, size = 8.5, colour = "grey30"),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.margin = margin(10, 20, 10, 10))

ggsave("figures/scatter.svg", p, width = 9, height = 5.8)
print(bands, row.names = FALSE)
cat("highest band:", as.character(top$band), top$mean_earn, "\n")
