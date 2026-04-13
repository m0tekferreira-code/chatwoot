# == Schema Information
#
# Table name: pipeline_stages
#
#  id          :bigint           not null, primary key
#  pipeline_id :bigint           not null
#  account_id  :bigint           not null
#  name        :string           not null
#  color       :string           default("#1f93ff")
#  description :text
#  position    :integer          default(0), not null
#  stage_type  :integer          default("default"), not null
#  settings    :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class PipelineStage < ApplicationRecord
  belongs_to :pipeline
  belongs_to :account
  has_many :conversation_pipeline_stages, dependent: :destroy_async

  enum stage_type: { default: 0, won: 1, lost: 2 }

  validates :name, presence: true, uniqueness: { scope: :pipeline_id }
  validates :account_id, presence: true

  before_validation :set_account_from_pipeline

  def conversations
    Conversation.joins(:conversation_pipeline_stage)
                .where(conversation_pipeline_stages: { pipeline_stage_id: id })
  end

  private

  def set_account_from_pipeline
    self.account_id = pipeline&.account_id if account_id.blank?
  end
end
