import ApiClient from './ApiClient';

class PipelinesAPI extends ApiClient {
  constructor() {
    super('pipelines', { accountScoped: true });
  }

  getStages(pipelineId) {
    return axios.get(`${this.url}/${pipelineId}/stages`);
  }

  createStage(pipelineId, data) {
    return axios.post(`${this.url}/${pipelineId}/stages`, data);
  }

  updateStage(pipelineId, stageId, data) {
    return axios.patch(`${this.url}/${pipelineId}/stages/${stageId}`, data);
  }

  deleteStage(pipelineId, stageId) {
    return axios.delete(`${this.url}/${pipelineId}/stages/${stageId}`);
  }

  getConversations(pipelineId) {
    return axios.get(`${this.url}/${pipelineId}/conversations`);
  }

  addConversation(pipelineId, data) {
    return axios.post(`${this.url}/${pipelineId}/conversations`, data);
  }

  moveConversation(pipelineId, conversationId, data) {
    return axios.patch(
      `${this.url}/${pipelineId}/conversations/${conversationId}`,
      data
    );
  }

  removeConversation(pipelineId, conversationId) {
    return axios.delete(
      `${this.url}/${pipelineId}/conversations/${conversationId}`
    );
  }
}

export default new PipelinesAPI();
