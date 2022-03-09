import numpy as np
import random

import gym
from gym.spaces import Discrete, Tuple, Box, Dict

'''
Tutorials on making envs
* good place to start
https://colab.research.google.com/github/araffin/rl-tutorial-jnrr19/blob/master/5_custom_gym_env.ipynb#scrollTo=rzevZcgmJmhi
* example implementation
https://towardsdatascience.com/creating-a-custom-openai-gym-environment-for-stock-trading-be532be3910e


Base class definition
https://github.com/openai/gym/blob/master/gym/core.py

Types of spaces
https://github.com/openai/gym/tree/master/gym/spaces

Tutorials with info on wrappers
* we may use a wrapper to create our perception-valuation function
https://blog.paperspace.com/getting-started-with-openai-gym/

'''


class Emotion:

    def __init__(self, id: int, emo_trajectory: list):
        self.id = id
        self.emo_trajectory = emo_trajectory
        self.size = len(self.emo_trajectory)
        self.cur_step = 0

    def step(self):
        self.cur_step += 1

    def get_intensity(self):
        return self.emo_trajectory[self.cur_step]

    def get_dict(self):
        return {'id': self.id, 'emo_trajectory': self.emo_trajectory, 'size': self.size, 'cur_step': self.cur_step}

    def reset(self):
        self.cur_step = 0


class EmotionEnv(gym.Env):

    metadata = {'render.modes': ['human']}

    N_ACTIONS = 3

    # Actions
    INACTION = 0
    DISENGAGE = 1
    ENGAGE = 2

    def __init__(self,
                 engage_delay: float,
                 engage_benefit: float,
                 disengage_benefit: float,
                 engage_adaptation: float,
                 stimuli: list,
                 ):
        super(EmotionEnv, self).__init__()

        self.action_space = Discrete(self.N_ACTIONS)
        self.observation_space = Dict({
            'stimulus_id': Discrete(len(stimuli)),
            'emo_intensity': Box(low=0, high=1, shape=(1,), dtype=np.float32),
            'emo_step:': Box(low=0, high=np.max([len(s.emo_trajectory) for s in stimuli]), shape=(1,), dtype=np.int8)
        })

        self.stimuli = stimuli

        self.n_stimuli = len(stimuli)
        self.engage_delay = engage_delay
        self.engage_benefit = engage_benefit
        self.engage_adaptation = engage_adaptation
        self.disengage_benefit = disengage_benefit

        self.current_emotion = None
        self.reset()

    def step(self, action: int) -> tuple:
        '''
        Execute one timestep in environment
        :param action: which action to take
        :return: state, reward, done, info
        '''
        # Take action
        if action == self.DISENGAGE:
            self._disengage()
        elif action == self.ENGAGE:
            self._engage()
        elif action == self.INACTION:
            self._inaction()
        else:
            raise ValueError(f'Received invalid action {action} which is not part of the action space')

        info = None

        if self._get_doneness():
            done = 1
            self.reset()
        else:
            done = 0

        return self.current_emotion.id, self._get_reward(), done, info


    def _inaction(self):
        self.current_emotion.step()
        return self.current_emotion.id

    def _disengage(self):
        self.current_emotion.step()
        trajectory = self.current_emotion.emo_trajectory
        trajectory = [x - self.disengage_benefit for x in trajectory]
        self.current_emotion.emo_trajectory = np.clip(trajectory, 0, 1)
        return self.current_emotion.id

    def _engage(self):
        self.current_emotion.step()
        trajectory = self.current_emotion.emo_trajectory
        trajectory[self.engage_delay:] = [x - self.engage_benefit for x in trajectory[self.engage_delay:]]
        self.current_emotion.emo_trajectory = np.clip(trajectory, 0, 1)

        # Agent adapts to future instances of this stimulus
        for stim in self.stimuli:
            if stim.id == self.current_emotion.id:
                stim.emo_trajectory -= self.engage_adaptation
                stim.emo_trajectory = np.clip(stim.emo_trajectory, 0, 1)

        return self.current_emotion.id

    def _get_reward(self):
        reward = -1 * self.current_emotion.get_intensity()
        return reward

    def _get_doneness(self):
        return True if self.current_emotion.cur_step >= self.current_emotion.size else False

    def reset(self):
        if self.current_emotion is not None:
            # TODO: not sure if this is necessary, is this pointing to same object when random choices are made?
            self.current_emotion.reset()
        self.current_emotion = random.choice(self.stimuli)

    def render(self, mode='human'):
        '''

        :param mode:
        :return:
        '''
        if mode == 'human':
            print(f'{self.current_emotion.get_dict()}')
        elif mode == 'log':
            return f'{self.current_emotion.get_dict()}'
        else:
            raise NotImplementedError()

