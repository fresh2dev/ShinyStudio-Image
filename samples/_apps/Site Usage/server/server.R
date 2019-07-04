parse_influx_series <- function(x) {
  df <- x$values %>% lapply(unlist) %>% do.call(rbind, .) %>% data.table()
  
  setnames(df, unlist(x$columns))
  
  df[, time := ymd_hms(time)]
  
  return(df)
}

function(input, output, session) {
  df <- reactive({
    input$btn_refresh
    
    qry <- 'select * from event'
    
    resp <- httr::GET('http://influxdb:8086',
                      path='query',
                      query=list(db='shinyproxy_usagestats', q=qry))
    
    df <- httr::content(resp)$results[[1]]$series %>% 
      lapply(parse_influx_series) %>%
      rbindlist()
    
    setorder(df, -time)
    
    return(df)
  })
  
  output$plot_users <- renderPlot({
    df_users <- df()[type=='ProxyStart', .(count=.N), by='username']
    
    ggplot(df_users, aes(x=reorder(username, count), y=count)) +
      geom_bar(stat='identity', fill='#3c8dbc') +
      coord_flip() +
      xlab(NULL)
  })
  
  output$plot_apps <- renderPlot({
    df_apps <- df()[type=='ProxyStart', .(count=.N), by='data']
    
    ggplot(df_apps, aes(x=reorder(data, count), y=count)) +
      geom_bar(stat='identity', fill='#3c8dbc') +
      coord_flip() +
      xlab(NULL)
  })
  
  output$datatable <- renderDataTable({
    DT::datatable(df(), options = list(pageLength = 25, lengthMenu = c(10, 25, 50, 100), select=FALSE), filter='top')
  })
}
