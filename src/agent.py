import numpy as np
import random
from scipy.special import softmax


class QTableAgent:
    '''
    Tabular Q-learning agent
    p 131 of Sutton and Barto
    '''

    def __init__(self, n_states, n_actions, alpha, gamma, epsilon):

        self.n_states = n_states
        self.n_actions = n_actions

        # Initialize q-table randomly
        # self.qtable = np.random.rand(n_states, n_actions)

        # Initialize q-table with zeros
        self.qtable = np.zeros((n_states, n_actions))

        # Initialize q-table with ones
        # self.qtable = np.ones((n_states, n_actions))

        self.alpha = alpha
        self.gamma = gamma
        self.epsilon = epsilon

    def choose_action(self, state_id):
        # Take actions according to probabilities assigned by softmax transformed q-values
        # action = random.choices(np.arange(self.n_actions), weights=softmax(self.qtable[state_id, :]))[0]

        # Epsilon-greedy policy
        if np.random.rand(1)[0] > self.epsilon:
            action = np.argmax(self.qtable[state_id, :])
        else:
            action = np.random.randint(0, self.n_actions)
        return action

    def update(self, state_id, next_state_id, action_id, reward):
        q = self.qtable[state_id, action_id] + self.alpha * \
            (reward + self.gamma * np.max(self.qtable[next_state_id, :]) - self.qtable[state_id, action_id])
        self.qtable[state_id, action_id] = q

