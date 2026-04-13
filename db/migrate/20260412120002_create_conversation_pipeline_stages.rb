class CreateConversationPipelineStages < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_pipeline_stages do |t|
      t.references :conversation, null: false, index: true
      t.references :pipeline, null: false, index: true
      t.references :pipeline_stage, null: false, index: true
      t.references :account, null: false, index: true
      t.references :moved_by, null: true, index: true, foreign_key: { to_table: :users }
      t.integer :position, default: 0, null: false
      t.datetime :entered_at, null: false

      t.timestamps
    end

    add_index :conversation_pipeline_stages, :conversation_id, unique: true, name: 'idx_conv_pipeline_stages_on_conversation_unique'
    add_index :conversation_pipeline_stages, [:pipeline_id, :pipeline_stage_id], name: 'idx_conv_pipeline_stages_on_pipeline_and_stage'
  end
end
