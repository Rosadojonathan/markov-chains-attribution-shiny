library(shiny) # il faut charger le package au début de chacun des scripts

shinyUI( pageWithSidebar( # mise en page shiny standard : éléments de contrôle à gauche et sorties à droite
  
  headerPanel("Markov Chains"), # titre de l'appli
  
  sidebarPanel( # cette partie va contenir tous les éléments de contrôle de l'UI
    
    selectInput("platform","Plateforme:",
                c("Next Concert"="176259709",
                  "Live Booker"="176165263"),
                selected = "Live Booker"),
    
    sliderInput(inputId = "conversion_threshold", # nom associé à cet élément de contrôle, sera utilisé dans la partie 'server'
              label = "Seuil de conversions graphées :", # libellé associé à cet élément de contrôle
              min = 1,
              max=150,
              value = 20), # valeur par défaut
    
      dateRangeInput("dateRange",label="A partir du / jusqu'à: ", start = as.character(Sys.Date() -31), end = as.character(Sys.Date() -1))
  ),
 
  
  mainPanel( # cette partie va contenir les sorties
    
    h4("GA View ID: ", textOutput("platform")), # titre donné à la partie présentant les sorties, l'élément h3 correspond à une balise "<h3>" en html, ie. le titre sera mis en valeur
    plotOutput("markov_plots")

  )
  
))