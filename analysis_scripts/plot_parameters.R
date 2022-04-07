library("stringr")
library("cowplot")
library("readr")

# FUNCTIONS
.read_all_datasets <- function(file_path, file_names){
  all_datasets <- list()
  for (i in 1:length(file_names)) {
    file_location <- paste0(file_path, file_names[i])
    dataset <- as.data.frame(read.csv(file_location))
    dataset <- .reshape_wrapper(dataset)
    all_datasets[[i]] <- dataset
  }
  return(all_datasets)
}

.reshape_wrapper <- function(dataset) {
  dataset <- tidyr::gather(dataset, action, value, inaction:engage, factor_key = TRUE)
  return(dataset)
}

.matrix_lineplots <- function(data_list, plot_titles, file_name, yLab, expValuePlot = FALSE){
  plot_list <- list()
  for (i in 1:length(data_list)) {
    dataset <- data_list[[i]]
    if (!expValuePlot) {
      plot <- .gg_line_plot(dataset, plot_titles[i], yLab)
    } else {
      plot <- .expValuePlot(dataset, plot_titles[i])
    }
    plot_list[[i]] <- plot
  }
  ncol = 1
  nrow =  round((length(data_list) + 1) / ncol)   
  matrixPlot <- cowplot::plot_grid(plotlist = plot_list, nrow = nrow, ncol = ncol)
  png(file_name, width = 1000, height = 1000)
  print(matrixPlot)
  dev.off()
}


.gg_line_plot <- function(dataset, title, ylab) {
  plot <-  ggplot2::ggplot() +
    ggplot2::geom_line(data = dataset, mapping = ggplot2::aes(x = X, y = value, group = action, color = action), size = 1) +
    ggplot2::xlab("Time in runs") +
    ggplot2::ylab(ylab) +
    ggplot2::ggtitle(title) +
    ggplot2::theme_light()
  if (ylab == "Emo. Intensity"){
    plot <- plot + ggplot2::geom_vline(xintercept = c(10, 20), size = 1)
  }
  return(plot)
}


.expValuePlot <- function(dataset, title){
  exp_value_plot <- ggplot2::ggplot() +
    ggplot2::geom_point(data = dataset, mapping = ggplot2::aes(x = X, y = value, color = action), size = 4) +
    ggplot2::geom_line(data = dataset, mapping = ggplot2::aes(x = X, y = value, color = action), size = 1) +
    ggplot2::scale_x_continuous(breaks = 0:10, name = "Stimulus Intensity") +
    ggplot2::scale_y_continuous(breaks = pretty(dataset$value), name = "Expected Value") +
    ggplot2::ggtitle(title) +
    ggplot2::theme_light()
  return(exp_value_plot)
}

.getAllPlots <- function(path, parameterName) {
  all_file_names <- list.files(path)
  file_order <- order(parse_number(all_file_names))
  all_file_names <- all_file_names[file_order]
  all_actionCumSum <- str_which(all_file_names, "actionCumSum") %>% all_file_names[.]
  all_actionTrajectory <- str_which(all_file_names, "actionTrajectory") %>% all_file_names[.]
  all_RewardsCumMean <- str_which(all_file_names, "RewardsCumMean") %>% all_file_names[.]
  all_ExpValues <- str_which(all_file_names, "expectedValue") %>% all_file_names[.]
  paramterValues <- sort(unique(parse_number(all_file_names)))
  
  all_actionCumSum_data <- .read_all_datasets(path, all_actionCumSum)
  all_actionTrajectory_data <- .read_all_datasets(path, all_actionTrajectory)
  all_RewardsCumMean_data <- .read_all_datasets(path, all_RewardsCumMean)
  all_expValue_data <- .read_all_datasets(path, all_ExpValues)
  
  fileName <- "../plots/"
  
  plotTitles_actions <- paste("Actions -", parameterName, paramterValues)
  fileNameActions <- paste0(fileName, parameterName, "_actions", ".png")
  .matrix_lineplots(all_actionCumSum_data, plotTitles_actions, fileNameActions, "Cum. Sum")
  
  plotTitles_trajectories <- paste("Trajectories -", parameterName, paramterValues)
  fileNameTrajectories <- paste0(fileName, parameterName, "_trajectories", ".png")
  .matrix_lineplots(all_actionTrajectory_data, plotTitles_trajectories, fileNameTrajectories, "Emo. Intensity")
  
  plotTitles_rewards <- paste("Rewards -", parameterName, paramterValues)
  fileNameRewards <- paste0(fileName, parameterName, "_rewards", ".png")
  .matrix_lineplots(all_RewardsCumMean_data, plotTitles_rewards, fileNameRewards, "Cum. Mean")
  
  plotTitles_expValues <- paste("Expected Values -", parameterName, paramterValues)
  fileNameExpValues <- paste0(fileName, parameterName, "_expValues", ".png")
  .matrix_lineplots(all_expValue_data, plotTitles_expValues, fileNameExpValues, "Cum. Mean", expValuePlot = TRUE)
  
}




#### GET PLOTS ######
path <- "../datasets/FiveToTen/"
parameterName <- "Intensity Min Five Max Ten"
.getAllPlots(path, parameterName)
