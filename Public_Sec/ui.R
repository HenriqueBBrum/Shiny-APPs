# User interface

ui <- fluidPage(
  theme = shinythemes::shinytheme("united"),
  
  titlePanel("Segurança Pública"),
  # UI for two panels: "Arquivo", contains inputs to help upload a csv file according to its configurations; 
  #                    "Mapa", map and  a chart, also a input for the amount of centers for k-means algorithm.
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
                     
                     
                     
                     
                      helpText(p("O arquivo csv deve conter como primeira coluna 'id'."),
                               p("As outras colunas podem estar em qualquer ordem mas devem ter os seguintes nomes: 'data',
                                   'latitude', 'longitude', 'policial_encarregado', 'tipo_de_crime', 'situação', 'descrição' e 'situação'"),
                              p("Obs: 'tipo_de_crime' é necessário para dados que possuem uma classificação, outros nomes não são aceitos."))
                     
                   ),
                   
                   mainPanel(DT::dataTableOutput("contents"))
                   
             )),
    
    tabPanel("Mapa", conditionalPanel("output.has_no_class==0",leafletOutput("with_class_map", height = 800), 
                                      h5(strong("**Dados não usam um campo de classificação**"))),
                     conditionalPanel("output.has_no_class==1", leafletOutput("without_class_map", height = 800),
                                      h5(strong("**Dados usam um campo de classificação**"))),
                     absolutePanel(
                       top = 250, left = 30, draggable = TRUE, width = "15%", style = "z-index:500; min-width: 250px;",
                       highchartOutput("qnt_de_casos"), 
                       conditionalPanel("output.has_no_class==1",numericInput("amt_clusters", "Qnt. de clusters", value = 0 ))
                     ))

  )
)