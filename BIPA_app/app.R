requiredLib <- c(
  "shiny",
  "shinyMobile",
  "shinyjs",
  "dplyr",
  "stringr", #str_remove_all function
  "leaflet", #map
  "leaflet.extras", #map
  "sf", #map
  "tidygeocoder", #map
  "emayili", #emails
  "keyringr", #mdp for windows
  "keyring" #mdp for ubuntu
) 
for (lib in requiredLib) {
  if (!require(lib, character.only = TRUE)) {
    install.packages(lib,repos = "http://cran.us.r-project.org")
  }
  require(lib, character.only = TRUE)
}


`%notin%` <- Negate(`%in%`)

filtres <- data.frame(names = c("Dechets",
                                "Depot sauvage", 
                                "Eau potable",
                                "Eau usee",
                                "Eclairage",
                                "Espaces verts",
                                "Graffitis/Tags",
                                "Nettoyage",
                                "Vehicule velo",
                                "Voirie",
                                "Autre"),
                      colors = c("red",
                                 "green",
                                 "blue",
                                 "pink",
                                 "black",
                                 "orange",
                                 "purple",
                                 "deeppurple",
                                 "lightblue",
                                 "black",
                                 "lime"))

shinyApp(ui = f7Page(title = "BIPA", 
                     tags$script('
                                    $(document).ready(function () {
                                      navigator.geolocation.getCurrentPosition(onSuccess, onError);
                              
                                      function onError (err) {
                                        Shiny.onInputChange("geolocation", false);
                                      }
                              
                                      function onSuccess (position) {
                                        setTimeout(function () {
                                          var coords = position.coords;
                                          console.log(coords.latitude + ", " + coords.longitude);
                                          Shiny.onInputChange("geolocation", true);
                                          Shiny.onInputChange("lat", coords.latitude);
                                          Shiny.onInputChange("long", coords.longitude);
                                        }, 1100)
                                      }
                                    });
                                    '),
                  source("BIPA_ui.R", local = TRUE)$value), 
         server = function(input, output, session) {source("BIPA_server.R", local = TRUE)})


#runGitHub("BIPA", "VirginieMournetas")
