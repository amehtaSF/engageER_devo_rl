import numpy as np
import random
import matplotlib.pyplot as plt
import logging
import sys

from environment import EmotionEnv, Emotion
from agent import QTableAgent

# Set up logging
logger = logging.getLogger(__name__)
stream_handler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter('%(message)s')
stream_handler.setFormatter(formatter)
logger.addHandler(stream_handler)
logger.setLevel(logging.INFO)

if __name__ == '__main__':

    N_RUNS = 1000
    N_STIMULI = int(N_RUNS/2)  # Ratio of N_RUNS/N_STIMULI determines how likely agent is to re-encounter stimuli

    # Create a set of stimuli which the agent will encounter
    stimuli = [random.choice(
        [Emotion(id=i, emo_trajectory=[.8, .8, .8]),
         Emotion(id=i, emo_trajectory=[.3, .3, .3])]
    ) for i in range(N_STIMULI)]

    # Set parameters for environment
    env = EmotionEnv(
        engage_delay=1,
        engage_benefit=.6,
        disengage_benefit=.5,
        engage_adaptation=.0,
        stimuli=stimuli
    )

    # Print actual expected value of strategies
    # TODO: engage EV calculation is wrong here
    # avg_emo_length = np.mean([len(s.emo_trajectory) for s in stimuli])
    # disengage_ev = env.disengage_benefit * avg_emo_length
    # engage_ev = env.engage_benefit * avg_emo_length + env.engage_adaptation * N_STIMULI / N_RUNS
    # logger.info(f'disengage expected value: {disengage_ev}')
    # logger.info(f'engage expected value: {engage_ev}')

    # Set parameters for agent
    agent = QTableAgent(env.n_stimuli, env.N_ACTIONS, alpha=.001, gamma=.99, epsilon=.1)

    state = env.current_emotion.id

    # Record actions and rewards
    action_counts = np.zeros((N_RUNS, agent.n_actions))
    reward_counts = np.zeros((N_RUNS, agent.n_actions))

    # Run simulation
    for i in range(N_RUNS):

        logger.debug(env.render(mode='log'))
        action = agent.choose_action(state, policy='ucb', c=.1)
        next_state, reward, done, info = env.step(action)
        agent.update(state, next_state, action, reward)
        logger.debug(f'action: {action}, reward: {reward}')
        logger.debug(env.render(mode='log'))

        action_counts[i, action] += 1
        reward_counts[i, action] += reward

    logger.info(f'actions: {np.sum(action_counts, axis=0)}')
    logger.info(f'rewards: {np.sum(reward_counts, axis=0) / np.sum(action_counts, axis=0)}')


    # Plot choices
    time = np.arange(0, N_RUNS)
    action_cumsum = np.cumsum(action_counts, axis=0)
    plt.plot(time, action_cumsum[:, 0], marker='', color='olive', linewidth=2, label='inaction')
    plt.plot(time, action_cumsum[:, 1], marker='', color='blue', linewidth=2, label='disengage')
    plt.plot(time, action_cumsum[:, 2], marker='', color='red', linewidth=2, label='engage')
    plt.legend()
    plt.show()
