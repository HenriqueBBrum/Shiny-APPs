library(shiny)
library(leaflet)

source('ui.R', local = TRUE, encoding="utf-8")


# Lógica do programa
server <- function(input, output, session) {
  
  # Inserção dos dados pelo usuário
  
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
  
  output$fileUploaded <- reactive({
    return(!is.null(myData()))
  })
  
  outputOptions(output, 'fileUploaded', suspendWhenHidden=FALSE)
  
  
  # Mapa onde é possível escolher quais casos por doença aparecem no mapa.
  # Gravidade dos casos é representada pela coloração
  
  output$mymap <- renderLeaflet({
    
    data<- myData()

    if(is.null(data)){
      map <- leaflet() %>%
              addTiles() %>% 
              setView(lng=-53.8008, lat=-29.6914, zoom = 12)
    }else{
      groups <- tolower(as.character(unique(data$doença)))
      pal <- colorFactor(c("red", "orange", "green"), domain = c("critíca", "preucupante", "estável"))
      


      map <-leaflet(data) %>%
              addTiles() %>% 
              setView(lng=-53.8008, lat=-29.6914, zoom = 12) %>%
              addCircleMarkers(
                lng = ~ longitude, 
                lat =  ~ latitude,
                color = ~pal(condição),
                popup=paste(
                  "<b>Id:</b>", data$id_paciente, "<br>",
                  "<b>Nome:</b>", data$nome_paciente, "<br>",
                  "<b>Data:</b>", data$data, "<br>",
                  "<b>Bairro:</b>", data$bairro, "<br>",
                  "<b>Doença:</b>", data$doença, "<br>"
                ),
                stroke = FALSE, fillOpacity = 0.5,
                group = ~tolower(doença)
                
              ) %>%
              addLayersControl(overlayGroups = groups, position = "topright") %>%
              hideGroup(groups) %>%
              addLegend("bottomright", pal = pal, values = ~condição,
                        title = "Situação",
                        opacity = 1
              )
    }
    
  })
  
  
  # Tabela qua aparece na aba "Arquivo"
  
  output$contents <- DT::renderDataTable({
    df <- myData()
    
    if(input$disp == "head") {
      return(DT::datatable(head(df), width="100%", options = list(lengthChange = FALSE, scrollX = TRUE)))
    }
    else {
      return(DT::datatable(df,width="100%", options = list(lengthChange = FALSE, scrollX = TRUE)))
    }
    
  })
  
  
  # Lógica da aba "Casos Individuais" onde é possível ver os dados de um caso de forma mais organizada
  
  output$elements_1 <- renderUI({
    data <- myData()
    
    selectInput(inputId= "select_type", 
                label="Categoria para buscar um paciente", 
                choices=unique(colnames(data[,1:2])))
    
   
  })
  
  output$elements_2 <- renderUI({
    data <- myData()
    
    selectInput(inputId="select_item",
                label=input$select_type,
                choices=unique(data[, input$select_type]))
  })
  
  output$text <- renderUI({
      
      data <- myData()
      

      patient <- data[match(input$select_item, unlist(data[,input$select_type])),]

      div(
        hr(),
        h3(strong("ID: "), span(patient$id_paciente, style = "font-size:21px"), br(),
           strong("Nome paciente: "), span(patient$nome_paciente, style = "font-size:21px"), br(), 
           strong("Bairro: "), span(patient$bairro, style = "font-size:21px"),  
            style="color:black;font-family:Times New Roman"),
        br(),
        h3(strong("Doença: "), span(patient$doença, style="font-size:21px"), br(), 
           strong("Situação: "), span(patient$condição, style="font-size:21px"),  
           style="color:black;font-family:Times New Roman"),
        
        h3(strong("Sintomas: "),  style="color:black;font-family:Times New Roman"),
        wellPanel(p(patient$sintomas, style="color:black;font-size:18px;font-family:verdana")),
      )
    
    })
  
  

  
  # Tabela da aba de edição
  
  
  output$table_2 <- DT::renderDataTable({
    DT::datatable(myData(),width="100%", options = list(lengthChange = FALSE, scrollX = TRUE))
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
