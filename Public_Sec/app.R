library(shiny)
library(leaflet)
library(highcharter)
library(dplyr)

# Used to verify if uploaded dataset has correct columns
seg_col_names <- c("id", "data","latitude", "longitude", "policial_encarregado", "tipo_de_crime", "descrição", "situação")

source('ui.R', local = TRUE, encoding="utf-8")




# Define server logic 
server <- function(input, output, session) {
  
  
  # Loads an csv file
  myData <- reactive({
    if (is.null(input$file))
      return(NULL)
    
    # when reading semicolon separated files,
    # having a comma separator causes `read.csv` to error
    tryCatch(
      {
        df <- read.csv(input$file$datapath,
                       header = input$header,
                       sep = input$sep,
                       quote = input$quote,
                       encoding = "UTF-8")
      },
      error = function(e) {
        stop(safeError(e))
      }
    )
    
    df
  })
  
  
  # Calculates the centroids of cases with the same "tipo_de_crime" 
  centroids <- reactive({

    if(!identical(colnames(myData()), seg_col_names)){
      return(NULL)
    }
    
    data <- myData()

    centers <- merge(aggregate(latitude~tipo_de_crime, data, mean),aggregate(longitude~tipo_de_crime, data, mean))
  })
  
  # Checks if a file was uploaded
  output$fileUploaded <- reactive({
    return(!is.null(myData()))
  })
  outputOptions(output, 'fileUploaded', suspendWhenHidden=FALSE)
  
  
  
  # Table that appears on "Arquivo" tab
  output$contents <- DT::renderDataTable({
    df <- myData()
    ct <- centroids()
    if(input$disp == "head") {
      return(DT::datatable(head(df), width="100%", options = list(lengthChange = FALSE, scrollX = TRUE)))
    }
    else {
      return(DT::datatable(df,width="100%", options = list(lengthChange = FALSE, scrollX = TRUE)))
    }
    
  })
  
  
  
  # Map displaying security data. This map shows cases colored by their "tipo_de_crime", info when you click an individual circle
  # and the centroids previously mentioned 
  
  output$seg_map <- renderLeaflet({
    data_<- myData()

    if(is.null(data_) || !identical(colnames(data_), seg_col_names)){
      map <- leaflet() %>%
              addProviderTiles(providers$CartoDB.Positron) %>%
              setView(lng=-53.8008, lat=-29.6914, zoom = 13)
    }else{
      ct <- centroids()
      groups <- tolower(as.character(unique(data_$tipo_de_crime)))
      pal <- colorFactor(hcl.colors(length(unique(data_$tipo_de_crime)), palette = "Sunset"), domain = data_$tipo_de_crime)
      pop <- paste(
          "<b>Id do crime:</b>", data_$id, "<br>",
          "<b>Policial encarregado:</b>", data_$policial_encarregado, "<br>",
          "<b>Data ocorrência:</b>", data_$data, "<br>",
          "<b>Descrição da ocorrência:</b>", na.omit(data_$descrição), "<br>",
          "<b>Situação:</b>", data_$situação, "<br>"
      )
     
      map <-leaflet("map") %>%
              addProviderTiles(providers$CartoDB.Positron) %>%
              setView(lng=-53.8008, lat=-29.6914, zoom = 13) %>%
              addCircleMarkers(
                lng = data_$longitude, 
                lat =  data_$latitude,
                fillColor = pal(data_$tipo_de_crime),
                popup= pop,
                stroke = FALSE, fillOpacity = 0.8,
                group = tolower(data_$tipo_de_crime)
                
              ) %>%
              addCircleMarkers(
                lng = ct$longitude, 
                lat =  ct$latitude,
                stroke = TRUE,
                color = 'black', opacity = 0.8,
                fillOpacity = 1,
                radius = 13,
                fillColor = pal(ct$tipo_de_crime),
                label= paste("Centro dos casos do tipo",ct$tipo_de_crime),
                group = tolower(ct$tipo_de_crime)
                
              )%>%
              addLayersControl(overlayGroups = groups, position = "topright") %>%
              hideGroup(groups) %>%
              addLegend("bottomright", pal = pal, values = data_$tipo_de_crime,
                        title = "Tipo de crime",
                        opacity = 1
              )
    }
    
  })
  
  # Movable graph on the left showing the amount of cases per "tipo_de_crime"
  
  output$qnt_de_casos <- renderHighchart({
    
    data <- myData()
    
    if(!is.null(myData()) && identical(colnames(data), seg_col_names)){
    
      dt <- data %>%
        count(tipo_de_crime) %>%
        arrange(n) 
      
      hchart(dt, "bar", hcaes(tipo_de_crime, n)) %>% 
        hc_colors("SteelBlue") %>% 
        hc_title(text ="Quantidade de crimes por tipo") %>% 
        hc_xAxis(title = list(text = ""), gridLineWidth = 0, minorGridLineWidth = 0) %>% 
        hc_yAxis(title = list(text = "Incidentes"), gridLineWidth = 0, minorGridLineWidth = 0) %>%
        hc_tooltip(pointFormat = "Incidentes: <b>{point.y}</b>") %>% 
        hc_add_theme(hc_theme_smpl()) %>% 
        hc_chart(backgroundColor = "transparent")
    }
    
  })

  
  
}

# Run the application 
shinyApp(ui = ui, server = server)
