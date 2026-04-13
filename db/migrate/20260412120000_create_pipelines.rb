class CreatePipelines < ActiveRecord::Migration[7.0]
  def change
    create_table :pipelines do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.text :description
      t.string :icon
      t.string :color, default: '#1f93ff'
      t.integer :pipeline_type, default: 0, null: false
      t.jsonb :settings, default: {}
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :pipelines, [:account_id, :name], unique: true
  end
end
