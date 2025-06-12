# Data utility functions for EU-Trees4F Viewer

# Constructs the path to a species data directory
get_species_path <- function(species, model_type = "ens_sdms") {
    file.path(DATA_DIR, paste0("EU-Trees4F_", species), model_type)
}

# Adds background values to raster where NA values exist
add_background_to_raster <- function(raster_data, countries, background_value = 50) {
    if(is.null(raster_data) || is.null(countries)) {
        return(raster_data)
    }

    tryCatch({
        # Convert countries to same CRS as raster
        countries_transformed <- st_transform(countries, crs(raster_data))
        countries_vect <- vect(countries_transformed)

        # Create a background raster with the background value
        background_raster <- raster_data
        background_raster[] <- background_value  # Fill with background value (0-10% category = 50 on 0-1000 scale)

        # Mask background to country boundaries
        background_masked <- mask(background_raster, countries_vect)

        # Where original raster has NA, use background values
        # Where original raster has values, keep original values
        result <- cover(raster_data, background_masked)

        return(result)

    }, error = function(e) {
        warning(paste("Error adding background to raster:", e$message))
        return(raster_data)
    })
}

# Loads and processes raster data for a specific species based on time period and climate scenario
load_species_raster <- function(species, time_period = "current", scenario = NULL, add_background = FALSE) {
    # Map time period to file naming convention
    mapped_time_period <- TIME_PERIOD_MAP[time_period]

    # Build the file name based on the time period and scenario
    # Current period doesn't include climate scenarios
    if(time_period == "current") {
        file_name <- paste0(species, "_ens-sdms_", mapped_time_period, "_prob_pot.tif")
    } else {
        # For future periods, climate scenario is required
        if(is.null(scenario)) scenario <- "rcp45"
        file_name <- paste0(species, "_ens-sdms_", scenario, "_", mapped_time_period, "_prob_pot.tif")
    }

    # Use only ens_sdms directory for consistent model type
    file_path <- file.path(get_species_path(species, "ens_sdms"), file_name)

    # Check if file exists before attempting to load
    if(!file.exists(file_path)) {
        warning(paste("File does not exist:", file_path))
        return(NULL)
    }

    # Load and process the raster with error handling
    tryCatch({
        # Load the raster using terra's rast() function
        r <- rast(file_path)

        # Get European countries mask for geographic filtering
        europe_mask <- load_europe_mask()

        # Apply European mask if available to limit display to relevant areas
        if(!is.null(europe_mask)) {
            # Ensure mask has same CRS and extent as raster
            if(crs(europe_mask) != crs(r)) {
                europe_mask <- project(europe_mask, crs(r))
            }
            # Mask the raster to only show European areas
            r <- mask(r, europe_mask)
        }

        # Add background for current period if requested
        if(add_background && time_period == "current") {
            countries <- load_europe_countries()
            r <- add_background_to_raster(r, countries, background_value = 10)
        }

        return(r)

    }, error = function(e) {
        warning(paste("Error loading raster:", e$message))
        return(NULL)
    })
}

# Creates a spatial mask of European countries for filtering raster data
load_europe_mask <- function() {
    tryCatch({
        # Get European countries from the Natural Earth dataset
        europe_countries <- ne_countries(scale = "medium", continent = "Europe", returnclass = "sf")
        # Exclude certain eastern countries to focus on central and western Europe
        excluded_countries <- c("Russia", "Ukraine", "Belarus")
        europe_filtered <- subset(europe_countries, !name %in% excluded_countries)
        # Convert to SpatVector format for compatibility with terra package
        europe_vect <- vect(europe_filtered)
        return(europe_vect)
    }, error = function(e) {
        warning(paste("Error creating Europe mask:", e$message))
        return(NULL)
    })
}

# Loads European country boundaries for map display
load_europe_countries <- function() {
    tryCatch({
        # Get European countries from the Natural Earth dataset
        europe_countries <- ne_countries(scale = "medium", continent = "Europe", returnclass = "sf")
        # Exclude certain eastern countries to focus on central and western Europe
        excluded_countries <- c("Russia", "Ukraine", "Belarus")
        europe_filtered <- subset(europe_countries, !name %in% excluded_countries)
        # Convert to EPSG:4326 (WGS84) to match the raster data coordinate system
        europe_filtered <- st_transform(europe_filtered, 4326)
        return(europe_filtered)
    }, error = function(e) {
        warning(paste("Error loading Europe countries:", e$message))
        return(NULL)
    })
}

# Creates a color palette function for visualizing habitat suitability in leaflet
create_color_palette <- function() {
    leaflet::colorNumeric(
        palette = HABITAT_COLORS,
        domain = c(0, 1000),
        na.color = "transparent"
    )
}
