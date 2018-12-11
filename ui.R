ui <- dashboardPage(
  title="Dotation forfaitaire", # Titre de l'onglet
  
  # Ligne d'entête ----------------------------------------------------------
  dashboardHeader(
    titleWidth = "100%",
    title = HTML(
      "<div>
        Estimez la dotation forfaitaire de votre commune pour l'année 2019
      <a href='http://etalab.gouv.fr' target='_blank'>
      <img src = 'etalab-blanc.png' height = '30px', align= 'right', vspace='10'>
      </a>

      <a href='http://www.cohesion-territoires.gouv.fr/' target='_blank'>
      <img src = 'logo_cohesion_territoire.jpg' height = '50px' hspace='20' align= 'right'>
      </a>
      </div>")
  ),
  
  # Menu de gauche ----------------------------------------------------------
  dashboardSidebar(
    width = 300,
    
    selectizeInput(
      "nomDepartement", "Département",
      choices = unique(departements$NCC), multiple = FALSE
      ),
    selectizeInput(
      "nomCommune", "Commune",
      choices = "", multiple = FALSE
      ),
    
    # Pour adapter l'url
    hr(),

    div(style = "font-size:15px",
        sliderInput("population2019", "Définissez la population DGF 2019",
                           min = 0, max = 1000, value = donnees$PopDGF2018[1], sep = "",
                    ticks = FALSE)
        ,
        numericInput("population2019bis", "Ou entrez directement une valeur", 
                     min = 0, max = 67000000, value = donnees$PopDGF2018[1],
                     step = 1)
        ),
    hr(),
    conditionalPanel(
      condition = "output.communeNouvelle", 
      box(
        title = "Informations sur la commune", status = "warning", solidHeader = TRUE,
        collapsible = FALSE, width = 12,
        div(style = "color:black", 
            textOutput("infoCommuneNouvelle")
        )
      )
    ),
    
    # Liens en bas à gauche A CHANGER
    mainPanel(width = 12,
      div(
        class = "credits",
        tags$a(href = "https://github.com/marion-paclot/DotationForfaitaire/issues", "Télécharger la notice explicative")),
      tags$a(href = "https://github.com/marion-paclot/DotationForfaitaire/", "Voir le code source")
      )
    ),
  
  # Page centrale -----------------------------------------------------------
  
  dashboardBody(
    bsModal(id = 'avertissement', title = 'Avertissement', trigger = '',
            size = 'medium', 
            p("Ce simulateur a été réalisé au périmètre communal 2018 et ne vaut 
              pas notification du montant de dotation forfaitaire pour 2019.")
            ),
    tags$head(tags$style("#avertissement .modal-footer{ display:none}")),
    
    # <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      
    
    fluidRow(
      
      # Tracking de visite
      tags$head(HTML(
        "<script type='text/javascript'>
        var _paq = _paq || [];
        _paq.push(['trackPageView']);
        _paq.push(['enableLinkTracking']);
        
        (function() {
        var u='//stats.data.gouv.fr/';
        _paq.push(['setTrackerUrl', u+'piwik.php']);
        _paq.push(['setSiteId', '76']);
        var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
        g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
        })();
        </script>"
      )),
      
      # Tracking d'événements
      tags$script(HTML(
        "$(document).on('shiny:inputchanged', function(event) {
        if (event.name === 'nomDepartement' || event.name === 'nomCommune') {
        _paq.push(['trackEvent', 'input', 'updates', event.name, event.value]);
        }
        });"
      )),
      
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
      
      valueBoxOutput("DF2016", width = 3),
      valueBoxOutput("DF2017", width = 3),
      valueBoxOutput("DF2018", width = 3),
      valueBoxOutput("DF2019", width = 3),
      
      box(
        title = "Détail de l'estimation", status = "primary", solidHeader = TRUE,
        collapsible = FALSE, width = 12, 
        
        fluidRow(
          box("Dotation forfaitaire de l'année antérieure", width = 3),
          box(textOutput("detailValeurDFanterieure"), width = 3),
          box("Montant de la dotation forfaitaire de l'année passée.", width = 6)
        ),
        fluidRow(
          box("Part dynamique de la population", width = 3),
          box(textOutput("detailValeurPartPop"), width = 3),
          box(textOutput("detailDeltaPop"), width = 6)
        ),
        fluidRow(
          box("Ecrêtement", width = 3),
          box(textOutput("detailValeurEcretement"), width = 3),
          box("L'écrêtement correspond à la participation de la commune au dynamisme 
              de certaines composantes de la DGF, comme la hausse de la péréquation et 
              la hausse de la population. Son montant dépend du potentiel fiscal 
              communal comparé au potentiel fiscal national, et il est plafonné à 1% 
              des recettes réelles de fonctionnement telles que définies à l'article 
              R2334-3-2 du code général des collectivités territoriales.", 
              width = 6)
        )
        )
    )
    
  )
)


