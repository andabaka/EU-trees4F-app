# Statistical utility functions for EU-Trees4F Viewer

# Function to calculate country-specific statistics with terra
calculate_country_stats <- function(country_polygon, current_raster, future_raster = NULL, suitability_threshold = SUITABILITY_THRESHOLD) {
    tryCatch({
        # Convert country polygon to terra SpatVector for raster operations
        country_vect <- vect(country_polygon)

        # Crop and mask the current raster to the country boundary using terra functions
        current_country <- crop(current_raster, ext(country_vect))
        current_country <- mask(current_country, country_vect)

        # Calculate current suitable area within the country
        current_values <- values(current_country)
        current_suitable_cells <- sum(current_values > suitability_threshold, na.rm = TRUE)
        current_area <- current_suitable_cells * 10  # Assuming 10 km² per cell

        # If no future raster is provided, just return current stats
        if(is.null(future_raster)) {
            return(list(
                current_area = current_area,
                future_area = NA,
                area_change_percent = NA,
                north_shift_km = NA,
                risk_level = NA
            ))
        }

        # Crop and mask the future raster to the country boundary
        future_country <- crop(future_raster, ext(country_vect))
        future_country <- mask(future_country, country_vect)

        # Calculate future suitable area
        future_values <- values(future_country)
        future_suitable_cells <- sum(future_values > suitability_threshold, na.rm = TRUE)
        future_area <- future_suitable_cells * 10

        # Calculate area change percentage
        area_change_percent <- ifelse(current_area > 0,
                                      ((future_area - current_area) / current_area) * 100,
                                      ifelse(future_area > 0, 100, 0))

        # Calculate northward shift using terra functions
        north_shift_km <- calculate_northward_shift_terra(current_country, future_country)

        # Calculate risk level
        risk_level <- calculate_risk_level(area_change_percent)

        return(list(
            current_area = current_area,
            future_area = future_area,
            area_change_percent = area_change_percent,
            north_shift_km = north_shift_km,
            risk_level = risk_level
        ))
    }, error = function(e) {
        # Return default values if an error occurs
        warning(paste("Error calculating stats for a country:", e$message))
        return(list(
            current_area = 0,
            future_area = 0,
            area_change_percent = 0,
            north_shift_km = NA,
            risk_level = "Low"
        ))
    })
}


# Helper function to calculate northward shift with terra objects
calculate_northward_shift_terra <- function(current_raster, future_raster) {
    tryCatch({
        # Check if rasters are empty or all NA
        if (all(is.na(values(current_raster))) || all(is.na(values(future_raster)))) {
            return(NA)
        }

        # Create binary rasters of suitable areas
        current_suitable <- current_raster > SUITABILITY_THRESHOLD
        future_suitable <- future_raster > SUITABILITY_THRESHOLD

        # Count cells with values above threshold
        current_cells_count <- sum(values(current_suitable) > 0, na.rm = TRUE)
        future_cells_count <- sum(values(future_suitable) > 0, na.rm = TRUE)

        # If either raster doesn't have enough suitable cells, return NA
        if (current_cells_count < 10 || future_cells_count < 10) {
            return(NA)
        }

        # Get coordinates and values for suitable cells
        current_cells <- as.data.frame(current_suitable, xy = TRUE)
        current_cells <- current_cells[current_cells[[3]] > 0, ]

        future_cells <- as.data.frame(future_suitable, xy = TRUE)
        future_cells <- future_cells[future_cells[[3]] > 0, ]

        # Calculate simple centroids (not weighted)
        current_y_centroid <- mean(current_cells[[2]], na.rm = TRUE)  # column 2 is y/latitude
        future_y_centroid <- mean(future_cells[[2]], na.rm = TRUE)

        # Calculate shift in kilometers (111 km per degree of latitude approximately)
        lat_shift_degrees <- future_y_centroid - current_y_centroid
        north_shift_km <- lat_shift_degrees * 111

        return(north_shift_km)
    }, error = function(e) {
        warning(paste("Error calculating northward shift:", e$message))
        return(NA)
    })
}

# Calculate risk level based on area change percentage
calculate_risk_level <- function(area_change) {
    if(area_change < RISK_LEVELS$critical$threshold) return("Critical")
    else if(area_change < RISK_LEVELS$high$threshold) return("High")
    else if(area_change < RISK_LEVELS$moderate$threshold) return("Moderate")
    else return("Low")
}

# Create HTML for distribution statistics panel
create_statistics_html <- function(raster, species, time_period, scenario = NULL) {
    # Format species name for display
    display_species <- gsub("_", " ", species)

    if(time_period == "current") {
        # For current period, just show area
        current_area <- sum(values(raster) > SUITABILITY_THRESHOLD, na.rm = TRUE) * 10

        return(HTML(paste0(
            "<table class='table table-striped' style='width:100%'>",
            "<tr><td>Species:</td><td><strong>", display_species, "</strong></td></tr>",
            "<tr><td>Current Area:</td><td>", format(current_area, big.mark = ",", scientific = FALSE), " km²</td></tr>",
            "</table>"
        )))
    } else {
        # Get current distribution for comparison
        current_raster <- load_species_raster(species, "current", NULL)

        if(is.null(current_raster)) {
            return(HTML("<p>Error loading current distribution data.</p>"))
        }

        # Calculate area with suitability > threshold
        current_area <- sum(values(current_raster) > SUITABILITY_THRESHOLD, na.rm = TRUE) * 10
        future_area <- sum(values(raster) > SUITABILITY_THRESHOLD, na.rm = TRUE) * 10

        # Calculate area change
        area_change_percent <- ((future_area - current_area) / current_area) * 100

        # Calculate northward shift using terra functions
        north_shift_km <- calculate_northward_shift_terra(current_raster, raster)

        # Calculate risk level
        risk_level <- calculate_risk_level(area_change_percent)
        risk_class <- paste0("risk-", tolower(risk_level))

        # Get time period label
        period_label <- TIME_PERIOD_LABELS[which(TIME_PERIODS == time_period)]

        # Get scenario label
        scenario_label <- ifelse(scenario == "rcp45", "Moderate (RCP 4.5)", "High (RCP 8.5)")

        # Display distribution statistics
        return(HTML(paste0(
            "<table class='table table-striped' style='width:100%'>",
            "<tr><td>Species:</td><td><strong>", display_species, "</strong></td></tr>",
            "<tr><td>Time Period:</td><td>", period_label, "</td></tr>",
            "<tr><td>Scenario:</td><td>", scenario_label, "</td></tr>",
            "<tr><td>Current Area:</td><td>", format(current_area, big.mark = ",", scientific = FALSE), " km²</td></tr>",
            "<tr><td>Future Area:</td><td>", format(future_area, big.mark = ",", scientific = FALSE), " km²</td></tr>",
            "<tr><td>Area Change:</td><td>", format(area_change_percent, digits = 2), "%</td></tr>",
            "<tr><td>Northward Shift:</td><td>", ifelse(is.na(north_shift_km), "N/A", paste0(format(north_shift_km, digits = 2), " km")), "</td></tr>",
            "<tr><td>Risk Level:</td><td><span class='", risk_class, "'>", risk_level, "</span></td></tr>",
            "</table>"
        )))
    }
}
