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



vectorToDf <- function(meanVector, seVector) {
  df <- data.frame("Bin" = rep(0:2, each = 3), "Action" = c("Inaction", "Disengage", "Engage"),
             "Action_Counter" = c(meanVector[c(1, 4, 7)], meanVector[c(2, 5, 8)], meanVector[c(3, 6, 9)]),
             "se" = c(seVector[c(1, 4, 7)], seVector[c(2, 5, 8)], seVector[c(3, 6, 9)]))
  return(df)
}

ggBarPlot <- function(df1) {
  plot <- ggplot2::ggplot(data = df1, mapping = ggplot2::aes(x = Bin, y = Action_Counter, fill = Action)) + 
    ggplot2::geom_bar(stat = "identity", position = "dodge") +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = Action_Counter - 1.96 * se, ymax = Action_Counter + 1.96 * se), position = "dodge") +
    ggplot2::theme_light()
  return(plot)
}

# equal benefits, differing values
path <- "../datasets/GridSearchEqualBenefits/"
all_file_names <- list.files(path)
file_order <- order(parse_number(all_file_names))
all_file_names <- all_file_names[file_order]

all_actions <- str_which(all_file_names, "actionPerIntensity") %>% all_file_names[.]
all_actions_data <- .read_all_parameters(path, all_actions)

all_actions_benefit1 <- all_actions_data[0:29]
all_actions_benefit3 <- all_actions_data[30:59]
all_actions_benefit5 <- all_actions_data[60:89]

#equal benefits = 1
actionListVec1 <- lapply(all_actions_benefit1, c, recursive=TRUE)
wideActions1 <- do.call(cbind, actionListVec1)
rowMeans1 <- rowMeans(wideActions1)
se1 <- apply(wideActions1, 1, sd)/sqrt(30)

df1 <- vectorToDf(rowMeans1, se1)
plot1 <- ggBarPlot(df1)

png("equalBenefits1.png", width = 500, height = 500)
print(plot1)
dev.off()


#equal benefits = 3
actionListVec3 <- lapply(all_actions_benefit3, c, recursive=TRUE)
wideActions3 <- do.call(cbind, actionListVec3)
rowMeans3 <- rowMeans(wideActions3)
se3 <- apply(wideActions3, 1, sd)/sqrt(30)

df3 <- vectorToDf(rowMeans3, se3)
plot3 <- ggBarPlot(df3)

png("equalBenefits3.png", width = 500, height = 500)
print(plot3)
dev.off()

#equal benefits = 5
actionListVec5 <- lapply(all_actions_benefit5, c, recursive=TRUE)
wideActions5 <- do.call(cbind, actionListVec5)
rowMeans5 <- rowMeans(wideActions5)
se5 <- apply(wideActions5, 1, sd)/sqrt(30)

df5 <- vectorToDf(rowMeans5, se5)
plot5 <- ggBarPlot(df5)

png("equalBenefits5.png", width = 500, height = 500)
print(plot5)
dev.off()

# equal benefits, differing n_stimuli

path <- "../datasets/GridSearchEqualBenefitsNSTIMULI/"
all_file_names <- list.files(path)
file_order <- order(parse_number(all_file_names))
all_file_names <- all_file_names[file_order]

all_actions <- str_which(all_file_names, "actionPerIntensity") %>% all_file_names[.]

all_actions_data <- .read_all_parameters(path, all_actions)

all_actions_benefit300 <- all_actions_data[0:29]
all_actions_benefit600 <- all_actions_data[30:59]
all_actions_benefit1000 <- all_actions_data[60:89]


#N_Stimuli = 300

actionListVec300 <- lapply(all_actions_benefit300, c, recursive=TRUE)
wideActions300 <- do.call(cbind, actionListVec300)
rowMeans300 <- rowMeans(wideActions300)
se300 <- apply(wideActions300, 1, sd)/sqrt(30)

df300 <- vectorToDf(rowMeans300, se300)
plot300 <- ggBarPlot(df300)

png("equalBenefits300.png", width = 500, height = 500)
print(plot300)
dev.off()

#N_Stimuli = 600

actionListVec600 <- lapply(all_actions_benefit600, c, recursive=TRUE)
wideActions600 <- do.call(cbind, actionListVec600)
rowMeans600 <- rowMeans(wideActions600)
se600 <- apply(wideActions600, 1, sd)/sqrt(30)

df600 <- vectorToDf(rowMeans600, se600)
plot600 <- ggBarPlot(df600)

png("equalBenefits600.png", width = 500, height = 500)
print(plot600)
dev.off()

#N_Stimuli = 1000

actionListVec1000 <- lapply(all_actions_benefit1000, c, recursive=TRUE)
wideActions1000 <- do.call(cbind, actionListVec1000)
rowMeans1000 <- rowMeans(wideActions1000)
se1000 <- apply(wideActions1000, 1, sd)/sqrt(30)

df1000 <- vectorToDf(rowMeans1000, se1000)
plot1000 <- ggBarPlot(df1000)

png("equalBenefits1000.png", width = 500, height = 500)
print(plot1000)
dev.off()

# engage_benefit higher

path <- "../datasets/GridSearchEngagementTinyAdvantage/"
all_file_names <- list.files(path)
file_order <- order(parse_number(all_file_names))
all_file_names <- all_file_names[file_order]

all_actionsEngageAdv <- str_which(all_file_names, "actionPerIntensity") %>% all_file_names[.]

all_actionsEngageAdv_data <- .read_all_parameters(path, all_actionsEngageAdv)


actionListEngageAdv <- lapply(all_actionsEngageAdv_data, c, recursive=TRUE)
wideActionsEngageAdv <- do.call(cbind, actionListEngageAdv)
rowMeansEH <- rowMeans(wideActionsEngageAdv)
seEH <- apply(wideActionsEngageAdv, 1, sd)/sqrt(30)

dfEH <- vectorToDf(rowMeansEH, seEH)
plotEH <- ggBarPlot(dfEH)

png("equalBenefitsEH.png", width = 500, height = 500)
print(plotEH)
dev.off()


# disengage_benefit higher

path <- "../datasets/GridSearchDisengagementTinyAdvantage/"
all_file_names <- list.files(path)
file_order <- order(parse_number(all_file_names))
all_file_names <- all_file_names[file_order]

all_actionsdisengageAdv <- str_which(all_file_names, "actionPerIntensity") %>% all_file_names[.]

all_actionsdisengageAdv_data <- .read_all_parameters(path, all_actionsdisengageAdv)


actionListdisengageAdv <- lapply(all_actionsdisengageAdv_data, c, recursive=TRUE)
wideActionsdisengageAdv <- do.call(cbind, actionListdisengageAdv)
rowMeansDH <- rowMeans(wideActionsdisengageAdv)
seDH <- apply(wideActionsdisengageAdv, 1, sd)/sqrt(30)

dfDH <- vectorToDf(rowMeansDH, seDH)
plotDH <- ggBarPlot(dfDH)

png("equalBenefitsDH.png", width = 500, height = 500)
print(plotDH)
dev.off()

# benefits equal but adaptation

path <- "../datasets/GridSearchEqualButAdaptation/"
all_file_names <- list.files(path)
file_order <- order(parse_number(all_file_names))
all_file_names <- all_file_names[file_order]

all_actionsEqualButAdapt <- str_which(all_file_names, "actionPerIntensity") %>% all_file_names[.]

all_actionsEqualButAdapt_data <- .read_all_parameters(path, all_actionsEqualButAdapt)


actionListEqualButAdapt <- lapply(all_actionsEqualButAdapt_data, c, recursive=TRUE)
wideActionsEqualButAdapt <- do.call(cbind, actionListEqualButAdapt)
rowMeansAD <- rowMeans(wideActionsEqualButAdapt)
seAD <- apply(wideActionsEqualButAdapt, 1, sd)/sqrt(30)

dfAD <- vectorToDf(rowMeansAD, seAD)
plotAD <- ggBarPlot(dfAD)

png("equalBenefitsAD.png", width = 500, height = 500)
print(plotAD)
dev.off()

