create_table :cia_events do |t|
  t.integer :actor_id
  t.string :actor_type
  t.string :source_type, :action, :null => false
  t.integer :source_id, :null => false
  t.string :ip_address
  t.string :message
  t.timestamp :created_at#, :null => false
end

create_table :cia_attribute_changes do |t|
  t.integer :cia_event_id, :source_id, :null => false
  t.string :attribute_name, :source_type, :null => false
  t.string :old_value, :new_value
end

# DOWN
# drop_table :cia_events
# drop_table :cia_attribute_changes
