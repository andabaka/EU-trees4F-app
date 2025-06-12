# Configuration parameters for EU-Trees4F Viewer

# Base directory for species data files
DATA_DIR <- "Species_Data"

# List of species Latin names for processing
SPECIES_LIST <- c(
    "Abies_alba",
    "Carpinus_betulus",
    "Fagus_sylvatica",
    "Fraxinus_excelsior",
    "Picea_abies",
    "Quercus_petraea",
    "Quercus_robur"
)

# Display names for species (Latin name with common name in parentheses)
SPECIES_DISPLAY_NAMES <- c(
    "Abies alba (Silver fir)",
    "Carpinus betulus (Common hornbeam)",
    "Fagus sylvatica (European beech)",
    "Fraxinus excelsior (Common ash)",
    "Picea abies (Norway spruce)",
    "Quercus petraea (Sessile oak)",
    "Quercus robur (Pedunculate oak)"
)

# Time period identifiers for the model
TIME_PERIODS <- c("current", "near", "mid", "far")

# Human-readable labels for time periods
TIME_PERIOD_LABELS <- c(
    "1991-2020",
    "2021-2050",
    "2051-2080",
    "2081-2110"
)

# Mapping between time period identifiers and file naming conventions
TIME_PERIOD_MAP <- c(
    "current" = "cur2005",
    "near" = "fut2035",
    "mid" = "fut2065",
    "far" = "fut2095"
)

# Color scale for habitat suitability visualization (from highest to lowest suitability)
HABITAT_COLORS <- c(
    "#414a37", # 90-100%
    "#556b4a", # 80-90%
    "#6b8559", # 70-80%
    "#819f68", # 60-70%
    "#97b977", # 50-60%
    "#c4a676", # 40-50%
    "#d19855", # 30-40%
    "#de8a34", # 20-30%
    "#c8743a", # 10-20%
    "#b85d40"  # 0-10%
)

# Labels for habitat suitability legend (from highest to lowest)
HABITAT_LABELS <- c(
    "90-100%", # Highest category - displayed first/at top
    "80-90%",
    "70-80%",
    "60-70%",
    "50-60%",
    "40-50%",
    "30-40%",
    "20-30%",
    "10-20%",
    "0-10%"    # Lowest category - displayed last/at bottom
)

# Risk level definitions with thresholds and associated colors
RISK_LEVELS <- list(
    critical = list(threshold = -50, color = "#b85d40"),
    high = list(threshold = -30, color = "#c8743a"),
    moderate = list(threshold = -10, color = "#de8a34"),
    low = list(threshold = Inf, color = "#414a37")
)

# Threshold value for calculating suitable habitat areas (on 0-1000 scale)
SUITABILITY_THRESHOLD <- 500

# Default map view settings for initial display
MAP_DEFAULT_VIEW <- list(
    lng = 10,
    lat = 58,
    zoom = 4.5
)
