dashboardSidebar(width = 150, collapsed = TRUE,
                 sidebarMenu(
                   id = 'sidebar',
                   menuItem(
                     'Home',
                     tabName = 'tab_home',
                     icon = icon('home'),
                     selected = TRUE
                   ),
                   menuItem(
                     actionButton('btn_refresh', 'Refresh', icon=icon('refresh'))
                   )
                 ))
