# == Schema Information
#
# Table name: conversation_pipeline_stages
#
#  id                :bigint           not null, primary key
#  conversation_id   :bigint           not null
#  pipeline_id       :bigint           not null
#  pipeline_stage_id :bigint           not null
#  account_id        :bigint           not null
#  moved_by_id       :bigint
#  position          :integer          default(0), not null
#  entered_at        :datetime         not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class ConversationPipelineStage < ApplicationRecord
  belongs_to :conversation
  belongs_to :pipeline
  belongs_to :pipeline_stage
  belongs_to :account
  belongs_to :moved_by, class_name: 'User', optional: true

  validates :conversation_id, uniqueness: true
  validates :account_id, presence: true

  before_validation :set_entered_at, on: :create
  before_validation :set_account_from_pipeline

  private

  def set_entered_at
    self.entered_at ||= Time.current
  end

  def set_account_from_pipeline
    self.account_id = pipeline&.account_id if account_id.blank?
  end
end
