library(shiny) # il faut charger le package au début de chacun des scripts
library(ChannelAttribution)
library(reshape)
library(ggplot2)
library(googleAuthR)
library(googleAnalyticsR)
library(dplyr)


 getMarkovChainsData <- function(vid,threshold, from, to){
  gar_auth('.httr-oauth')
  vid <- vid
  
  trans_filter <- "mcf:conversionType==Transaction" # the conversion you're interested in
  visit_filter <- "mcf:conversionGoalNumber==001"   # "visit" conversion
  
  # date range
  from <- from
  to   <- to
  
  dim = "sourceMediumPath"
  
  get_data <- function(vid, from, to, filters = "",
                       dim = "sourceMediumPath", max = 25000) {
    df <- google_analytics_3(id = vid, 
                             start = from, end = to, 
                             metrics = c("totalConversions"), 
                             dimensions = dim,
                             filters = filters,
                             type="mcf",
                             max_results = max)
    # clean up and set class
    df[,1] <- gsub(" / ", "/", df[,1])              # remove spacing
    df[,1] <- gsub(":?(NA|CLICK|NA):?", "", df[,1]) # remove CLICK and NA
    df[,2] <- as.numeric(df[,2])                    # conversion column is character :-/
    
    # return the dataframe
    df
  }
  
  transactions <- get_data(vid=vid, from=from, to=to, dim=dim, filters=trans_filter)
  colnames(transactions) <- c("path", "transactions")
  
  visits <- get_data(vid=vid, from=from, to=to, dim=dim, filters=visit_filter)
  colnames(visits) <- c("path", "visits")
  
  alldata <- merge.data.frame(visits, transactions, by = "path", all=T)
  alldata[is.na(alldata$transactions), "transactions"] <- 0
  
  alldata$rate <- alldata$transactions / alldata$visits
  alldata$null  <- alldata$visits - alldata$transactions
  
  mm <- markov_model(alldata, var_path = "path",
                     var_conv = "transactions",
                     #var_value = "value", #use this if you have conversion values
                     var_null = "null",
                     order=1, nsim=NULL, max_step=NULL, out_more=FALSE)
  names(mm)[2] <- "markov_chains_attribution"
  hm <- heuristic_models(alldata, var_path = "path",
                         #var_value = "value",
                         var_conv = "transactions")
  
  modeled <- merge.data.frame(hm, mm, all=T, by="channel_name")
  
  threshold <- threshold
  filtered_data <- filter(modeled,first_touch > threshold | last_touch > threshold | linear_touch > threshold | markov_chains_attribution > threshold )
  tidy_data <- melt(filtered_data, id='channel_name')
  
  plots <-ggplot(tidy_data, aes(channel_name, value, fill = variable)) +
    geom_bar(stat='identity', position='dodge') +
    ggtitle('Comparison Heuristic Channels vs Markov Chains') + 
    facet_wrap(~channel_name,ncol=5, scales="free") +
    theme(axis.title.x = element_text(vjust = -2)) +
    theme(axis.title.y = element_text(vjust = +2)) +
    theme(title = element_text(size = 16)) +
    theme(plot.title=element_text(size = 20)) +
    ylab("")
  
  return (plots)
}



shinyServer( function(input, output) { # les éléments de la partie 'server' vont être définis ici
  
  output$platform <- renderText({input$platform})
  output$markov_plots <- renderPlot({
  markovPlots <- getMarkovChainsData(input$platform, input$conversion_threshold, input$dateRange[1], input$dateRange[2])
   markovPlots
  })
  
})