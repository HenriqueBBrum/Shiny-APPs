# Interface do usuário


source('ui_map.R', local = TRUE, encoding="utf-8")
source('ui_no_map.R', local = TRUE, encoding="utf-8")

ui <- fluidPage(
  theme = shinythemes::shinytheme("united"),
  
  titlePanel("Saúde Pública"),
  
  navbarPage("", map_tab, no_map_tab)
             
)