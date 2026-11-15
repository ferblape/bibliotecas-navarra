class CreateBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmarks do |t|
      t.references :list, null: false, foreign_key: true, index: false
      t.string :record_id, null: false
      t.string :title, null: false
      t.string :author
      t.string :isbn

      t.timestamps
    end
    add_index :bookmarks, [ :list_id, :record_id ], unique: true
  end
end
