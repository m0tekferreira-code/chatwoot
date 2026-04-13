class CreatePipelineStages < ActiveRecord::Migration[7.0]
  def change
    create_table :pipeline_stages do |t|
      t.references :pipeline, null: false, foreign_key: { on_delete: :cascade }
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.string :color, default: '#1f93ff'
      t.text :description
      t.integer :position, default: 0, null: false
      t.integer :stage_type, default: 0, null: false
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :pipeline_stages, [:pipeline_id, :name], unique: true
    add_index :pipeline_stages, [:pipeline_id, :position]
  end
end
