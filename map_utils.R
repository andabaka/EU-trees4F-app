# Map utility functions for EU-Trees4F Viewer

# Creates a color palette for habitat suitability visualization in leaflet
create_color_palette <- function() {

    # Reverse the HABITAT_COLORS which are defined from high to low
    reversed_colors <- rev(HABITAT_COLORS)

    # Create colorNumeric palette for continuous data values
    colorNumeric(
        palette = reversed_colors,
        domain = c(0, 1000),  # Raster values range from 0-1000
        na.color = "transparent"
    )
}

# Creates an empty leaflet map with base layer and default view settings
create_empty_map <- function() {
    leaflet(options = leafletOptions(
        zoomControl = FALSE,        # Hide zoom control buttons
        doubleClickZoom = TRUE,     # Enable double-click to zoom
        dragging = TRUE,            # Enable map dragging
        scrollWheelZoom = TRUE,     # Enable mouse wheel zoom - CRITICAL!
        touchZoom = TRUE,           # Enable touch zoom for mobile devices
        boxZoom = TRUE,             # Enable box zoom with Shift+drag
        keyboard = TRUE,            # Enable keyboard shortcuts
        zoomSnap = 0.1,             # Set smooth zoom increments
        zoomDelta = 0.5,            # Set zoom sensitivity
        wheelPxPerZoomLevel = 60    # Set scroll sensitivity
    )) %>%
        addProviderTiles(providers$CartoDB.Positron, group = "CartoDB Light") %>%
        setView(
            lng = MAP_DEFAULT_VIEW$lng,
            lat = MAP_DEFAULT_VIEW$lat,
            zoom = MAP_DEFAULT_VIEW$zoom
        )
}

# Creates a complete map with raster layer, legend, and layer controls
# Simplified version - no background polygons needed
create_base_map <- function(r) {
    # Create color palette
    pal <- create_color_palette()

    # Convert terra SpatRaster to raster object for leaflet
    r_for_leaflet <- raster::raster(r)

    # Create base leaflet map with interaction options
    leaflet(options = leafletOptions(
        zoomControl = FALSE,        # Hide zoom control buttons
        doubleClickZoom = TRUE,     # Enable double-click to zoom
        dragging = TRUE,            # Enable map dragging
        scrollWheelZoom = TRUE,     # Enable mouse wheel zoom - CRITICAL!
        touchZoom = TRUE,           # Enable touch zoom for mobile devices
        boxZoom = TRUE,             # Enable box zoom with Shift+drag
        keyboard = TRUE,            # Enable keyboard shortcuts
        zoomSnap = 0.1,             # Set smooth zoom increments
        zoomDelta = 0.5,            # Set zoom sensitivity
        wheelPxPerZoomLevel = 60    # Set scroll sensitivity
    )) %>%
        addProviderTiles(providers$CartoDB.Positron, group = "CartoDB Light") %>%
        addProviderTiles(providers$OpenStreetMap, group = "OpenStreetMap") %>%
        addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
        setView(
            lng = MAP_DEFAULT_VIEW$lng,
            lat = MAP_DEFAULT_VIEW$lat,
            zoom = MAP_DEFAULT_VIEW$zoom
        ) %>%
        addRasterImage(r_for_leaflet, colors = pal, opacity = 0.7, group = "Distribution") %>%
        addLegend(
            position = "bottomright",
            colors = HABITAT_COLORS,
            labels = HABITAT_LABELS,
            title = "Habitat suitability",
            opacity = 1
        ) %>%
        addLayersControl(
            baseGroups = c("CartoDB Light", "OpenStreetMap", "Satellite"),
            overlayGroups = c("Distribution"),
            options = layersControlOptions(collapsed = FALSE)
        )
}

# Adds country boundaries to the map with interactive tooltips and popups
add_countries_to_map <- function(map, countries, current_raster, future_raster = NULL, time_period = "current") {
    # Check if required data is available
    if(is.null(countries) || is.null(current_raster)) {
        return(map)
    }

    # Process each country to add boundaries and statistics
    for(i in 1:nrow(countries)) {
        tryCatch({
            country <- countries[i,]
            country_name <- country$name

            # Skip very small countries that might cause processing issues
            country_area_numeric <- as.numeric(st_area(country))
            if(country_area_numeric < 1e9) next

            # Calculate statistics for this country
            if(time_period == "current" || is.null(future_raster)) {
                # For current period, no need to compare
                country_stats <- calculate_country_stats(country, current_raster)
            } else {
                # For future periods, compare with current
                country_stats <- calculate_country_stats(country, current_raster, future_raster)
            }

            # Create popup content with country statistics
            popup_content <- create_country_popup(country_name, country_stats)

            # Add country to map with popup and hover effects
            map <- map %>%
                addPolygons(
                    data = country,
                    fillColor = "transparent",
                    fillOpacity = 0,
                    weight = 0.5,  # Thinner boundary line
                    color = "#999999",  # Light gray boundary
                    opacity = 0.7,
                    highlight = highlightOptions(
                        weight = 2,
                        color = "#666666",
                        fillOpacity = 0.1,
                        bringToFront = TRUE
                    ),
                    label = country_name,
                    popup = popup_content,
                    labelOptions = labelOptions(
                        style = list("font-weight" = "normal", padding = "3px 8px"),
                        textsize = "12px",
                        direction = "auto"
                    )
                )
        }, error = function(e) {
            # Skip this country if there's an error
            warning(paste("Error processing country:", e$message))
        })
    }

    return(map)
}

# Creates HTML popup content for a country showing habitat statistics
create_country_popup <- function(country_name, stats) {
    # Determine risk class for CSS styling
    risk_class <- ifelse(!is.na(stats$risk_level),
                         paste0("risk-", tolower(stats$risk_level)),
                         "")

    # Create appropriate popup content based on available data
    if(all(is.na(c(stats$future_area, stats$area_change_percent)))) {
        # For current time period only (no comparison)
        popup_content <- paste0(
            "<div class='country-info'>",
            "<h4>", country_name, "</h4>",
            "<table>",
            "<tr><td>Current Suitable Area:</td><td>", format(stats$current_area, big.mark = ",", scientific = FALSE), " km²</td></tr>",
            "</table>",
            "</div>"
        )
    } else {
        # For future time periods with comparison data
        popup_content <- paste0(
            "<div class='country-info'>",
            "<h4>", country_name, "</h4>",
            "<table>",
            "<tr><td>Current Suitable Area:</td><td>", format(stats$current_area, big.mark = ",", scientific = FALSE), " km²</td></tr>",
            "<tr><td>Future Suitable Area:</td><td>", format(stats$future_area, big.mark = ",", scientific = FALSE), " km²</td></tr>",
            "<tr><td>Area Change:</td><td>", format(stats$area_change_percent, digits = 2), "%</td></tr>",
            "<tr><td>Northward Shift:</td><td>", ifelse(is.na(stats$north_shift_km), "N/A", paste0(format(stats$north_shift_km, digits = 2), " km")), "</td></tr>",
            "<tr><td>Risk Level:</td><td><span class='", risk_class, "'>", stats$risk_level, "</span></td></tr>",
            "</table>",
            "</div>"
        )
    }

    return(popup_content)
}
