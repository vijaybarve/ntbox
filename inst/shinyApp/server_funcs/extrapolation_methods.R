observe({
  wf_directory <- workflowDir()

  m_layers <- NULL
  g_layers <- NULL

  # Para salvar el workflow
  # length(nchar(wf_directory))>0L

  if(!is.null(rasterLayers())){
    m_layers <- c(m_layers,"Niche Layers from AppSettings" = "niche_layers")
    updateSelectInput(session,"mlayers_extra",
                      choices = m_layers)

  }

  if(!is.null(proj_rasterLayers())){
    g_layers <- c(g_layers,"Projection Layers from AppSettings" = "proj_layers")

    updateSelectInput(session,"glayers_extra",
                      choices =g_layers)


  }
  if(!is.null(define_M_raster())){
    g_layers <- c(g_layers,"M Layers defined on dynamic map" = "m_layers")
    updateSelectInput(session, "glayers_extra",
                      choices = g_layers)
    m_layers <- c(m_layers,"M Layers defined on dynamic map" = "m_layers")
    updateSelectInput(session, "mlayers_extra",
                      choices = m_layers)

  }
  if(!is.null(mask_layers())){
    g_layers <- c(g_layers,"Masked layers from GIS Tools" = "masked_layers")
    updateSelectInput(session, "glayers_extra",
                      choices = g_layers)
    m_layers <- c(m_layers,"Masked layers from GIS Tools" = "masked_layers")
    updateSelectInput(session, "mlayers_extra",
                      choices = m_layers)
  }
  if(!is.null(crop_layers())){
    g_layers <- c(g_layers,"Cropped layers from GIS Tools" = "cropped_layers")
    updateSelectInput(session, "glayers_extra",
                      choices = g_layers)
    m_layers <- c(m_layers,"Cropped layers from GIS Tools" = "cropped_layers")
    updateSelectInput(session, "mlayers_extra",
                      choices = m_layers)
  }
  if(!is.null(crop_layers_proj())){
    g_layers <- c(g_layers,"Cropped projection layers from GIS Tools" = "cropped_proj_layers")
    updateSelectInput(session, "glayers_extra",
                      choices = g_layers)
  }
  if(!is.null(mask_layers_proj())){
    g_layers <- c(g_layers,"Masked projection layers from GIS Tools" = "masked_proj_layers")
    updateSelectInput(session, "glayers_extra",
                      choices = g_layers)
  }

})


M_ras_Layers <- reactive({
  if(input$mlayers_extra=="niche_layers")
    return(rasterLayers())
  if(input$mlayers_extra=="m_layers")
    return(define_M_raster())
  if(input$mlayers_extra == "masked_layers")
    return(mask_layers())
  if(input$mlayers_extra == "cropped_layers")
    return(crop_layers())

})

G_ras_Layers <- reactive({
  if(input$glayers_extra=="proj_layers")
    return(proj_rasterLayers())
  if(input$glayers_extra=="m_layers")
    return(define_M_raster())
  if(input$glayers_extra == "masked_layers")
    return(mask_layers())
  if(input$glayers_extra == "cropped_layers")
    return(crop_layers())
  if(input$glayers_extra == "cropped_proj_layers")
    return(crop_layers_proj())
  if(input$glayers_extra == "masked_proj_layers")
    return(mask_layers_proj())

})


observe({
  if(!is.null(M_ras_Layers())){
    updateSelectInput(session,inputId = "mlayers_select",
                      choices = names(M_ras_Layers()),
                      selected =  names(M_ras_Layers()))
  }

  if(!is.null(G_ras_Layers())){
    updateSelectInput(session,inputId = "glayers_select",
                      choices = names(G_ras_Layers()),
                      selected =  names(G_ras_Layers()))
  }


})



mop_comp <- eventReactive(input$run_mop,{
  m_layers <- M_ras_Layers()[[input$mlayers_select]]
  g_layers <- G_ras_Layers()[[input$glayers_select]]
  mop_names <- all(length(names(m_layers))==length(names(g_layers)))

  percent <- as.numeric(as.character(input$ref_percent))
  comp_each <- as.numeric(as.character(input$comp_each))
  if(mop_names){

    mop_anlysis <- ntbox::mop(M_stack =  m_layers,
                              G_stack = g_layers,
                              percent= percent,
                              comp_each = comp_each,
                              parallel = input$parallel_comp,
                              normalized=FALSE)
    mop_max <- cellStats(mop_anlysis,max)*1.05
    mop_norm <- 1 - (mop_anlysis/mop_max)



    return(list(mop_anlysis,mop_norm ))

  }
  else
    return(NULL)

})



output$show_m_g_layers <- renderPlot({

  if(!is.null(M_ras_Layers())){
    plot(M_ras_Layers()[[1]])
  }
  if(!is.null(M_ras_Layers()) & !is.null(G_ras_Layers())){
    par(mfrow=c(1,2))
    plot(M_ras_Layers()[[1]])
    plot(G_ras_Layers()[[1]])
  }
  else{
    messages <- "Load M and G layers"
    x <- -10:10
    y <- x
    plot(x,y,type="n", xlab="No Data", ylab="No data",cex=2)
    text(0,0,messages,cex=3 )
  }

})

output$mop_plot <- renderPlot({
  if(!is.null(mop_comp())){
    #colramp <- colorRampPalette(c("#2cd81c","#385caa",
    #                              "#1825df","black"))(226)
    colramp <- colorRampPalette(c("#1210d9","#7605e0",
                                  "#a618d1","#d3168c",
                                  "#ea1136"))(226)
    mop_raster<- mop_comp()

    if(!input$normalized_mop)
      plot(mop_raster[[1]],col=colramp,main="MOP")


    if(input$normalized_mop){
      colramp <- rev(colramp)
      plot(mop_raster[[2]],col=colramp,main="MOP")
    }



  }

})

output$mop_raster <- downloadHandler(
  filename <- function() {paste0("mop_results_",
                                 as.numeric(input$ref_percent),
                                 "_percent_normalized_",
                                 input$normalized_mop,".asc")},
  content <- function(file){
    if(!is.null(mop_comp())){
      if(input$normalized_mop)
        return(writeRaster(mop_comp()[[2]],filename = file))
      else
        return(writeRaster(mop_comp()[[1]],filename = file))
    }
  })


## Messs Methods


mess_comp <- eventReactive(input$run_mess,{
  m_layers <- M_ras_Layers()[[input$mlayers_select]]
  g_layers <- G_ras_Layers()[[input$glayers_select]]
  nlayers <- all(length(names(m_layers))==length(names(g_layers)))

  if(nlayers){
    #mLPuntos <- as.data.frame(na.omit(getValues(m_layers)))
    mess_comp <- ntbox::ntb_mess(M_stack =m_layers,G_stack = g_layers)
    return(mess_comp)
  }
  else
    return(NULL)

})



output$mess_plot <- renderPlot({
  if(!is.null(mess_comp())){
    #colramp <- colorRampPalette(c("#2cd81c","#385caa",
    #                              "#1825df","black"))(226)
    colramp <- colorRampPalette(c("#1210d9","#7605e0",
                                  "#a618d1","#d3168c",
                                  "#ea1136"))(226)
    mess_raster<- mess_comp()


    plot(mess_raster,col=rev(colramp),main="MESS")


  }

})

output$mess_raster <- downloadHandler(
  filename <- function() {paste0("mess_results.asc")},
  content <- function(file){
    if(!is.null(mess_comp())){
     return(writeRaster(mess_comp(),filename = file))
    }
  })


# Exdet NT1

exdet_univar_comp <- eventReactive(input$run_nt1,{
  m_layers <- M_ras_Layers()[[input$mlayers_select]]
  g_layers <- G_ras_Layers()[[input$glayers_select]]
  nlayers <- all(length(names(m_layers))==length(names(g_layers)))

  if(nlayers){
    nt1 <- ntbox::exdet_univar(M_stack = m_layers,
                               G_stack =g_layers,
                               G_mold = NULL)
    return(nt1)
  }
})


output$exdet_univarC <- renderPlot({
  if(!is.null(exdet_univar_comp())){
    nt1 <- exdet_univar_comp()
    plot(nt1,main="NT1")
  }

})


output$nt1_raster <- downloadHandler(
  filename <- function() {paste0("nt1_results.asc")},
  content <- function(file){
    if(!is.null(exdet_univar_comp())){
      return(writeRaster(exdet_univar_comp(),filename = file))
    }
  })



# NT2

exdet_multvar_comp <- eventReactive(input$run_nt2,{
  m_layers <- M_ras_Layers()[[input$mlayers_select]]
  g_layers <- G_ras_Layers()[[input$glayers_select]]
  nlayers <- all(length(names(m_layers))==length(names(g_layers)))

  if(nlayers){
    nt2 <- ntbox::exdet_multvar(M_stack = m_layers,
                                G_stack =g_layers,
                                G_mold = NULL)
    return(nt2)
  }
})


output$exdet_multvarC <- renderPlot({
  if(!is.null(exdet_multvar_comp())){
    nt2 <- exdet_multvar_comp()
    plot(nt2,main="NT2")
  }

})

output$nt2_raster <- downloadHandler(
  filename <- function() {paste0("nt2_results.asc")},
  content <- function(file){
    if(!is.null(exdet_multvar_comp())){
      return(writeRaster(exdet_multvar_comp(),filename = file))
    }
  })



