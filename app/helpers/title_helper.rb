module TitleHelper
  VALID_TITLES = ['Mr', 'Mrs', 'Miss', 'Ms'].freeze
  def handle_other_titles(title)
    return title if title.nil? || title.in?(VALID_TITLES)

    'Other'
  end
end
