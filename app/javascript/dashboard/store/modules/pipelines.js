import types from '../mutation-types';
import PipelinesAPI from '../../api/pipelines';

export const state = {
  records: [],
  currentPipeline: null,
  boardData: { stages: [] },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isFetchingConversations: false,
    isMovingConversation: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getPipelines(_state) {
    return _state.records;
  },
  getCurrentPipeline(_state) {
    return _state.currentPipeline;
  },
  getBoardData(_state) {
    return _state.boardData;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_PIPELINE_UI_FLAG, { isFetching: true });
    try {
      const response = await PipelinesAPI.get();
      commit(types.SET_PIPELINES, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_PIPELINE_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, pipelineObj) => {
    commit(types.SET_PIPELINE_UI_FLAG, { isCreating: true });
    try {
      const response = await PipelinesAPI.create(pipelineObj);
      commit(types.ADD_PIPELINE, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PIPELINE_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_PIPELINE_UI_FLAG, { isUpdating: true });
    try {
      const response = await PipelinesAPI.update(id, updateObj);
      commit(types.EDIT_PIPELINE, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PIPELINE_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_PIPELINE_UI_FLAG, { isDeleting: true });
    try {
      await PipelinesAPI.delete(id);
      commit(types.DELETE_PIPELINE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PIPELINE_UI_FLAG, { isDeleting: false });
    }
  },

  setCurrentPipeline: ({ commit }, pipeline) => {
    commit(types.SET_CURRENT_PIPELINE, pipeline);
  },

  fetchBoardData: async ({ commit }, pipelineId) => {
    commit(types.SET_PIPELINE_UI_FLAG, { isFetchingConversations: true });
    try {
      const response = await PipelinesAPI.getConversations(pipelineId);
      commit(types.SET_PIPELINE_CONVERSATIONS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_PIPELINE_UI_FLAG, { isFetchingConversations: false });
    }
  },

  addConversation: async (_, { pipelineId, conversationId, stageId }) => {
    await PipelinesAPI.addConversation(pipelineId, {
      conversation_id: conversationId,
      pipeline_stage_id: stageId,
    });
  },

  moveConversation: async (
    { commit },
    { pipelineId, conversationId, stageId, position }
  ) => {
    commit(types.SET_PIPELINE_UI_FLAG, { isMovingConversation: true });
    try {
      commit(types.UPDATE_PIPELINE_CONVERSATION_STAGE, {
        conversationId,
        stageId,
        position,
      });
      await PipelinesAPI.moveConversation(pipelineId, conversationId, {
        pipeline_stage_id: stageId,
        position,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PIPELINE_UI_FLAG, { isMovingConversation: false });
    }
  },

  removeConversation: async (_, { pipelineId, conversationId }) => {
    await PipelinesAPI.removeConversation(pipelineId, conversationId);
  },

  createStage: async (_, { pipelineId, stageObj }) => {
    const response = await PipelinesAPI.createStage(pipelineId, stageObj);
    return response.data;
  },

  updateStage: async (_, { pipelineId, stageId, stageObj }) => {
    const response = await PipelinesAPI.updateStage(
      pipelineId,
      stageId,
      stageObj
    );
    return response.data;
  },

  deleteStage: async (_, { pipelineId, stageId }) => {
    await PipelinesAPI.deleteStage(pipelineId, stageId);
  },
};

export const mutations = {
  [types.SET_PIPELINE_UI_FLAG](_state, data) {
    _state.uiFlags = { ..._state.uiFlags, ...data };
  },

  [types.SET_PIPELINES](_state, data) {
    _state.records = data;
  },

  [types.ADD_PIPELINE](_state, data) {
    _state.records.push(data);
  },

  [types.EDIT_PIPELINE](_state, data) {
    const index = _state.records.findIndex(r => r.id === data.id);
    if (index !== -1) {
      _state.records[index] = { ..._state.records[index], ...data };
    }
  },

  [types.DELETE_PIPELINE](_state, id) {
    _state.records = _state.records.filter(r => r.id !== id);
  },

  [types.SET_CURRENT_PIPELINE](_state, data) {
    _state.currentPipeline = data;
  },

  [types.SET_PIPELINE_CONVERSATIONS](_state, data) {
    _state.boardData = data;
  },

  [types.UPDATE_PIPELINE_CONVERSATION_STAGE](
    _state,
    { conversationId, stageId }
  ) {
    if (!_state.boardData.stages) return;

    let movedConversation = null;

    _state.boardData.stages.forEach(stage => {
      const idx = stage.conversations.findIndex(c => c.id === conversationId);
      if (idx !== -1) {
        movedConversation = stage.conversations.splice(idx, 1)[0];
      }
    });

    if (movedConversation) {
      const targetStage = _state.boardData.stages.find(s => s.id === stageId);
      if (targetStage) {
        targetStage.conversations.push(movedConversation);
      }
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
