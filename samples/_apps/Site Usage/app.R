library(shiny)
library(shinydashboard)
library(DT)

library(httr)
library(data.table)
library(magrittr)
library(ggplot2)
library(lubridate)

ui <- dashboardPage(
  header = source('ui/header.R', local = TRUE)$value,
  sidebar = source('ui/sidebar.R', local = TRUE)$value,
  body = source('ui/body.R', local = TRUE)$value
)

server <- source('server/server.R', local=TRUE)$value

shinyApp(ui, server)
