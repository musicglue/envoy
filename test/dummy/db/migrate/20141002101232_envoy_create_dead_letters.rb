class EnvoyCreateDeadLetters < ActiveRecord::Migration
  def change
    create_table :dead_letters, id: :uuid do |t|
      t.timestamps

      t.uuid :docket_id, null: false
      t.json :message, null: false

      t.index :docket_id
    end
  end
end
