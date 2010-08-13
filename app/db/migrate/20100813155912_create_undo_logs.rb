class CreateUndoLogs < ActiveRecord::Migration
  def self.up
    create_table :undo_logs do |t|
      t.string :identifier
      
      t.string :undoable_type
      t.integer :undoable_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :undo_logs
  end
end
