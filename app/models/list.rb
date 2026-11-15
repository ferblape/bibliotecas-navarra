# An anonymous list of bookmarked records. Its secret token in the URL is the only way
# to reach it: whoever knows the URL can see and change the list.
class List < ApplicationRecord
  has_secure_token
  has_many :bookmarks, -> { order(created_at: :desc) }, dependent: :destroy

  def to_param
    token
  end

  def bookmark(record)
    bookmarks.create_with(title: record.title, author: record.author, isbn: record.isbn).find_or_create_by!(record_id: record.id)
  end

  def bookmarked?(record_id)
    bookmarks.exists?(record_id:)
  end
end
