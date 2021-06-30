library(shiny)
library(leaflet)
library(highcharter)
library(dplyr)
library(tibble)

# Used to verify if uploaded dataset has correct columns
seg_col_names <- c("id", "data","latitude", "longitude", "policial_encarregado", "descrição", "situação")

source('ui.R', local = TRUE, encoding="utf-8")

`%notin%` <- Negate(`%in%`)


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
  
 
  
  output$has_no_class <- reactive({
    data <- myData()
    if(is.null(data) || !all(seg_col_names %in% colnames(data)) || "tipo_de_crime" %in% colnames(data)) return(0)
  
    
    return(1)
  })
  outputOptions(output, 'has_no_class', suspendWhenHidden=FALSE)
  
  
  # Calculates the centroids of cases with the same "tipo_de_crime" 
  centroids <- reactive({
    
    data <- myData()

    if(!all(seg_col_names %in% colnames(data))){
      return(NULL)
    }
  
    centers <- merge(aggregate(latitude~tipo_de_crime, data, mean),aggregate(longitude~tipo_de_crime, data, mean))
  })
  
  # Calculates the clusters and centroids of cases without column "tipo_de_crime".
  # The amt of clusters is defined by input$amt_clusters
  k_means <- reactive({
    data_ <-myData()
    #print(input$amt_clusters)
    if(is.na(input$amt_clusters) || input$amt_clusters<1) return(NULL)
    kmeans(data_ %>% select(latitude, longitude), input$amt_clusters)
    
  })
  
  
  
  # Checks if a file was uploaded
  output$fileUploaded <- reactive({
    return(!is.null(myData()))
  })
  outputOptions(output, 'fileUploaded', suspendWhenHidden=FALSE)

  
  # Table that appears on "Arquivo" tab
  output$contents <- DT::renderDataTable({
    df <- myData()
    if(input$disp == "head") {
      return(DT::datatable(head(df), width="100%", options = list(lengthChange = FALSE, scrollX = TRUE)))
    }
    else {
      return(DT::datatable(df,width="100%", options = list(lengthChange = FALSE, scrollX = TRUE)))
    }
    
  })
  
  
  # Base map
  baseMap <- leaflet("baseMap") %>%
    addProviderTiles(providers$CartoDB.Positron) %>%
    setView(lng=-53.8008, lat=-29.6914, zoom = 13)%>% 
    addMapPane("centroids", zIndex = 420) %>%  addMapPane("crimes", zIndex = 410)  
  
  
  # Map displaying security data. This map shows cases colored by their "tipo_de_crime", info when you click an individual circle
  # and the centroids previously mentioned 
  output$with_class_map <- renderLeaflet({
    data_ <-myData()
    if(is.null(data_) || !all(seg_col_names %in% colnames(data_))) return(baseMap)
    
    ct <- centroids()
    crimes <- tolower(as.character(unique(data_$tipo_de_crime)))
    pal <- colorFactor(hcl.colors(length(unique(data_$tipo_de_crime)), palette = "Sunset"), domain = data_$tipo_de_crime)
    pop <- paste(
      "<b>Id do crime:</b>", data_$id, "<br>",
      "<b>Policial encarregado:</b>", data_$policial_encarregado, "<br>",
      "<b>Data ocorrência:</b>", data_$data, "<br>",
      "<b>Descrição da ocorrência:</b>", na.omit(data_$descrição), "<br>",
      "<b>Situação:</b>", data_$situação, "<br>"
    )
  
    baseMap %>% 
      # This circles are the crimes circles
      addCircleMarkers( lng = data_$longitude, lat =  data_$latitude,
                      fillColor = pal(data_$tipo_de_crime), popup= pop,
                      stroke = FALSE, fillOpacity = 0.8,
                      group = tolower(data_$tipo_de_crime), options = pathOptions(pane = "crimes")
      )%>%
      # This circles are the centroids circles
      addCircleMarkers(lng = ct$longitude, lat =  ct$latitude,
                       stroke = TRUE, color = 'black', opacity = 0.8,
                       fillOpacity = 1, radius = 13, fillColor = pal(ct$tipo_de_crime),
                       label= paste("Centro dos casos do tipo",ct$tipo_de_crime),
                       group = crimes, options = pathOptions(pane = "centroids")
                       
      )%>%
      addLayersControl(overlayGroups = crimes, position = "topright",
                       options = layersControlOptions(collapsed = FALSE)) %>%
      hideGroup(crimes) %>%
      addLegend("topright", pal = pal, values = data_$tipo_de_crime,
                title = "Tipo de crime",
                opacity = 1
      )
    
  })
  
  
  
  # Map without classification on data. Uses k-means to cluster
  output$without_class_map <- renderLeaflet({
    baseMap
  })
  
  # Observes for change in input$amt_clusters and updates "without_class_map".
  observeEvent(input$amt_clusters,{
    data_ <-myData()
    
    if(is.null(data_) || !all(seg_col_names %in% colnames(data_))) return(baseMap)
    
    km<-k_means() 
    
    if(is.null(km)){
      showNotification("Valor inválido para o K-means", type = "error", duration = 2) 
      return(NULL)
    } 

    # Creates a data table for centroids data
    ct<-data.table::as.data.table(km$centers, .keep.rownames = "word")
    ct<-cbind(as.data.frame(rownames(ct)), ct)
    colnames(ct)[1]<- "cluster"

    class <- km$cluster
    crimes <- tolower(as.character(unique(class)))
    pal <- colorFactor(hcl.colors(length(unique(class)), palette = "Sunset"), domain = class)
    pop <- paste(
      "<b>Id do crime:</b>", data_$id, "<br>",
      "<b>Policial encarregado:</b>", data_$policial_encarregado, "<br>",
      "<b>Data ocorrência:</b>", data_$data, "<br>",
      "<b>Descrição da ocorrência:</b>", na.omit(data_$descrição), "<br>",
      "<b>Situação:</b>", data_$situação, "<br>"
    )
    
    
    leafletProxy("without_class_map") %>% clearMarkers() %>% clearShapes() %>% clearControls() %>%
      addCircleMarkers( lng = data_$longitude, lat =  data_$latitude,
                        fillColor = pal(class), popup= pop,
                        stroke = FALSE, fillOpacity = 0.8,
                        group = tolower(class), options = pathOptions(pane = "crimes")
      )%>%
      addCircleMarkers(lng = ct$longitude, lat =  ct$latitude,
                       stroke = TRUE, color = 'black', opacity = 0.8,
                       fillOpacity = 1, radius = 13, fillColor = pal(ct$cluster),
                       label= paste("Centro dos casos do cluster",ct$cluster),
                       group = sort(crimes), options = pathOptions(pane = "centroids")

      )%>%
      addLayersControl(overlayGroups = crimes, position = "topright",
                       options = layersControlOptions(collapsed = FALSE)) %>%
      hideGroup(crimes) %>%
      addLegend("bottomright", pal = pal, values = class,
                title = "Cluster",
                opacity = 1
      )
  })
  
  
  
  # Movable graph on the left showing the amount of cases per "tipo_de_crime" or kmeans$size
  output$qnt_de_casos <- renderHighchart({
    data <- myData()

    if(!is.null(data) && all(seg_col_names %in% colnames(data))){
      
      if("tipo_de_crime" %notin% colnames(data)){
        km<-k_means() 
        
        if(is.null(km)){return(NULL)}
        
        dt<-data.table::as.data.table(km$size, .keep.rownames = "word")
        dt<-cbind(as.data.frame(rownames(dt)), dt)
        colnames(dt)<- c("group", "n")
        
      }else{
        dt <- data %>%
          count(tipo_de_crime) %>%
          arrange(n)
        
        colnames(dt)<- c("group", "n")
      }
      

      
      hchart(dt, "bar", hcaes(group, n)) %>%
        hc_colors("SteelBlue") %>%
        hc_title(text ="Quantidade de crimes por grupo") %>%
        hc_xAxis(title = list(text = ""), gridLineWidth = 0, minorGridLineWidth = 0) %>%
        hc_yAxis(title = list(text = "Incidentes"), gridLineWidth = 0, minorGridLineWidth = 0) %>%
        hc_tooltip(pointFormat = "Incidentes: <b>{point.y}</b>") %>%
        hc_add_theme(hc_theme_smpl()) %>%
        hc_legend(enabled = F) %>%
        hc_chart(backgroundColor = "transparent")
    }
    
  })

  
  
}

# Run the application 
shinyApp(ui = ui, server = server)
