class Api::V1::Accounts::Pipelines::ConversationsController < Api::V1::Accounts::BaseController
  before_action :pipeline
  before_action :check_authorization

  def index
    @stages = @pipeline.pipeline_stages.order(position: :asc)
    @grouped_conversations = @stages.each_with_object({}) do |stage, hash|
      hash[stage.id] = ConversationPipelineStage
                        .where(pipeline_stage_id: stage.id, pipeline_id: @pipeline.id)
                        .includes(conversation: [:assignee, :contact, :inbox, :team])
                        .order(position: :asc)
                        .map(&:conversation)
    end
  end

  def create
    conversation = Current.account.conversations.find(params[:conversation_id])
    stage = @pipeline.pipeline_stages.find(params[:pipeline_stage_id])

    cps = ConversationPipelineStage.find_or_initialize_by(conversation: conversation)
    cps.assign_attributes(
      pipeline: @pipeline,
      pipeline_stage: stage,
      account: Current.account,
      moved_by: Current.user,
      entered_at: Time.current
    )
    cps.save!

    render json: { conversation_id: conversation.id, pipeline_stage_id: stage.id }, status: :ok
  end

  def update
    conversation = Current.account.conversations.find(params[:id])
    cps = ConversationPipelineStage.find_by!(conversation: conversation, pipeline: @pipeline)

    new_stage = @pipeline.pipeline_stages.find(params[:pipeline_stage_id])
    cps.update!(
      pipeline_stage: new_stage,
      moved_by: Current.user,
      entered_at: Time.current,
      position: params[:position] || 0
    )

    render json: { conversation_id: conversation.id, pipeline_stage_id: new_stage.id }, status: :ok
  end

  def destroy
    conversation = Current.account.conversations.find(params[:id])
    cps = ConversationPipelineStage.find_by!(conversation: conversation, pipeline: @pipeline)
    cps.destroy!

    head :ok
  end

  private

  def pipeline
    @pipeline ||= Current.account.pipelines.find(params[:pipeline_id])
  end

  def check_authorization
    authorize(@pipeline, :show?)
  end
end
