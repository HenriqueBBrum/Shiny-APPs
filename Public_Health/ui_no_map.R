# Página que seria para edição dos dados e para contatar os pacientes 



no_map_tab <- tabPanel("Página para editar dados e contactar pacientes (não feita)", 
                       sidebarLayout(sidebarPanel(helpText("Descrição de como usar esse APP")), 
                                     mainPanel(tabsetPanel(
                                                tabPanel("Editar", DT::dataTableOutput("table_2")), 
                                                           
                                                tabPanel("Contatar paciente", )
                                                
                                                
                                                ))
                                     ),
                       )