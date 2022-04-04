requiredLib <- c(
  "shiny",
  "DT",
  "dplyr",
  "shinydashboard",
  "shinydashboardPlus"
) 
for (lib in requiredLib) {
  if (!require(lib, character.only = TRUE)) {
    install.packages(lib,repos = "http://cran.us.r-project.org")
  }
  require(lib, character.only = TRUE)
}



# Upload last version of the database
database.rds <- readRDS(file = "../www/database.rds")


ui <- dashboardPage(
  
  dashboardHeader(title = NULL), 

  dashboardSidebar(disable = TRUE),
  
  dashboardBody(
    h1("B.I.P.A dashboards"),
    br(),
    dataTableOutput("database"),
    br(),
    p("* les adresses emails ont ete enleves de la base de donnees")
    )
  
  )

# Define server logic required to draw a histogram ----
server <- function(input, output) {
  
  output$database <- renderDataTable({
    
    database.rds <- database.rds %>%
      dplyr::select(-email)
    
    DT::datatable(
      database.rds , 
      escape = FALSE, #for HTML input
      filter = 'top', 
      style = "default",
      class = 'cell-border stripe' , 
      extensions = c('Scroller','Buttons'), 
      options = list(
        dom = 'Blfrtip', #for buttons
        buttons = 
          list('copy', 'print', list(
            extend = 'collection',
            buttons = c('csv', 'excel', 'pdf'),
            text = 'Download'
          )),
        deferRender = TRUE, #with 'Scroller'
        scrollY = 250,#with 'Scroller'
        scroller = TRUE ,#with 'Scroller'
        autoWidth = FALSE,
        scrollX = TRUE ,
        lengthMenu = list(c(10 , 50 , -1) , c('10' , '50' , 'All')) ,
        columnDefs = list(
          list(className = 'dt-center', targets = c(0:length(database.rds[1, ])) #Center columns
          ) 
        )
      )
    )%>%
      DT::formatStyle(columns = c(0:length(database.rds[1, ])), fontSize = '80%') #change text size 
    
    
    })
  
  
}

shinyApp(ui, server)
