server <- function(input, output, session) {
  
  # Popup de démarrage
  toggleModal(session, "avertissement", toggle = "open")
  
  
  # Adaptation du menu commune en fonction du département sélectionné
  codeDep = reactive({
    nomDepartement = input$nomDepartement
    nomDepartement = ifelse(nomDepartement %in% departements$NCC, nomDepartement, "AIN")
    codeDep = departements$DEP[departements$NCC == nomDepartement]
    return(codeDep)
    }
  )
  
  # Update inutile mais nécessaire pour avoir un espace vertical analogue entre
  choix_departement = observe({
    updateSelectizeInput(session, 'nomDepartement', 
                         choices = unique(departements$NCC),
                         server = FALSE)
  })
  
  choix_commune = observe({
    # Pour éviter qu'un calcul soit lancé avec un couple (département, commune) incohérent
    freezeReactiveValue(input, 'nomCommune')
    
    updateSelectizeInput(session, 'nomCommune', 
                         choices = donnees$NomCom[donnees$CodeDep == codeDep()],
                         server = FALSE)
  })
  
  
  codeCom = reactive({
    nomCommune = input$nomCommune
    codeDep = codeDep()
    
    nomCommune = ifelse(nomCommune %in% donnees$NomCom[donnees$CodeDep == codeDep], 
                        nomCommune,  donnees$NomCom[donnees$CodeDep == codeDep][1])
    
    codeCom = donnees$CodeCom[donnees$CodeDep == codeDep & donnees$NomCom == nomCommune]
    return(codeCom)
  })
  
  donneesCom = reactive({
    donneesCom = subset(donnees, CodeCom == codeCom())
    return(donneesCom)
  })
  
  # Menu pour changer la population ------------------------------
  # Par défaut, fixée à la population 2018
  
  fourchette_population = observe({
    PopDGF2018 = donneesCom()$PopDGF2018
    maxPopDGF2018 = round(2*PopDGF2018*1.5,-nchar(PopDGF2018)+1)

    updateSliderInput(session, "population2019",
                      max = maxPopDGF2018, 
                      value = PopDGF2018)
  })

  # Lien entre les deux champs de population
  champ_population = observeEvent(input$population2019,{
    updateNumericInput(session, 
                       "population2019bis", 
                       value = input$population2019)
  })
  
  curseur_population = observeEvent(input$population2019bis,{
    PopDGF2018 = donneesCom()$PopDGF2018
    maxPopDGF = max(round(2*PopDGF2018*1.5,-nchar(PopDGF2018)+1), input$population2019bis)

    updateSliderInput(session, "population2019", 
                      max = maxPopDGF,
                      value = input$population2019bis)
  })

#######################################
# Boite d'information commune nouvelle
  output$telechargerNotice <- downloadHandler(
    filename = "notice_dotation_forfaitaire_2019.pdf",
    content = function(file) {
      file.copy("www/notice_dotation_forfaitaire_2019.pdf", file)
    }
  )
#######################################
  # Boite d'information commune nouvelle
  
  output$communeNouvelle <- reactive({
    calcul()[['ComNouvelle']]
  })
  outputOptions(output, "communeNouvelle", suspendWhenHidden = FALSE)
  
  output$infoCommuneNouvelle <- renderText({
    annee = calcul()[['annee']]
    anneeCreation = donneesCom()$AnneeCreationCom
    comNouvelle = calcul()[['ComNouvelle']]

    explication = NA
    if (comNouvelle){
      explication = sprintf("Votre commune est une commune nouvelle créée entre le 02/01/%s et le 01/01/%s et
      éligible à la garantie de non-baisse. Elle est donc exonérée de l'écrêtement en %s,
      et sa part dynamique de la population sera prise en compte seulement si elle est positive.",
                                anneeCreation, anneeCreation +1, annee)
    }
    print(explication)
    return(explication)
  })
  
#######################################
  calcul = reactive({
    donneesCom = donneesCom()
    PopDGFnew = input$population2019
    DFestimation = calculDF(annee = 2019, 
                           AnneeCreationCom = donneesCom$AnneeCreationCom, 
                           PopDGFnmoins1 = donneesCom$PopDGF2018, 
                           PopDGFn = PopDGFnew, 
                           DFnmoins1 = donneesCom$DF2018, 
                           PF4Taxesnmoins1 = donneesCom$PF4Taxes2018, 
                           RRFn = donneesCom$RRF2018, # Pas d'autre valeur
                           valeurPopn = valeurPop2019, 
                           valeurPointn = valeurPoint2019, 
                           pfParHabNationalnmoins1 = pfParHabNational2018
    )
      
    return(DFestimation)
  })

  
  output$DF2016 <- renderValueBox({
    valeur = paste(format(donneesCom()$DF2016, big.mark=" ", scientific=FALSE, trim=TRUE), "€")
    valueBox(valeur, "Dotation forfaitaire 2016", valeur, icon = icon("coins"), color = 'light-blue')
  })
  output$DF2017 <- renderValueBox({
    valeur = paste(format(donneesCom()$DF2017, big.mark=" ", scientific=FALSE, trim=TRUE), "€")
    valueBox(valeur, "Dotation forfaitaire 2017", icon = icon("coins"), color = 'light-blue')
  })
  output$DF2018 <- renderValueBox({
    valeur = paste(format(donneesCom()$DF2018, big.mark=" ", scientific=FALSE, trim=TRUE), "€")
    valueBox(valeur, "Dotation forfaitaire 2018", icon = icon("coins"), color = 'light-blue')
  })
  
  output$DF2019 <- renderValueBox({
    DFestimation = calcul()[['DFn']]

    valeur = paste(format(DFestimation, big.mark=" ", scientific=FALSE, trim=TRUE), "€")
    valueBox(valeur, "Estimation 2019", icon = icon("coins"), color = "navy")
  })
  
  ## Affichage des détails
  output$detailValeurDFanterieure <- renderText({
    valeur = paste(format(donneesCom()$DF2018, big.mark=" ", scientific=FALSE, trim=TRUE), "€")
    return(valeur)
  })
  
  output$detailValeurPartPop <- renderText({
    valeur = calcul()[['PartDynPop']]
    valeur = paste(format(valeur, big.mark=" ", scientific=FALSE, trim=TRUE), "€")
    valeur = ifelse(grepl('^-', valeur), gsub('^-(.*)$', '- \\1', valeur), paste('+', valeur))
    return(valeur)
  })
  
  output$detailDeltaPop <- renderText({
    valeur = calcul()[['DeltaPop']]
    
    phrase = sprintf("Cette composante traduit l'évolution de la population.
                     Par rapport à l'an passé, votre commune a %s %s habitants",
                     ifelse(valeur>0, "gagné", "perdu"), abs(valeur)) 
    phrase = ifelse(valeur == 0, "La population de votre commune n'a pas changé depuis l'an passé.", phrase)
    return(phrase)
  })
  
  output$detailValeurEcretement <- renderText({
    valeur = calcul()[['MtEcretement']]
    valeur = paste(format(valeur, big.mark=" ", scientific=FALSE, trim=TRUE), "€")
    valeur =paste('-', valeur)
    return(valeur)
  })
  
}
