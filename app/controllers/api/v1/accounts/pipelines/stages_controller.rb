class Api::V1::Accounts::Pipelines::StagesController < Api::V1::Accounts::BaseController
  before_action :pipeline
  before_action :stage, except: [:index, :create]
  before_action :check_authorization, with: :pipeline_policy

  def index
    @stages = @pipeline.pipeline_stages.order(position: :asc)
  end

  def create
    @stage = @pipeline.pipeline_stages.create!(stage_params)
  end

  def update
    @stage.update!(stage_params)
  end

  def destroy
    @stage.destroy!
    head :ok
  end

  private

  def pipeline
    @pipeline ||= Current.account.pipelines.find(params[:pipeline_id])
  end

  def stage
    @stage ||= @pipeline.pipeline_stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :description, :color, :position, :stage_type, settings: {})
  end

  def pipeline_policy
    @pipeline
  end

  def check_authorization(*)
    authorize(@pipeline, :update?)
  end
end
