# Interface do usuário da página principal onde são vistos os dados tanto de forma textual quanto em um mapa


map_tab <- tabPanel("Visualição de Casos", navlistPanel(
      tabPanel("Arquivo",
                 sidebarLayout(
                   sidebarPanel(
                     fileInput("file", "Escolha um arquivo CSV",
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
                     helpText("O arquivo csv deve conter como primeira coluna 'id_paciente' e segunda 'nome_paciente', obrigatoriamente"),
                     helpText("As outras colunas podem estar em qualquer ordem mas devem ter os seguintes nomes: 'data',
                               'latitude', 'longitude', 'bairro', 'doença', 'condição' e 'sintomas'")
                     
                    ),
                   
                   mainPanel(DT::dataTableOutput("contents"))
                   
                 )),
                
      tabPanel("Mapa",leafletOutput("mymap", height = 800)),
      
      tabPanel("Casos Individuais", 
               sidebarLayout(
                 sidebarPanel(
                   conditionalPanel(condition =  "output.fileUploaded == true", 
                                    uiOutput("elements_1"),
                                    uiOutput("elements_2")
                   )),
                 mainPanel(
                   conditionalPanel(condition =  "output.fileUploaded == false",
                                    helpText("Esta aba serve para pesquisar por indivíduos específicos")),
                   conditionalPanel(condition =  "output.fileUploaded == true",
                                    h2("Relatório de paciente", style="color:black;font-family:verdana"),
                                    uiOutput("text"))
                   
                 )
               )),
      widths = c(2, 10)))
