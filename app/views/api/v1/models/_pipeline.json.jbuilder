json.id resource.id
json.name resource.name
json.description resource.description
json.icon resource.icon
json.color resource.color
json.pipeline_type resource.pipeline_type
json.position resource.position
json.settings resource.settings
json.stages resource.pipeline_stages.order(position: :asc) do |stage|
  json.id stage.id
  json.name stage.name
  json.color stage.color
  json.description stage.description
  json.position stage.position
  json.stage_type stage.stage_type
  json.conversations_count stage.conversation_pipeline_stages.count
end
json.created_at resource.created_at
json.updated_at resource.updated_at
