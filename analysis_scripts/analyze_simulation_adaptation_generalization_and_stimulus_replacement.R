library("stringr")
library("cowplot")
library("readr")

ggBarPlot <- function(df1) {
  plot <- ggplot2::ggplot(data = df1, mapping = ggplot2::aes(x = Bin, y = Action_Counter, fill = Action)) + 
    ggplot2::geom_bar(stat = "identity", position = "dodge") +
    ggplot2::theme_light()
  return(plot)
}

.read_all_datasets <- function(file_path, file_names){
  all_datasets <- list()
  for (i in 1:length(file_names)) {
    file_location <- paste0(file_path, file_names[i])
    dataset <- as.data.frame(read.csv(file_location))
    all_datasets[[i]] <- dataset[,-1]
  }
  return(all_datasets)
}

ggBarPlot <- function(df1) {
  plot <- ggplot2::ggplot(data = df1, mapping = ggplot2::aes(x = Bin, y = Action_Counter, fill = Action)) + 
    ggplot2::geom_bar(stat = "identity", position = "dodge") +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = Action_Counter - 1.96 * se, ymax = Action_Counter + 1.96 * se), position = "dodge") +
    ggplot2::theme_light()
  return(plot)
}

vectorToDf <- function(meanVector, seVector) {
  df <- data.frame("Bin" = rep(0:2, each = 3), "Action" = c("Inaction", "Disengage", "Engage"),
                   "Action_Counter" = c(meanVector[c(1, 4, 7)], meanVector[c(2, 5, 8)], meanVector[c(3, 6, 9)]),
                   "se" = c(seVector[c(1, 4, 7)], seVector[c(2, 5, 8)], seVector[c(3, 6, 9)]))
  return(df)
}

## example plot of ratio

ratioExampleData <- read.csv("../datasets/SimAdaptationGeneralizationAndStimulusReplacement/SimAdaptationGeneralizationAndStimulusReplacement_0_actionPerIntensity.csv")
ratioExampleDf <- data.frame(Bin = rep(0:2, each = 3), Action = c("Inaction", "Disengage", "Engage"),
                             Action_Counter = as.numeric(c(ratioExampleData[1,2:4], ratioExampleData[2,2:4], ratioExampleData[3,2:4])))


ratioExamplePlot <- ggBarPlot(ratioExampleDf) 



## heatmap

# data loading
path <- "../datasets/SimAdaptationGeneralizationAndStimulusReplacement/"
all_file_names <- list.files(path)
file_order <- order(parse_number(all_file_names))
all_file_names <- all_file_names[file_order]


# separate parameter files from data files
all_actions <- str_which(all_file_names, "actionPerIntensity") %>% all_file_names[.]
all_actions_data <- .read_all_datasets(path, all_actions)


all_parameters <- str_which(all_file_names, "parameters") %>% all_file_names[.]
all_parameter_data <- .read_all_datasets(path, all_parameters)

unlisted <- unlist(all_parameter_data)
occurrence_values <- unique(unlisted[names(unlisted) == "STIMULUS_MAX_OCCURRENCE"])
generalization_values <- unique(unlisted[names(unlisted) == "adaptation_generalization"])


grid <- expand.grid(max_occurrence = factor(occurrence_values),
                    adaptation_generalization = factor(generalization_values, rev(generalization_values)))


lowRatios <- c()
highRatios <- c()
overallRatios <- c()


for (i in seq_len(nrow(grid))){
  occurr <- grid$max_occurrence[i]
  general <- grid$adaptation_generalization[i]
  indices <- which(sapply(all_parameter_data, function(x, occurr, general) x$STIMULUS_MAX_OCCURRENCE == occurr & x$adaptation_generalization == general,
               occurr = occurr, general = general))
  current_action_data <- all_actions_data[indices]
  actionListVec <- lapply(current_action_data, c, recursive=TRUE)
  wideActions <- do.call(cbind, actionListVec)
  rowMeans <- rowMeans(wideActions)
  lowRatios <- c(lowRatios, as.numeric(rowMeans[8]/rowMeans[5]))
  highRatios <- c(highRatios, as.numeric(rowMeans[9]/rowMeans[6]))
  overallRatios <- c(overallRatios, sum(rowMeans[8:9])/sum(rowMeans[5:6]))
}


heatmapDf <- cbind(grid, low_ratios = lowRatios, high_ratios = highRatios, overall_ratios = overallRatios)

png("heatmapOverall.png", width = 800, height = 800)
ggplot2::ggplot(data = heatmapDf, mapping = ggplot2::aes(x = max_occurrence, y = adaptation_generalization, fill = overall_ratios)) +
  ggplot2::geom_tile() +
  ggplot2::geom_text(ggplot2::aes(label = round(overall_ratios, 1))) +
  ggplot2::scale_fill_gradient(low = "lightblue", high = "darkblue", limits = c(1, 6)) +
  ggplot2::xlab("STIMULUS_MAX_OCCURRENCE") +
  ggplot2::theme_light()
dev.off()


png("heatmapLow.png", width = 800, height = 800)
ggplot2::ggplot(data = heatmapDf, mapping = ggplot2::aes(x = max_occurrence, y = adaptation_generalization, fill = low_ratios)) +
  ggplot2::geom_tile() +
  ggplot2::geom_text(ggplot2::aes(label = round(low_ratios, 1))) +
  ggplot2::scale_fill_gradient(low = "lightblue", high = "darkblue", limits = c(1, 6)) +
  ggplot2::xlab("STIMULUS_MAX_OCCURRENCE") +
  ggplot2::theme_light()
dev.off()


png("heatmapHigh.png", width = 800, height = 800)
ggplot2::ggplot(data = heatmapDf, mapping = ggplot2::aes(x = max_occurrence, y = adaptation_generalization, fill = high_ratios)) +
  ggplot2::geom_tile() +
  ggplot2::geom_text(ggplot2::aes(label = round(high_ratios, 1))) +
  ggplot2::scale_fill_gradient(low = "lightblue", high = "darkblue",limits = c(1, 6)) +
  ggplot2::xlab("STIMULUS_MAX_OCCURRENCE") +
  ggplot2::theme_light()
dev.off()





# confirm max occurrence = 1 plot
# data loading
path <- "../datasets/ConfirmMaxOccurenceOne/"
all_file_names <- list.files(path)
file_order <- order(parse_number(all_file_names))
all_file_names <- all_file_names[file_order]


# separate parameter files from data files
all_actions <- str_which(all_file_names, "actionPerIntensity") %>% all_file_names[.]
all_actions_data <- .read_all_datasets(path, all_actions)


#barplot with error bars
actionListVec <- lapply(all_actions_data, c, recursive=TRUE)
wideActions <- do.call(cbind, actionListVec)
rowMeans <- rowMeans(wideActions)
se <- apply(wideActions, 1, sd)/sqrt(30)

df <- vectorToDf(rowMeans, se)
plot <- ggBarPlot(df)
plot <- plot + ggplot2::ggtitle("Sum of actions per intensity")
png("maxOccurence1Confirmed.png", width = 800, height = 800)
print(plot)
dev.off()
