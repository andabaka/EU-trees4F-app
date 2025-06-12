# EU-Trees4F Interactive Viewer App
# Main application file with tree species and country statistics

# Load required libraries
library(shiny)
library(leaflet)
library(raster)
library(terra)
library(dplyr)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(leaflet.extras)
library(units)
library(shinyjs)

# Source helper functions
source("config.R")
source("data_utils.R")
source("map_utils.R")
source("stats_utils.R")

# UI definition
ui <- bootstrapPage(
    useShinyjs(),

    # External CSS
    includeCSS("www/styles.css"),

    # Full screen map
    leafletOutput("map", width = "100%", height = "100%"),

    # Content wrapper for scroll functionality
    div(class = "content-wrapper",
        # Central species title
        div(class = "central-species-title",
            textOutput("central_species_title")
        ),

        # Main container for controls and tree image
        div(class = "top-container",
            # Control panel - left side
            div(class = "controls-panel",
                div(class = "title",
                    span("European Tree Species Climate Suitability",
                         tags$sup(
                             icon("info-circle", class = "info-icon")
                         )
                    )
                ),

                # Species selection
                div(class = "control-group",
                    tags$label("Tree Species ", icon("tree"),
                               style = "font-weight: 600; color: #34495e; margin-bottom: 6px; display: block; font-size: 14px;"),
                    selectInput("species", NULL,
                                choices = setNames(SPECIES_LIST, SPECIES_DISPLAY_NAMES),
                                selected = "Abies_alba",
                                width = "100%")
                ),

                # Time period slider
                div(class = "control-group",
                    sliderInput("time_period", "Time Period:",
                                min = 1, max = 4, value = 1, step = 1,
                                ticks = TRUE, width = "100%"),
                    htmlOutput("time_period_label")
                ),

                # Climate scenario buttons
                div(class = "control-group", id = "scenario-container",
                    tags$label("Climate Scenario:"),
                    div(class = "btn-group", role = "group", id = "scenario-buttons",
                        tags$button(id = "rcp45", type = "button",
                                    class = "btn btn-primary active",
                                    onclick = "Shiny.setInputValue('scenario', 'rcp45')",
                                    "RCP 4.5"),
                        tags$button(id = "rcp85", type = "button",
                                    class = "btn btn-default",
                                    onclick = "Shiny.setInputValue('scenario', 'rcp85')",
                                    "RCP 8.5")
                    )
                ),

                # Reset button
                div(class = "control-group", style = "text-align: center;",
                    actionButton("reset_map", "Reset to Default",
                                 icon = icon("undo"),
                                 class = "btn reset-btn")
                )
            ),

            # Tree image panel
            div(id = "tree-image-display", class = "tree-image-panel",
                div(class = "image-container-full",
                    uiOutput("tree_image"),
                    # Image controls overlay
                    div(class = "image-controls-overlay",
                        actionButton("zoom_in", "", icon = icon("plus"), class = "control-btn-small"),
                        actionButton("zoom_out", "", icon = icon("minus"), class = "control-btn-small"),
                        actionButton("reset_image", "", icon = icon("refresh"), class = "control-btn-small")
                    )
                )
            )
        ),

        # Statistics panel
        div(id = "stats-container", class = "stats-panel",
            tags$h4("Overall Statistics"),
            htmlOutput("distribution_stats")
        )
    ),

    # Data source panel
    div(class = "data-source-panel",
        div(class = "data-source-content",
            tags$span("Data Source: "),
            tags$a("EU-Trees4F",
                   href = "https://data.jrc.ec.europa.eu/dataset/b2199de2-2fd8-44aa-9910-2ee9daa5ce93",
                   target = "_blank", class = "source-link"),
            tags$span(" | Tree Images: "),
            tags$a("free3D.com",
                   href = "https://free3d.com/",
                   target = "_blank", class = "source-link"),
            tags$span(" | Source Code: "),
            tags$a(href = "https://github.com/YourUsername/repository-name",
                   icon("github"), target = "_blank", class = "github-link"),
            tags$span(" | Author: "),
            tags$a("Marijana Andabaka",
                   href = "https://andalytics.com/en/",
                   target = "_blank", class = "author-link"),
            tags$span(", "),
            tags$a("marijana@andalytics.com",
                   icon("envelope"),
                   href = "mailto:marijana@andalytics.com",
                   class = "email-link")
        )
    ),

    # Hidden input for scenario
    tags$input(type = "hidden", id = "scenario", value = "rcp45"),

    # JavaScript for functionality
    tags$script(HTML("
    $(document).ready(function() {
      // Scenario button functionality
      $('#rcp45, #rcp85').on('click', function() {
        $('.btn-group .btn').removeClass('btn-primary active').addClass('btn-default');
        $(this).addClass('btn-primary active').removeClass('btn-default');
      });
    });

    // Image interaction variables
    let currentZoom = 1, currentX = 0, currentY = 0;
    let isDragging = false, startX, startY;

    // Zoom function
    function zoomImage(factor) {
      currentZoom = Math.max(0.3, Math.min(5, currentZoom * factor));
      updateImageTransform();
    }

    // Reset image function
    function resetImage() {
      currentZoom = 1; currentX = 0; currentY = 0;
      updateImageTransform();
    }

    // Update image transform
    function updateImageTransform() {
      const img = document.getElementById('tree-img');
      if (img) {
        img.style.transform = `translate(${currentX}px, ${currentY}px) scale(${currentZoom})`;
      }
    }

    // Mouse/touch drag functionality
    $(document).on('mousedown touchstart', '#tree-img', function(e) {
      isDragging = true;
      const clientX = e.type === 'mousedown' ? e.clientX : e.originalEvent.touches[0].clientX;
      const clientY = e.type === 'mousedown' ? e.clientY : e.originalEvent.touches[0].clientY;
      startX = clientX - currentX;
      startY = clientY - currentY;
      this.style.cursor = 'grabbing';
      e.preventDefault();
    });

    $(document).on('mousemove touchmove', function(e) {
      if (!isDragging) return;
      const clientX = e.type === 'mousemove' ? e.clientX : e.originalEvent.touches[0].clientX;
      const clientY = e.type === 'mousemove' ? e.clientY : e.originalEvent.touches[0].clientY;
      currentX = clientX - startX;
      currentY = clientY - startY;
      updateImageTransform();
      e.preventDefault();
    });

    $(document).on('mouseup touchend', function() {
      if (isDragging) {
        isDragging = false;
        const img = document.getElementById('tree-img');
        if (img) img.style.cursor = 'grab';
      }
    });

    // Mouse wheel zoom
    $(document).on('wheel', '#tree-img', function(e) {
      e.preventDefault();
      zoomImage(e.originalEvent.deltaY > 0 ? 0.9 : 1.1);
    });

    // Double-click reset
    $(document).on('dblclick', '#tree-img', resetImage);
  "))
)


# Server logic
server <- function(input, output, session) {

    # Species images mapping - update with your actual image names
    species_images <- list(
        "Fagus_sylvatica" = "fagus-sylvatica.jpg",
        "Quercus_robur" = "pedunculate_oak.jpg",
        "Quercus_petraea" = "sessile_oak.jpg",
        "Abies_alba" = "silver_fir.jpg",
        "Picea_abies" = "norway-spruce.jpg",
        "Carpinus_betulus" = "common-hornbeam.jpg",
        "Fraxinus_excelsior" = "common-ash.jpg"
    )

    # Update central species title dynamically - uses correct format
    output$central_species_title <- renderText({
        species <- input$species
        species_index <- which(SPECIES_LIST == species)
        if (length(species_index) > 0) {
            # Use display names which are already in "Latin (Common)" format
            display_name <- SPECIES_DISPLAY_NAMES[species_index]
            return(display_name)
        } else {
            return("Tree Species")
        }
    })

    # Update tree image when species changes
    observe({
        species <- input$species

        if (species %in% names(species_images)) {
            image_path <- paste0("trees/", species_images[[species]])
            species_index <- which(SPECIES_LIST == species)
            alt_text <- if (length(species_index) > 0) {
                SPECIES_DISPLAY_NAMES[species_index]
            } else {
                "Tree species"
            }

            output$tree_image <- renderUI({
                img(src = image_path, alt = alt_text,
                    class = "tree-species-image-full", id = "tree-img")
            })
        } else {
            # Fallback if no image available
            output$tree_image <- renderUI({
                div(class = "tree-placeholder-full",
                    icon("tree", style = "font-size: 60px; color: #999;"),
                    div("No image available", style = "margin-top: 10px; color: #999; font-size: 14px;"))
            })
        }
    })

    # Image control handlers
    observeEvent(input$zoom_in, { runjs("zoomImage(1.2);") })
    observeEvent(input$zoom_out, { runjs("zoomImage(0.8);") })
    observeEvent(input$reset_image, { runjs("resetImage();") })

    # Display time period label
    output$time_period_label <- renderUI({
        selected_period <- TIME_PERIOD_LABELS[input$time_period]
        HTML(paste0("<div class='custom-time-label'>", selected_period, "</div>"))
    })

    # Enable/disable scenario controls based on time period
    observe({
        if (input$time_period == 1) {
            shinyjs::disable("scenario-container")
            shinyjs::addClass("scenario-container", "disabled")
        } else {
            shinyjs::enable("scenario-container")
            shinyjs::removeClass("scenario-container", "disabled")
        }
    })

    # Load European countries
    europe_countries <- reactive({ load_europe_countries() })

    # Reactive values for map updates
    map_data <- reactive({
        species <- input$species
        time_period <- TIME_PERIODS[input$time_period]
        scenario <- ifelse(is.null(input$scenario), "rcp45", input$scenario)

        if(time_period == "current") scenario <- NULL

        # Add background only for current period
        add_bg <- (time_period == "current")
        r <- load_species_raster(species, time_period, scenario, add_background = add_bg)

        list(
            raster = r,
            species = species,
            time_period = time_period,
            scenario = scenario
        )
    })

    # Reset button functionality
    observeEvent(input$reset_map, {
        updateSelectInput(session, "species", selected = "Fagus_sylvatica")
        updateSliderInput(session, "time_period", value = 1)

        runjs("
          $('#rcp45').addClass('btn-primary active').removeClass('btn-default');
          $('#rcp85').removeClass('btn-primary active').addClass('btn-default');
          Shiny.setInputValue('scenario', 'rcp45');
        ")
    })

    # Create map with country statistics
    output$map <- renderLeaflet({
        data <- map_data()
        r <- data$raster
        species <- data$species
        time_period <- data$time_period
        scenario <- data$scenario

        if(is.null(r)) {
            showNotification("Failed to load raster data. Please check the data directory.",
                             type = "error", duration = 10)
            return(create_empty_map())
        }

        # Create base map - simple, no background polygons needed
        map <- create_base_map(r)

        # Load current raster for comparison (needed for country stats)

        current_raster <- load_species_raster(species, "current", NULL, add_background = FALSE)

        # Load countries
        countries <- load_europe_countries()

        # Add countries with popup statistics (these go on top as interactive elements)
        if(!is.null(countries) && !is.null(current_raster)) {
            if(time_period == "current") {
                # For current period, pass current raster only
                map <- add_countries_to_map(map, countries, current_raster, NULL, time_period)
            } else {
                # For future periods, pass both current and future rasters
                map <- add_countries_to_map(map, countries, current_raster, r, time_period)
            }
        }

        return(map)
    })

    # Update statistics panel
    observe({
        data <- map_data()
        r <- data$raster
        species <- data$species
        time_period <- data$time_period
        scenario <- data$scenario

        if(is.null(r)) return()

        output$distribution_stats <- renderUI({
            create_statistics_html(r, species, time_period, scenario)
        })
    })
}

# Run the application
shinyApp(ui = ui, server = server)
