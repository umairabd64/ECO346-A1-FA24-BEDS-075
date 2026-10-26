# 01_default.R -- Question 4: R's untouched default scatterplot (variant 3 = Sindh urban)
# Run from the repository root:  Rscript scripts/01_default.R
library(ggplot2)

person <- read.csv("data/pslm_person_subset.csv")
hh     <- read.csv("data/pslm_hh_subset.csv")

# attach weight, province and area from the household file by hhid
hh <- hh[, c("hhid", "hhweight", "prov_code", "urban_rural")]
d  <- merge(person, hh, by = "hhid", all.x = TRUE)

# variant 3 = Sindh (prov_code 3), urban (urban_rural 2); earners aged 15-64
earners <- subset(d, prov_code == 3 & urban_rural == 2 &
                     age >= 15 & age <= 64 & earn_annual > 0)

dir.create("figures", showWarnings = FALSE)
p <- ggplot(earners, aes(age, earn_annual)) + geom_point()   # nothing else added
ggsave("figures/default.svg", p, width = 7, height = 5)
cat("earners:", nrow(earners), "\n")
