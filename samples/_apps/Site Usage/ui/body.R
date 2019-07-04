dashboardBody(tabItems(tabItem(
  tabName = 'tab_home',
  fluidRow(
    box(title = 'Users',
        width = 6,
        plotOutput('plot_users')),
    box(title = 'Apps',
        width = 6,
        plotOutput('plot_apps'))
  ),
  fluidRow(box(
    title = 'Data',
    width = 12,
    DT::dataTableOutput('datatable')
  ))
)))