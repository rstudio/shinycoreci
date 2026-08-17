### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


library(ggvis)
library(dplyr)

all_movies <- readRDS("movies.rds")


function(input, output, session) {

  movies <- reactive({
    reviews <- input$reviews
    oscars <- input$oscars
    minyear <- input$year[1]
    maxyear <- input$year[2]
    minboxoffice <- input$boxoffice[1] * 1e6
    maxboxoffice <- input$boxoffice[2] * 1e6

    m <- all_movies %>%
      filter(
        Reviews >= reviews,
        Oscars >= oscars,
        Year >= minyear,
        Year <= maxyear,
        BoxOffice >= minboxoffice,
        BoxOffice <= maxboxoffice
      ) %>%
      arrange(Oscars)

    if (input$genre != "All") {
      m <- m %>% filter(grepl(input$genre, Genre, fixed = TRUE))
    }
    if (!is.null(input$director) && input$director != "") {
      m <- m %>% filter(grepl(input$director, Director, ignore.case = TRUE))
    }
    if (!is.null(input$cast) && input$cast != "") {
      m <- m %>% filter(grepl(input$cast, Cast, ignore.case = TRUE))
    }

    m <- as.data.frame(m)

    # Add column which says whether the movie won any Oscars
    # Be a little careful in case we have a zero-row data frame
    m$has_oscar <- character(nrow(m))
    m$has_oscar[m$Oscars == 0] <- "No"
    m$has_oscar[m$Oscars >= 1] <- "Yes"
    m
  })

  # Function for generating tooltip text
  movie_tooltip <- function(x) {
    if (is.null(x)) return(NULL)
    if (is.null(x$ID)) return(NULL)

    # Pick out the movie with this ID
    all_movies <- isolate(movies())
    movie <- all_movies[all_movies$ID == x$ID, ]

    paste0("<b>", movie$Title, "</b><br>",
      movie$Year, "<br>",
      "$", format(movie$BoxOffice, big.mark = ",", scientific = FALSE)
    )
  }

  # A reactive expression with the ggvis plot
  vis <- reactive({
    # Lables for axes
    xvar_name <- names(axis_vars)[axis_vars == input$xvar]
    yvar_name <- names(axis_vars)[axis_vars == input$yvar]

    # Normally we could do something like props(x = ~BoxOffice, y = ~Reviews),
    # but since the inputs are strings, we need to do a little more work.
    xvar <- prop("x", as.symbol(input$xvar))
    yvar <- prop("y", as.symbol(input$yvar))

    movies %>%
      ggvis(x = xvar, y = yvar) %>%
      layer_points(size := 50, size.hover := 200,
        fillOpacity := 0.2, fillOpacity.hover := 0.5,
        stroke = ~has_oscar, key := ~ID) %>%
      add_tooltip(movie_tooltip, "hover") %>%
      add_axis("x", title = xvar_name) %>%
      add_axis("y", title = yvar_name) %>%
      add_legend("stroke", title = "Won Oscar", values = c("Yes", "No")) %>%
      scale_nominal("stroke", domain = c("Yes", "No"),
        range = c("orange", "#aaa")) %>%
      set_options(width = 500, height = 500)
  })

  vis %>% bind_shiny("plot1")

  output$n_movies <- renderText({ nrow(movies()) })
}
