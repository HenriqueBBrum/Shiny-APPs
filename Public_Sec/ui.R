# User interface

ui <- fluidPage(
  theme = shinythemes::shinytheme("united"),
  
  titlePanel("Segurança Pública"),
  # UI for two panels: "Arquivo", contains inputs to help upload a csv file according to its configurations; "Mapa", map and chart.
  navbarPage("",
    tabPanel("Arquivo",
                 sidebarLayout(
                   sidebarPanel(
                     fileInput("file", "Escolha um arquivo CSV com os dados de sergurança pública",
                               multiple = FALSE,
                               accept = c("text/csv",
                                          "text/comma-separated-values,text/plain",
                                          ".csv")),
                     
                     tags$hr(),
                     
                     checkboxInput("header", "Cabeçalho", TRUE),
                     
                     radioButtons("sep", "Separador",
                                  choices = c("Vírgula" = ",",
                                              "Ponto e vírgula" = ";",
                                              Tab = "\t"),
                                  selected = ","),
                     
                     radioButtons("quote", "Aspas",
                                  choices = c(Nenhuma = "",
                                              "Aspas duplas" = '"',
                                              "Aspas Simples" = "'"),
                                  selected = '"'),
                     
                     tags$hr(),
                     
                     radioButtons("disp", "Visualização",
                                  choices = c("Início" = "head",
                                              Todo = "all"),
                                  selected = "head"),
                     
                     
                     
                     
                      helpText("O arquivo csv deve conter como primeira coluna 'id',
                                     As outras colunas podem estar em qualquer ordem mas devem ter os seguintes nomes: 'data',
                                   'latitude', 'longitude', 'policial_encarregado', 'tipo_de_crime', 'situação', 'descrição' e 'situação'")
                     
                   ),
                   
                   mainPanel(DT::dataTableOutput("contents"))
                   
             )),
    
    tabPanel("Mapa", leafletOutput("seg_map", height = 800),
                     absolutePanel(
                       top = 250, left = 30, draggable = TRUE, width = "15%", style = "z-index:500; min-width: 250px;",
                       highchartOutput("qnt_de_casos")
                     ))

  )
)