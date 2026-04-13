class Api::V1::Accounts::PipelinesController < Api::V1::Accounts::BaseController
  before_action :pipeline, except: [:index, :create]
  before_action :check_authorization

  def index
    @pipelines = Current.account.pipelines.includes(:pipeline_stages).order(position: :asc)
  end

  def show; end

  def create
    @pipeline = Current.account.pipelines.create!(pipeline_params)
  end

  def update
    @pipeline.update!(pipeline_params)
  end

  def destroy
    @pipeline.destroy!
    head :ok
  end

  private

  def pipeline
    @pipeline ||= Current.account.pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :description, :icon, :color, :position, settings: {})
  end
end
