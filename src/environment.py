import numpy as np
import random
import copy

import gym
from gym.spaces import Discrete, Tuple, Box, Dict

class Stimulus:

    def __init__(self, id: int, emo_intensity: int, p_recurrence: float):
        self.id = id
        self.emo_intensity = emo_intensity
        self.p_recurrence = p_recurrence
        self.reappraised = False

    def get_intensity(self):
        return self.emo_intensity

    def get_dict(self):
        return {'id': self.id, 'emo_intensity': self.emo_intensity, "p_recurrence": self.p_recurrence, 'reappraised': self.reappraised}



class AgentStatus:

    def __init__(self):
        self.stimuliAppraisals = list()
        self.current_id = None
        self.current_emo_intensity = None
        self.expected_p_recurrence = None
        #self.previous_encounter = None

    def print_list(self):
        for i in range(len(self.stimuliAppraisals)):
            print(self.stimuliAppraisals[i].get_dict())

    def appraise_stimuli(self, stimulus: Stimulus):  # currently the appraisal function is 1:1, so just a copy
        if not self._check_for_previous_encounter(stimulus):
            self.stimuliAppraisals.append(copy.deepcopy(stimulus))
        self._update_emotional_state(stimulus)

    def _check_for_previous_encounter(self, stimulus):
        for i in range(0, len(self.stimuliAppraisals)):
            if self.stimuliAppraisals[i].id == stimulus.id:
                return True
        return False

    def _update_emotional_state(self, stimulus):
        for i in range(0, len(self.stimuliAppraisals)):
            if self.stimuliAppraisals[i].id == stimulus.id:
                self.current_emo_intensity = self.stimuliAppraisals[i].emo_intensity
                self.expected_p_recurrence = self.stimuliAppraisals[i].p_recurrence
                self.current_id = self.stimuliAppraisals[i].id






class EmotionEnv(gym.Env):
    metadata = {'render.modes': ['human']}

    N_ACTIONS = 3

    # # Actions
    # INACTION = 0
    # DISENGAGE = 1
    # ENGAGE = 2

    def __init__(self,
                 engage_benefit: float,
                 disengage_benefit: float,
                 engage_adaptation: float,
                 stimuli: list,
                 agent_status: AgentStatus
                 ):

        super(EmotionEnv, self).__init__()

        self.action_space = Discrete(self.N_ACTIONS)
        self.observation_space = Dict({'stimulus_id': Discrete(len(stimuli)),
        'emo_intensity': Box(low=0, high=10, shape=(1,), dtype=np.float32),
        'emo_step:': Box(low=0, high=2, shape=(1,), dtype=np.int8)})

        self.stimuli = stimuli
        self.n_stimuli = len(stimuli)
        self.engage_benefit = engage_benefit
        self.engage_adaptation = engage_adaptation
        self.disengage_benefit = disengage_benefit
        self.agent_status = agent_status
        self.current_appraisal = None
        self.current_timepoint = 1

    def step(self, action: int) -> tuple:
        '''
        Execute one timestep in environment
        :param action: which action to take
        :return: state, reward, done, info
        '''


        if self.current_timepoint == 10:
            done = True
            self.reset()
        else:
            done = False
            # Take action
            if action == 1:
                self._disengage()
            elif action == 2:
                self._engage()
            elif action == 0:
                self._inaction()
            else:
                raise ValueError(f'Received invalid action {action} which is not part of the action space')
            self.current_timepoint += 1

        info = None
        reward = self._get_reward()

        return self.agent_status.current_id, reward, done, info

    def _inaction(self):
        return self.agent_status

    def _disengage(self):
        if self.current_timepoint != 0:
            self.agent_status.current_emo_intensity -= self.disengage_benefit
        self.agent_status.current_emo_intensity = np.clip(self.agent_status.current_emo_intensity, 0, 10)
        return self.agent_status

    def _engage(self):
        for i in range(0, len(self.agent_status.stimuliAppraisals)):
            if self.agent_status.stimuliAppraisals[i].id == self.agent_status.current_id:
                self.current_appraisal = self.agent_status.stimuliAppraisals[i]
        if self.current_appraisal.emo_intensity == self.current_timepoint:
            self.current_appraisal.emo_intensity -= self.engage_adaptation
            self.agent_status.current_emo_intensity -= self.engage_adaptation
            #self.current_appraisal.reappraised = True
        self.agent_status.current_emo_intensity = np.clip(self.agent_status.current_emo_intensity, 0, 10)
        return self.agent_status

    def _get_reward(self):
        reward = 10 - self.agent_status.current_emo_intensity
        return reward

    def reset(self):
        self.current_timepoint = 1
        new_stimulus = random.choice(self.stimuli)
        self.agent_status.appraise_stimuli(new_stimulus)


    def get_original_intensity(self, stimulus_id):
        for i in range(0, len(self.stimuli)):
            if self.stimuli[i].id == stimulus_id:
                return self.stimuli[i].emo_intensity

    def render(self, mode='human'):
        '''

        :param mode:
        :return:
        '''
        if mode != 'human':
            raise NotImplementedError()
        for i in range(0, len(self.agent_status.stimuliAppraisals)):
            if self.agent_status.stimuliAppraisals[i].id == self.agent_status.current_id:
                self.current_appraisal = self.agent_status.stimuliAppraisals[i]

        print({'timepoint': self.current_timepoint, 'emo_intensity': self.agent_status.current_emo_intensity,
               'stimulus id': self.agent_status.current_id})
        print(self.current_appraisal.get_dict())
