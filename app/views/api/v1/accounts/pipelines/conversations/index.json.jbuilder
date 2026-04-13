json.pipeline do
  json.id @pipeline.id
  json.name @pipeline.name
end
json.stages @stages do |stage|
  json.id stage.id
  json.name stage.name
  json.color stage.color
  json.position stage.position
  json.stage_type stage.stage_type
  json.conversations @grouped_conversations[stage.id] do |conversation|
    json.id conversation.display_id
    json.uuid conversation.uuid
    json.status conversation.status
    json.priority conversation.priority
    json.created_at conversation.created_at.to_i
    json.last_activity_at conversation.last_activity_at.to_i
    json.contact do
      json.id conversation.contact.id
      json.name conversation.contact.name
      json.email conversation.contact.email
      json.phone_number conversation.contact.phone_number
      json.thumbnail conversation.contact.avatar_url
    end
    json.inbox do
      json.id conversation.inbox.id
      json.name conversation.inbox.name
      json.channel_type conversation.inbox.channel_type
    end
    json.assignee do
      if conversation.assignee.present?
        json.id conversation.assignee.id
        json.name conversation.assignee.name
        json.thumbnail conversation.assignee.avatar_url
      end
    end
    json.team do
      if conversation.team.present?
        json.id conversation.team.id
        json.name conversation.team.name
      end
    end
    json.labels conversation.cached_label_list_array
  end
end
