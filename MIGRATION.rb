create_table :audit_transactions do |t|
  t.integer :actor_id, :null => false
  t.string :actor_type, :null => false
  t.string :ip_address
  t.timestamp :created_at
end

create_table :audit_events do |t|
  t.string :type, :source_type, :null => false
  t.integer :audit_transaction_id, :source_id, :null => false
  t.string :message
  t.timestamp :created_at
end

create_table :audit_attribute_changes do |t|
  t.integer :audit_event_id, :source_id, :null => false
  t.string :attribute_name, :source_type, :null => false
  t.string :old_value, :new_value
end

# DOWN
# drop_table :audit_transactions
# drop_table :audit_events
# drop_table :audit_attribute_changes
