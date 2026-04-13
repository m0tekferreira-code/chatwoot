# == Schema Information
#
# Table name: pipelines
#
#  id            :bigint           not null, primary key
#  account_id    :bigint           not null
#  name          :string           not null
#  description   :text
#  icon          :string
#  color         :string           default("#1f93ff")
#  pipeline_type :integer          default("conversation"), not null
#  settings      :jsonb
#  position      :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Pipeline < ApplicationRecord
  belongs_to :account
  has_many :pipeline_stages, -> { order(position: :asc) }, dependent: :destroy_async
  has_many :conversation_pipeline_stages, dependent: :destroy_async

  enum pipeline_type: { conversation: 0 }

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :account_id, presence: true

  def conversations
    Conversation.joins(:conversation_pipeline_stage)
                .where(conversation_pipeline_stages: { pipeline_id: id })
  end
end
