#### Global data ----

results <- reactiveValues()

# Upload last version of the database
results$database.rds <- readRDS(file = "../www/database.rds")

#build up path to password for windows
#credential_label <- "email_pwd"
#credential_path <- paste(Sys.getenv("USERPROFILE"), '\\DPAPI\\passwords\\', Sys.info()["nodename"], '\\', credential_label, '.txt', sep="")

# setup email sender
results$smtp <- emayili::server(
                              host = "mail.gandi.net",
                              port = 465,
                              username = "contact@virginie-mournetas.fr",
                              password = keyring::key_get("MY_SECRET") # for windows: decrypt_dpapi_pw(credential_path)
                            )

# update leaflet map according to the database
map <- reactive({
  
  map <- leaflet() %>% 
    addTiles() %>%
    addAwesomeMarkers(layerId = results$database.rds$ID, results$database.rds$long, results$database.rds$lat, 
                      icon=awesomeIcons(icon = 'ios-close', library = 'ion', markerColor = results$database.rds$color), 
                      label = results$database.rds$group, group = results$database.rds$group, 
                      popup = paste(tags$b("Adresse :"), results$database.rds$address,"<br/>",
                                    tags$b("Filtre :"), results$database.rds$group,"<br/>",
                                    tags$b("Description :"), results$database.rds$description,"<br/>",
                                    tags$b("Date de creation :"), format(results$database.rds$date_creation, format = "%d-%m-%Y"),"<br/>",
                                    tags$b("Date de derniere interaction :"), format(results$database.rds$date_interaction, format = "%d-%m-%Y"),"<br/>",
                                    f7Icon("hand_thumbsup_fill"), " :", results$database.rds$like,
                                    "<button onclick='Shiny.onInputChange(\"plusplus\",  Math.random())' id='plusplus' type='button' class='btn btn-default action-button'>PLUS</button>",
                                    "<br/>",
                                    "</br><button onclick='Shiny.onInputChange(\"go_modification\",  Math.random())' id='go_modification' type='button' class='btn btn-default action-button'>Plus d'options</button>")
                      ) %>%
    leaflet.extras::addSearchOSM(options = searchOptions(collapsed = TRUE)) %>% # Add the control widget
    addLayersControl(overlayGroups = filtres$names, options = layersControlOptions(collapsed = TRUE)) %>% # Add default OpenStreetMap map tiles
    addControlGPS(options = gpsOptions(position = "topleft", activate = TRUE, 
                                       autoCenter = TRUE, maxZoom = 10, 
                                       setView = TRUE)) %>%
    setView(lng=5.727534, lat=45.19101, zoom = 12) # zoom to Grenoble
  
  map
  
  
  
})

output$mymap <- renderLeaflet({
  map()
})



#### Add a new POI ----

# popup on creation click
observeEvent(input$go_creation, {
  
  #reset for next creation
  results$PointData <- NULL
  
  shinyjs::enable("go_create")
  
  updateF7Popup(id = "popup_create")
  
})

# add the address related to the GPS location when location button is clicked
observeEvent(input$gps, {
  updateF7Text("adresse", value = tidygeocoder::reverse_geo(input$lat, input$long)[[3]])
})


# render the uploaded image
output$dataImageUI <- renderUI({
  
  req(input$Image)
  
  imageOutput("dataImage")
  
})

observeEvent(input$Image, {
  
  req(input$Image)

  output$dataImage <- renderImage({
    
    width  <- session$clientData$output_dataImage_width
    height <- session$clientData$output_dataImage_height
    
    outfile <- input$Image$datapath
    
    # Return a list containing the filename
    list(src = outfile, width = width/3, height = height/3)
    
  }, deleteFile = FALSE)

})


# Triggered events on creation button click
observeEvent(input$go_create, {
  
  req(input$go_creation)

  if(!is.null(input$Image) & is.null(results$PointData)){
    results$image <- "YES"
  }else{
    results$image <- "NO"
  }
  
  if(input$adresse != "" & input$description != ""){
    
    #gather new point information together
    results$PointData <- data.frame(
      ID = max(results$database.rds$ID) + 1,
      date_creation = Sys.time(),
      like = 1,
      remove = 0,
      date_interaction = NA,
      image = results$image,
      email = c(input$email_creation),
      address = input$adresse,
      group = input$filtre,
      description = input$description) %>%
      tidygeocoder::geocode(address = address)
    
    results$PointData$date_interaction <- as.POSIXct(results$PointData$date_interaction)
    
    results$PointData$color <- filtres$colors[filtres$names == input$filtre]
    
    #create a new line in the database 
    results$database.rds <- as.data.frame(rbind(results$database.rds, results$PointData))
    
    #save the updated database 
    saveRDS(results$database.rds, file = "../www/database.rds")
    
    #save the image
    if(results$image == "YES"){
      fileName <- paste0(results$PointData$ID,".jpg")
      file.copy(input$Image$datapath, file.path("./www", fileName))
    }
    
    if(is.null(results$id_used)){
      results$id_used <- c(results$PointData$ID)
    }else{
      results$id_used <- c(results$id_used, results$PointData$ID)
    }
    
    #send an email for creating the point if email is given
    if(input$email_creation != ""){
      email <- envelope()
      email <- email %>% subject("B.i.P.A. Suivi de point")
      email <- email %>% text("Vous recevez cet email car vous voulez suivre le point que vous venez de creer. Vous pouvez vous desabonner à tout moment via l'application B.i.P.A.")
      
      email <- email %>%
        from("contact@virginie-mournetas.fr") %>%
        to(input$email_creation)
      
      results$smtp(email, verbose = TRUE)
    }
    
    shinyjs::disable("go_create") #to use only once
    
  }else if(input$adresse == "" & input$description != ""){
    output$erreur_creation <- renderUI({
      f7Block(inset = TRUE, "Veuillez entrer une adresse ou vous geolocaliser.")
    })
  }else if(input$description == "" & input$adresse != ""){
    output$erreur_creation <- renderUI({
      f7Block(inset = TRUE, "Veuillez entrer une description.")
    })
  }else if(input$description == "" & input$adresse == ""){
    output$erreur_creation <- renderUI({
      f7Block(inset = TRUE, "Veuillez entrer une adresse (ou vous geolocaliser), ainsi qu'une description.")
    })
  }
  
  shinyjs::runjs("history.go(0)") #to reset inputs for next point creation
  
})



#### Modify an existing POI ----

#champs obligatoire
observe({
  validateF7Input(inputId = "description", error = "Veuillez ajouter une description")
  validateF7Input(inputId = "adresse", error =  "Veuillez entrer une adresse ou vous geolocaliser")
})

#Open a popup on map click
observeEvent(input$go_modification, {
  
  #to use buttons only once
  if(input$mymap_marker_click$id %in% results$id_used){
    shinyjs::disable("plussoyer") 
    shinyjs::disable("Poubelle") 
    shinyjs::disable("go_modify")
  }else{
    shinyjs::enable("plussoyer")
    shinyjs::enable("Poubelle")
    shinyjs::enable("go_modify")
  }
  
  
  ID <- input$mymap_marker_click$id
  
  output$dataText_savedUI <- renderUI({
    f7Card(f7Col(
      f7Block(inset = TRUE, tags$b("Adresse :"), results$database.rds$address[ID]),
      f7Block(inset = TRUE, tags$b("Filtre :"), results$database.rds$group[ID]),
      f7Block(inset = TRUE, tags$b("Description :"), results$database.rds$description[ID]),
      f7Block(inset = TRUE, tags$b("Date de creation :"), format(results$database.rds$date_creation[ID], format = "%d-%m-%Y")),
      f7Block(inset = TRUE, tags$b("Date de dernire interaction :"), format(results$database.rds$date_interaction[ID], format = "%d-%m-%Y"))
      ))
  })
  
  # Do thinks if the image exists
  if(file.exists(image()) == TRUE){
    
    output$dataImage_savedUI <- renderUI({
      f7Card(imageOutput("dataImage_saved"))
    })
      
    output$dataImage_saved <- renderImage({
      
      # Return a list containing the filename
      list(src = image(), height="150")
      
    }, deleteFile = FALSE)
    
  }else{
    output$dataImage_savedUI <- renderUI({
    })
  }

  updateF7Popup(id = "popup_modify")
})

image <- reactive({
  # file path for image
  file.path("../www", paste0(input$mymap_marker_click$id,".jpg"))
})

#Save the number of like from the clicked point
likes <- reactive({
  likes <- results$database.rds[results$database.rds$ID == input$mymap_marker_click$id, ]$like
  likes
})

#Render the number of like from the clicked point
output$likes <- renderUI({
  f7Chip(label = paste("Actuellement", likes()), icon = f7Icon("hand_thumbsup_fill"), iconStatus = "blue")
})

#Save the number of remove from the clicked point
remove <- reactive({
  remove <- results$database.rds[results$database.rds$remove == input$mymap_marker_click$id, ]$remove
  remove
})

#Save the number of like from the clicked point
emailAdresses <- reactive({
  
  if(input$email_modification != "" | !is.null(input$plusplus)){
    emailAdresses <- c(unlist(results$database.rds$email[results$database.rds$ID == input$mymap_marker_click$id]), input$email_modification)
    emailAdresses <- unique(emailAdresses)
    results$database.rds$email[results$database.rds$ID == input$mymap_marker_click$id] <- list(c(emailAdresses))
  }else{
    emailAdresses <- unlist(results$database.rds$email[results$database.rds$ID == input$mymap_marker_click$id])
  }
  
  emailAdresses
  
})
 
#update the number of likes 
observeEvent(input$plusplus, {
  
  if(input$mymap_marker_click$id %in% results$id_used){
    shinyjs::disable("plusplus") 
  }else{
    shinyjs::enable("plusplus") #to use only once
    
    if(is.null(results$id_used)){
      results$id_used <- c(input$mymap_marker_click$id)
    }else{
      results$id_used <- c(results$id_used, input$mymap_marker_click$id)
    }
    
    results$database.rds[results$database.rds$ID == input$mymap_marker_click$id, ]$like <- likes() + 1
    
    results$database.rds[results$database.rds$ID == input$mymap_marker_click$id, ]$date_interaction <- Sys.time()
    
    #Save the updated database
    saveRDS(results$database.rds, file = "../www/database.rds")
    
    email <- envelope()
    email <- email %>% subject("B.i.P.A. Suivi de point")
    email <- email %>% text("Vous recevez cet email car vous voulez suivre le point. Il y a un like de plus pour ce point. Vous pouvez vous desabonner via l'application B.i.P.A.")
    
    req(emailAdresses())
    
    #send an email for modifying the point if email is given 
    for (mailAddress in emailAdresses()){
      if(mailAddress != ""){
        email <- email %>%
          from("contact@virginie-mournetas.fr") %>%
          bcc(mailAddress)
      }
    }
    results$smtp(email, verbose = TRUE)
    
  }
  
})

#update the number of likes 
observeEvent(input$plussoyer, {
  
    if(is.null(results$id_used)){
      results$id_used <- c(input$mymap_marker_click$id)
    }else{
      results$id_used <- c(results$id_used, input$mymap_marker_click$id)
    }
    results$database.rds[results$database.rds$ID == input$mymap_marker_click$id, ]$like <- likes() + 1
    
    results$database.rds[results$database.rds$ID == input$mymap_marker_click$id, ]$date_interaction <- Sys.time()
    
    shinyjs::disable("plussoyer") #to use only once
  
})

#update the number of remove demand 
observeEvent(input$Poubelle, {
    
    if(is.null(results$id_used)){
      results$id_used <- c(input$mymap_marker_click$id)
    }else{
      results$id_used <- c(results$id_used, input$mymap_marker_click$id)
    }
    
    results$database.rds[results$database.rds$remove == input$mymap_marker_click$id, ]$remove <- remove() + 1
    
    #Save the updated database
    saveRDS(results$database.rds, file = "../www/database.rds")
    
    output$Poubelle_message <- renderUI({
      #to use buttons only once
      if(input$mymap_marker_click$id %in% results$id_used){
        f7Card(f7Block(inset = TRUE, "Votre demande de suppression sera prise en compte apres avoir cliquez sur 'Modifier le point'."))
      }
    })
    
    results$database.rds[results$database.rds$ID == input$mymap_marker_click$id, ]$date_interaction <- Sys.time()
    
    shinyjs::disable("Poubelle") #to use only once
  
})


 
# Triggered events on modification button click
observeEvent(input$go_modify, {
  
  
  if(input$mymap_marker_click$id %in% results$id_used){
    shinyjs::disable("go_modify") #to use only once
  }else{
    shinyjs::enable("go_modify") #to use only once
    #Save the updated database
    saveRDS(results$database.rds, file = "../www/database.rds")
    
    if(is.null(results$id_used)){
      results$id_used <- c(input$mymap_marker_click$id)
    }else{
      results$id_used <- c(results$id_used, input$mymap_marker_click$id)
    }
    
    email <- envelope()
    email <- email %>% subject("B.i.P.A. Suivi de point")
    email <- email %>% text("Vous recevez cet email car vous voulez suivre le point. Il y a un like de plus pour ce point. Vous pouvez vous desabonner via l'application B.i.P.A.")
    
    req(emailAdresses())
    
    #send an email for modifying the point if email is given 
    for (mailAddress in emailAdresses()){
      if(mailAddress != ""){
        email <- email %>%
          from("contact@virginie-mournetas.fr") %>%
          bcc(mailAddress)
      }
    }
    results$smtp(email, verbose = TRUE)
    
    shinyjs::runjs("history.go(0)") #to reset inputs for next point creation
    
    shinyjs::disable("go_modify") #to use only once
  }
  
 
  
})


#### Remove emails ----

observeEvent(input$go_removeEmail,{
  f7Dialog(
    id = "removeEmail",
    title = "Se desabonner",
    type = "prompt",
    text = "Entrez votre email"
  )
})

observeEvent(input$removeEmail, {
  
  results$database.rds$email <- str_remove_all(results$database.rds$email, input$removeEmail)
  
  #save the updated database 
  saveRDS(results$database.rds, file = "../www/database.rds")
  
})
