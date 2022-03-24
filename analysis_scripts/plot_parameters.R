# FUNCTIONS
.read_all_datasets <- function(file_path, file_numbers){
  all_datasets <- list()
  for (i in 1:length(file_numbers)) {
    file_name <- paste(file_path, file_numbers[i] , ".csv", sep = "")
    dataset <- as.data.frame(read.csv(file_name))
    dataset <- .reshape_wrapper(dataset)
    all_datasets[[i]] <- dataset
  }
  return(all_datasets)
}

.reshape_wrapper <- function(dataset) {
  dataset <- tidyr::gather(dataset, action, cumSum, inaction:engange, factor_key = TRUE)
  return(dataset)
}

.cum_sum_lineplots <- function(data_list, parameter){
  parameter_name <- deparse(substitute(parameter))
  for (i in 1:length(data_list)) {
    dataset <- data_list[[i]]
    plot_file_name <- paste(parameter_name, "_", parameter[i], ".png", sep = "")
    title <- paste(parameter_name, "=", parameter[i], sep = "")
    png(plot_file_name)
    plot <- .gg_line_plot(dataset, title)
    print(plot)
    dev.off()
  }
}


.gg_line_plot <- function(dataset, title) {
  plot <-  ggplot2::ggplot() +
    ggplot2::geom_line(data = dataset, mapping = ggplot2::aes(x = X, y = cumSum, group = action, color = action), size = 1) +
    ggplot2::xlab("Time in runs") +
    ggplot2::ylab("Cum. Sum") +
    ggplot2::ggtitle(title) +
    ggplot2::theme_light()
  return(plot)
}


#N_RUNS

N_RUNS <- seq(1000, 8000, 1000)
path <- "../datasets/N_RUNS/N_RUNS"
all_N_RUNS <- .read_all_datasets(path, N_RUNS)
.cum_sum_lineplots(all_N_RUNS, N_RUNS)

#N_STIMULI
N_STIMULI <- seq(1000, 8000, 1000)
path <- "../datasets/N_STIMULI/N_STIMULI"

all_N_STIMULI <- .read_all_datasets(path, N_STIMULI)
.cum_sum_lineplots(all_N_STIMULI, N_STIMULI)


#Seed
seed <- 1:8
path <- "../datasets/Seed/Seed"

all_N_STIMULI <- .read_all_datasets(path, seed)
.cum_sum_lineplots(all_N_STIMULI, seed)





#engage_adaptation
engage_adapt <- seq(0, .8, .1)
path <- "../datasets/engage_adaptation/engage_adaptation_"

all_engage_adapt <- .read_all_datasets(path, engage_adapt)
.cum_sum_lineplots(all_engage_adapt, engage_adapt)




#no  disengage benefits 
no_benefits <- ""
path <- "../datasets/remove_benefits/no_disengage_benefit"
data_list <- .read_all_datasets(file_path = path, file_numbers = no_benefits)
.cum_sum_lineplots(data_list, no_benefits)


#no engage benefits
no_benefits <- ""
path <- "../datasets/remove_benefits/no_engage_benefit"
data_list <- .read_all_datasets(file_path = path, file_numbers = no_benefits)
.cum_sum_lineplots(data_list, no_benefits)

#plotting rewards
pdf("Rewards.pdf")
standard_action <- read.csv("../datasets/plot rewards/standard_settings_actions.csv") %>% .reshape_wrapper()
.gg_line_plot(standard_action, "Standard settings - actions")
standard_reward <- read.csv("../datasets/plot rewards/standard_settings_rewards.csv") %>% .reshape_wrapper()
.gg_line_plot(standard_reward, "Standard settings - rewards")
no_disengage_action <- read.csv("../datasets/plot rewards/no_disengage_benefit_actions.csv") %>% .reshape_wrapper()
.gg_line_plot(no_disengage_action, "No disengage benefit - actions")
no_disengage_reward <- read.csv("../datasets/plot rewards/no_disengage_benefit_rewards.csv") %>% .reshape_wrapper()
.gg_line_plot(no_disengage_reward, "No disengage benefit - rewards")
no_engage_action <- read.csv("../datasets/plot rewards/no_engage_benefit_actions.csv") %>% .reshape_wrapper()
.gg_line_plot(no_engage_action, "No engage benefit - actions")
no_engage_reward <- read.csv("../datasets/plot rewards/no_engage_benefit_rewards.csv") %>% .reshape_wrapper()
.gg_line_plot(no_engage_reward, "No engage benefit - rewards")
no_engage_high_adapt_actions <- read.csv("../datasets/plot rewards/no_engage_benefit_high_adapt_actions.csv") %>% .reshape_wrapper()
.gg_line_plot(no_engage_high_adapt_actions, "No engage benefit, high adaptation - actions")
no_engage_high_adapt_rewards <- read.csv("../datasets/plot rewards/no_engage_benefit_high_adapt_rewards.csv") %>% .reshape_wrapper()
.gg_line_plot(no_engage_high_adapt_rewards, "No engage benefit, high adaptation - rewards")
dev.off()


#plotting rewards and actions with high intensity stimuli
high_intensity_actions <- read.csv("../datasets/high_intensity_stimuli/high_stimuli_intensity_actions.csv") %>% .reshape_wrapper()
.gg_line_plot(high_intensity_actions, "High intensity stimuli - actions")
high_intensity_rewards <- read.csv("../datasets/high_intensity_stimuli/high_stimuli_intensity_rewards.csv") %>% .reshape_wrapper()
.gg_line_plot(high_intensity_rewards, "High intensity stimuli - rewards")


#plotting forced engagement
forced_engage_actions <- read.csv("../datasets/forced/forced_engage_actions.csv") %>% .reshape_wrapper()
.gg_line_plot(forced_engage_actions, "Forced engage - actions")
forced_engage_rewards <- read.csv("../datasets/forced/forced_engage_rewards.csv") %>% .reshape_wrapper()
.gg_line_plot(forced_engage_rewards, "Forced engage - rewards")
