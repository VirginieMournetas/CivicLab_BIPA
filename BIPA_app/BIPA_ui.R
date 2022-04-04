f7SingleLayout(
  
  navbar = f7Navbar(title = "B.I.P.A.", hairline = TRUE, shadow = TRUE),
  
  shinyjs::useShinyjs(),
  
  # f7Tabs(id = 'tabs', animated = TRUE, #swipeable = TRUE,
  #        
  #        f7Tab(tabName = "Carte", icon = f7Icon("map"), active = TRUE,
               
               f7Popup(id = "popup_create",
                       title = h2("Nouveau point"),
                       f7Card(h3("Choisissez un filtre *"),
                              f7Select(inputId = "filtre", label = NULL, choices = as.character(filtres$names))
                       ),
                       f7Card(h3("Geolocalisez-vous ou tapez une adresse *"),
                              f7Button(inputId = "gps", label = f7Icon("compass_fill"), fill = FALSE),
                              f7Text("adresse", label = NULL, value = "", placeholder = "Taper une adresse")
                              ),
                       f7Card(h3("Ajoutez une description *"),
                              f7TextArea(inputId = "description", label = NULL,
                                         value = NULL, placeholder = NULL,
                                         resize = TRUE)
                       ),
                       f7Card(h3("Televerser une image"),
                              f7File("Image", label = NULL),
                              uiOutput("dataImageUI")
                       ),
                       f7Card(h3("Renseignez votre email"),
                              f7Text("email_creation", label = NULL, value = "", placeholder = "Rentrer votre email pour suivre ce point")),
                       uiOutput("erreur_creation"),
                       f7Button(inputId = "go_create", label = "Creer le point", rounded = TRUE, size = "large")
               ),
               
               f7Popup(id = "popup_modify",
                       title = h2("Point existant"),
                       uiOutput("dataText_savedUI"),
                       uiOutput("dataImage_savedUI"),
                       f7Row(
                         f7Col(),f7Col(),f7Col(),
                         uiOutput("likes"),
                         f7Col(),f7Col(),f7Col()
                       ),
                       f7Card(
                         f7Row(
                           f7Col(),
                           f7Col(f7Button(inputId = "plussoyer", label = f7Icon("hand_thumbsup_fill"))),
                           f7Col(),
                           f7Col(),
                           f7Col(f7Button(inputId = "Poubelle", label = f7Icon("bin_xmark_fill"))),
                           f7Col()
                       )),
                       uiOutput("Poubelle_message"),
                       f7Card(h3("Renseignez votre email"),
                              f7Text("email_modification", label = NULL, value = "", placeholder = "Rentrer votre email pour suivre ce point")),
                       f7Button(inputId = "go_modify", label = "Modifier le point", rounded = TRUE, size = "large")
                       
               ),
  
               f7Align(f7Block(inset = TRUE, tags$b("si tu veux Agir sur un Probleme ou Informer sur ton Besoin, B.I.P.A. est la solution !")), side = "center"),
               
               f7Card(f7Button(inputId = "go_creation", label = "Creer un point")),
               
               f7Card(leafletOutput("mymap"), 
                      fullBackground = TRUE),
  
              f7Card(f7Button(inputId = "go_removeEmail", "Se desabonner de toutes les alertes")),
              f7Card(f7Col(f7Align(f7Block(inset = TRUE, "Idee originale d'Alois Arrighi - Derniere mise a jour le 04/04/2022 par Virginie Mournetas"), side = "center"),
                           f7Align(f7Block(inset = TRUE, "Apache Public License 2.0"), side = "center")))
  #        )
  # )
)