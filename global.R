library(stringr)
library(shiny)
library(shinyBS) # Additional Bootstrap Controls
library(stringr)
library(shinydashboard)
library(shinyjs)

options(digits = 15, scipen = 999)

departements = read.csv("depts2016.txt", stringsAsFactors = F, sep = '\t', fill = TRUE, header = T)
donnees = read.csv2("donnees_app.csv", header = T, stringsAsFactors = FALSE)

donnees$NomCom = paste(donnees$CodeCom, '-', donnees$NomCom)

bsModalFrench = function (id, title, trigger, ..., size) 
{
  if (!missing(size)) {
    if (size == "large") {
      size = "modal-lg"
    }
    else if (size == "small") {
      size = "modal-sm"
    }
    size <- paste("modal-dialog", size)
  }
  else {
    size <- "modal-dialog"
  }
  bsTag <- shiny::tags$div(class = "modal sbs-modal fade", 
                           id = id, tabindex = "-1", `data-sbs-trigger` = trigger, 
                           shiny::tags$div(class = size, shiny::tags$div(class = "modal-content", 
                                                                         shiny::tags$div(class = "modal-header", shiny::tags$button(type = "button", 
                                                                                                                                    class = "close", `data-dismiss` = "modal", 
                                                                                                                                    shiny::tags$span(shiny::HTML("&times;"))), 
                                                                                         shiny::tags$h4(class = "modal-title", title)), 
                                                                         shiny::tags$div(class = "modal-body", list(...)), 
                                                                         shiny::tags$div(class = "modal-footer", shiny::tags$button(type = "button", 
                                                                                                                                    class = "btn btn-default", `data-dismiss` = "modal", 
                                                                                                                                   "J'ai compris")))))
  return(bsTag)
  #htmltools::attachDependencies(bsTag, shinyBSDep)
}


## Fonctions ----------------------------------------------------------------
# Arrondi 0,5 --> 1 comme dans excel
round2 = function(x, n) {
  posneg = sign(x)
  z = abs(x)*10^n          
  z = z + 0.5
  z = trunc(z)
  z = z/10^n
  z*posneg
}

# Coeff Population logarithmee
calculCoeffPop = function(pop){
  a = ifelse(pop <= 500, 1, 
             ifelse(pop >= 200000, 2,
                    1 + log(pop/500)/log(200000/500)
                    )
             )
  return(a)
}

##########################################################
# pfParHabNational2017 = 624.197452

# Constantes 2018
valeurPop2018 = 64.4629119722368
valeurPoint2018 = 7.2662803
# masseTotale2018 = 160051335

# Utiliser http://lpsolve.sourceforge.net/5.5/R.htm pour déterminer vp

valeurPop2019 = 64.4629119722368
valeurPoint2019 = 8.6702415130632
# masseTotale2019 = 184800000

# calculValeurPoint = function(annee, masseTotale, vpDepart, donnees){
#   annee = 2018 # nmoins1 = 2018
#   # Potentiel Fiscal par habitant année n-1
#   coeffPopLog2017 = calculCoeffPop(donnees$PopDGF2017)
#   
#   
#   donnees$PopLog2017 = round2(coeffPopLog2017*donnees$PopDGF2017, 0)
#   donnees$PF4ParHab2017 = round2(donnees$PF4Taxes2017/PopLog2017, 0)
#   donnees$PF4ParHab2017[is.infinite(donnees$PF4ParHab2017)] = 0
#   
#   pfParHabNational2017 = round2(sum(donnees$PF4Taxes2017)/sum(donnees$PopLog2017[donnees$PF4Taxes2017>0]),6)
#   
#   
#   donnees$exoEcretement =  donnees$PF4ParHab2017-0.75*pfParHabNational2017 <0 | 
#     donnees$AnneeCreationCom %in% c((annee-2):annee) |         
#     (donnees$DF2017 == 0 & donnees$PartDynPop == 0)|
#     donnees$PF4Taxes2017 == 0
#   
#   
#     valeurPoint2018 = 7.2662803
#   # masseTotale2018 = 160051335
#   vp = valeurPoint2018
#   
#   donnees$PF4ParHab2017[donnees$PopDGF2017 ==0] =0
#   donnees$contibution = ifelse(donnees$exoEcretement, 0,
#                                vp*donnees$PopLog2017*(donnees$PF4ParHab2017-0.75*pfParHabNational2017))
#   donnees$contibution = ifelse(donnees$contibution > 0.01*donnees$RRF2018, 0.01*donnees$RRF2018, donnees$contibution)
#   donnees$contibution = ifelse(donnees$contibution > donnees$DF2017 + donnees$PartDynPop, donnees$DF2017 + donnees$PartDynPop, donnees$contibution)
#   sum(donnees$contibution)
#                               , 
#                                     0.01*donnees$RRF2018, 
#                                     max(donnees$DF2017 + donnees$PartDynPop,0))
#   )
#                               
# 
#   vp = 
#   
# }

donnees$PopLog2017 = round2(calculCoeffPop(donnees$PopDGF2017)*donnees$PopDGF2017, 0)
donnees$PopLog2018 = round2(calculCoeffPop(donnees$PopDGF2018)*donnees$PopDGF2018, 0)

pfParHabNational2017 = round2(sum(donnees$PF4Taxes2017)/sum(donnees$PopLog2017[donnees$PF4Taxes2017>0]),6)
pfParHabNational2018 = round2(sum(donnees$PF4Taxes2018)/sum(donnees$PopLog2018[donnees$PF4Taxes2018>0]),6)


calculDF = function(annee, AnneeCreationCom, PopDGFnmoins1, PopDGFn, 
                    DFnmoins1, PF4Taxesnmoins1, RRFn,
                    valeurPopn, valeurPointn, pfParHabNationalnmoins1){
  
  # Calcul de la part dynamique de la population
  coeffPopLognmoins1 = calculCoeffPop(PopDGFnmoins1)
  coeffPopLogn = calculCoeffPop(PopDGFn)
  
  PartDynPop = round2(valeurPopn*(PopDGFn - PopDGFnmoins1)*coeffPopLogn,0)
  PartDynPop = pmax(-DFnmoins1, PartDynPop)
  PartDynPop = ifelse(AnneeCreationCom %in% c((annee-2):annee), pmax(PartDynPop,0), PartDynPop)
  
  
  # Potentiel Fiscal par habitant année n-1
  PopLognmoins1 = round2(coeffPopLognmoins1*PopDGFnmoins1, 0)
  PF4ParHabNmoins1 = round2(PF4Taxesnmoins1/PopLognmoins1, 0)
  PF4ParHabNmoins1[is.infinite(PF4ParHabNmoins1)] = NA
  
  # Calcul de l'écrêtement
  if ((PF4ParHabNmoins1-0.75*pfParHabNationalnmoins1) <0 |
      (AnneeCreationCom %in% c((annee-2):annee)) |
      (DFnmoins1 == 0 & PartDynPop ==0) |
      PF4Taxesnmoins1 == 0){
    MtEcretement = 0
  }else{
    MtEcretement = round2((PF4ParHabNmoins1-0.75*pfParHabNationalnmoins1)/(0.75*pfParHabNationalnmoins1),6)
    MtEcretement = valeurPointn*PopDGFn*MtEcretement
    MtEcretement = pmin(MtEcretement, 0.01*RRFn, DFnmoins1 + PartDynPop) # Plafonnement
    MtEcretement = round2(MtEcretement,0)
  }


  
                           

  # Binaire commune nouvelle
  ComNouvelle = ifelse(annee-3 <= AnneeCreationCom, T, F)
  
  # Calcul final
  DFn = DFnmoins1 + PartDynPop - MtEcretement
  return(list(DFn = DFn, 
              DFnmoins1 = DFnmoins1,
              DeltaPop = PopDGFn - PopDGFnmoins1,
              PartDynPop = PartDynPop,
              MtEcretement = MtEcretement,
              CoeffPop = coeffPopLogn,
              valeurPopn = valeurPopn,
              ComNouvelle = ComNouvelle,
              annee = annee
              ))
  
}

donneesCom = donnees[1,]
test = calculDF(annee = 2019,
                AnneeCreationCom = donneesCom$AnneeCreationCom,
                PopDGFnmoins1 = donneesCom$PopDGF2017,
                PopDGFn = 170,
                DFnmoins1 = donneesCom$DF2017,
                PF4Taxesnmoins1 = donneesCom$PF4Taxes2017,
                RRFn = donneesCom$RRF2018,
                valeurPopn = valeurPop2018,
                valeurPointn = valeurPoint2018,
                pfParHabNationalnmoins1 = pfParHabNational2017
                  )

