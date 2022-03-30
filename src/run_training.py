import os
import numpy as np
import random
import matplotlib.pyplot as plt
import pandas as pd
import path
import os

from environment import Stimulus, AgentStatus, EmotionEnv
from agent import QTableAgent

simulationValues = [1] # a vector of values that the parameter you want to change should take.
                            # For no simulations, set to [1] and set all paramter values yourself

#file_name = "engage_adaptation"      # the first part of the file name, automatically appended with the respective simulation value and data description
# DONT USE NUMBERS IN FILE NAME

#folder_path = "../datasets/" + file_name   # where to save the data
#os.makedirs(folder_path)     # create a folder

for sv in simulationValues:


    # parameter list; to run simulations, change the desired parameter to "sv"
    SEED = 123
    N_RUNS = 1000
    N_STIMULI = 200
    N_ACTIONS = 3

    alpha = .001
    gamma = .99
    epsilon = .1

    engage_benefit = 3
    disengage_benefit = 5
    engage_adaptation = 2

    random.seed(SEED)
    np.random.seed(SEED)

    # p_recurrence does not do anything at the moment
    stimuli_list = []
    for i in range(N_STIMULI):
        id = i
        emo_intensity = np.random.randint(1, 11)
        p_recurrence = np.random.randint(0, 11)
        stimuli_list.append(Stimulus(id=id, emo_intensity=emo_intensity, p_recurrence=p_recurrence))

    agent_status = AgentStatus()

    env = EmotionEnv(engage_benefit=engage_benefit,
                     disengage_benefit=disengage_benefit,
                     engage_adaptation=engage_adaptation,
                     stimuli=stimuli_list,
                     agent_status=agent_status
                     )
    env.reset()



    agent = QTableAgent(env.n_stimuli, n_actions=N_ACTIONS, alpha=alpha, gamma=gamma, epsilon=epsilon)


    action = 0 # the first action

    # Record actions and rewards
    action_counts = np.zeros((N_RUNS, agent.n_actions))
    reward_counts = np.zeros((N_RUNS, agent.n_actions))

    # Run simulation
    for i in range(N_RUNS):
        state = agent_status.current_id
        next_state, reward, done, info = env.step(action)
        agent.update(state, next_state, action, reward)
        print(f'action: {action}, reward: {reward}, step: {i}')
        env.render()
        action_counts[i, action] += 1
        reward_counts[i, action] += reward
        if done:
            action = agent.choose_action(state, policy="epsilon_greedy")



    #create data for running the same stimulus 3 times with every action
    intensity_values = np.zeros((4, N_ACTIONS))
    stimuli_list2 = [Stimulus(id=N_STIMULI + 1, emo_intensity=8, p_recurrence=5)]
    agent_status2 = AgentStatus()
    env2 = EmotionEnv(engage_benefit=engage_benefit,
                      disengage_benefit=disengage_benefit,
                      engage_adaptation=engage_adaptation,
                      stimuli=stimuli_list2,
                      agent_status=agent_status2
                      )
    env2.reset()
    state = agent_status2.current_id
    for ac in [0, 1, 2]:
        action = ac
        for i in np.arange(0, 4, 1):
            next_state, reward, done, info = env2.step(action)
            print(f'action: {action}, reward: {reward}, step: {i}')
            intensity_values[i, ac] = 10 - reward
            env2.render()


    #plot the emotional intensity curve per action
    time = np.arange(0, 4)
    plt.plot(time, intensity_values[:, 0], marker='', color='olive', linewidth=2, label='inaction')
    plt.plot(time, intensity_values[:, 1], marker='', color='blue', linewidth=2, label='disengage')
    plt.plot(time, intensity_values[:, 2], marker='', color='red', linewidth=2, label='engage')
    plt.legend()
    plt.show()

    # Plot choices
    time = np.arange(0, N_RUNS)
    action_cumsum = np.cumsum(action_counts, axis=0)
    plt.plot(time, action_cumsum[:, 0], marker='', color='olive', linewidth=2, label='inaction')
    plt.plot(time, action_cumsum[:, 1], marker='', color='blue', linewidth=2, label='disengage')
    plt.plot(time, action_cumsum[:, 2], marker='', color='red', linewidth=2, label='engage')
    plt.legend()
    plt.show()


    # plot rewards
    inaction_timeline = np.cumsum(reward_counts[:, 0] != 0) + 1
    disengage_timeline = np.cumsum(reward_counts[:, 1] != 0) + 1
    engage_timeline = np.cumsum(reward_counts[:, 2] != 0) + 1
    reward_cumsum = np.cumsum(reward_counts, axis=0)
    reward_cumsum[:, 0] / np.arange(1, N_RUNS + 1, 1)
    plt.plot(time, reward_cumsum[:, 0]/inaction_timeline, marker='', color='olive', linewidth=2, label='inaction')
    plt.plot(time, reward_cumsum[:, 1]/disengage_timeline, marker='', color='blue', linewidth=2, label='disengage')
    plt.plot(time, reward_cumsum[:, 2]/engage_timeline, marker='', color='red', linewidth=2, label='engage')
    plt.legend()
    plt.show()

    # #set options for pandas
    # pd.set_option('display.max_columns', None)
    # pd.set_option('display.width', None)
    # pd.set_option('display.max_colwidth', None)
    #
    # #to write the actions to csv
    # df1 = pd.DataFrame({'inaction': action_cumsum[:, 0], 'disengage': action_cumsum[:, 1], 'engage': action_cumsum[:, 2]})
    # file_name1 = folder_path + '/' + file_name + '_' + str(sv) + '_actionCumSum' '.csv'
    # df1.to_csv(file_name1)
    #
    #
    # #To write the rewards to csv
    # df2 = pd.DataFrame({'inaction': reward_cumsum[:, 0]/inaction_timeline, 'disengage': reward_cumsum[:, 1]/disengage_timeline,
    #                     'engage': reward_cumsum[:, 2]/engage_timeline})
    # file_name2 = folder_path + '/' + file_name + '_' + str(sv) + '_RewardsCumMean' '.csv'
    # df2.to_csv(file_name2)
    #
    #
    # #To write action trajectory to csv
    # df3 = pd.DataFrame({'inaction': intensity_values[:, 0], 'disengage': intensity_values[:, 1], 'engage': intensity_values[:, 2]})
    # file_name3 = folder_path + '/' + file_name + '_' + str(sv) + '_actionTrajectory' '.csv'
    # df3.to_csv(file_name3)
