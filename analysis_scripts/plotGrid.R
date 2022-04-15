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


.read_all_parameters <- function(file_path, file_names){
  all_datasets <- list()
  for (i in 1:length(file_names)) {
    file_location <- paste0(file_path, file_names[i])
    dataset <- as.data.frame(read.csv(file_location))
    all_datasets[[i]] <- dataset[,-1]
  }
  return(all_datasets)
}

.reshape_wrapper <- function(dataset) {
  dataset <- tidyr::gather(dataset, action, value, inaction:engage, factor_key = TRUE)
  return(dataset)
}

.gg_line_plot_time <- function(dataset, title, ylab) {
  plot <-  ggplot2::ggplot() +
    ggplot2::geom_line(data = dataset, mapping = ggplot2::aes(x = X, y = value, group = action, color = action), size = 1) +
    ggplot2::xlab("Time in runs") +
    ggplot2::ylab(ylab) +
    ggplot2::ggtitle(title) +
    ggplot2::theme_light()
  if (ylab == "Emo. Intensity"){
    plot <- plot + ggplot2::geom_vline(xintercept = c(10, 20), size = 1) +
      ggplot2::scale_y_continuous(breaks = 0:10, limits = c(0, 10))
  }
  return(plot)
}


.gg_line_plot_per_intensity <- function(dataset, title, ylab){
  plot <- ggplot2::ggplot() +
    ggplot2::geom_point(data = dataset, mapping = ggplot2::aes(x = X, y = value, color = action), size = 2) +
    ggplot2::geom_line(data = dataset, mapping = ggplot2::aes(x = X, y = value, color = action), size = .8) +
    ggplot2::scale_x_continuous(breaks = 0:10, name = "Stimulus Intensity") +
    ggplot2::scale_y_continuous(breaks = pretty(dataset$value), name = ylab) +
    ggplot2::ggtitle(title) +
    ggplot2::theme_light()
  return(plot)
}

.gg_parameter_plot <- function(dataset) {
  text <- paste0(names(dataset), ":", " ", as.vector(dataset))
  textData <- data.frame(x = rep(5, 11), y = 11:1, text = text)
  plot <- ggplot2::ggplot(data.frame(x = 0:11, y = 0:11), mapping = ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_text(data = textData, mapping = ggplot2::aes(x = x, y = y, label = text)) +
    ggplot2::theme_void()
  return(plot)
}

.getAllPlots <- function(path, folderName) {
  dir.create(paste0("../plots/", folderName))
  all_file_names <- list.files(path)
  file_order <- order(parse_number(all_file_names))
  all_file_names <- all_file_names[file_order]
  all_actionPerIntensity <- str_which(all_file_names, "actionPerIntensity") %>% all_file_names[.]
  all_actionTrajectory <- str_which(all_file_names, "actionTrajectory") %>% all_file_names[.]
  all_expectedValue <- str_which(all_file_names, "expectedValue") %>% all_file_names[.]
  all_learnedValue <- str_which(all_file_names, "learnedValue") %>% all_file_names[.]
  all_parameters <- str_which(all_file_names, "parameters") %>% all_file_names[.]
  
  all_actionPerIntensity_data <- .read_all_datasets(path, all_actionPerIntensity)
  all_actionTrajectory_data <- .read_all_datasets(path, all_actionTrajectory)
  all_learnedValue_data <- .read_all_datasets(path, all_learnedValue)
  all_expectedValue_data <- .read_all_datasets(path, all_expectedValue)
  all_parameters_data <- .read_all_parameters(path, all_parameters)
  
  for(i in seq_along(all_parameters_data)) {
    fileName <- paste0("../plots/", folderName, "/SummaryPlotRun", i, ".png")
    parameterOverview <- .gg_parameter_plot(all_parameters_data[[i]])
    trajectoryPlot <- .gg_line_plot_time(all_actionTrajectory_data[[i]], title = "Trajectory per action", ylab = "Emo. Intensity")
    actionPlot <- .gg_line_plot_per_intensity(all_actionPerIntensity_data[[i]], title = "Actions per Intensity", ylab = "Actions Sum")
    learnedValuePlot <- .gg_line_plot_per_intensity(all_learnedValue_data[[i]], "Learned Values", "Value")
    expectedValuePlot <- .gg_line_plot_per_intensity(all_expectedValue_data[[i]], "Objective Values", "Value")
    plotList <- list(parameterOverview, trajectoryPlot, actionPlot, learnedValuePlot, expectedValuePlot)
    ncol = 2
    nrow =  3
    matrixPlot <- cowplot::plot_grid(plotlist = plotList, nrow = nrow, ncol = ncol)
    png(fileName, width = 1000, height = 1000)
    print(matrixPlot)
    dev.off()
    
  }
}




#### GET PLOTS ######
path <- "../datasets/GridSearchA/"
folderName <- "GridSearchA"
.getAllPlots(path, folderName)
