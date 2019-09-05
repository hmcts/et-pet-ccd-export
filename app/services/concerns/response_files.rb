module ResponseFiles
  extend ActiveSupport::Concern


  private

  def files_data(client, export)
    files_of_interest(export).map do |f|
      json = client.upload_file_from_url(f['url'], content_type: f['content_type'], original_filename: f['filename'])
      {
        'id' => nil,
        'value' => {
          'typeOfDocument' => 'ET3',
          'shortDescription' => short_description_for(f, export: export),
          'uploadedDocument' => {
            'document_url' => json.dig('_embedded', 'documents').first.dig('_links', 'self', 'href'),
            'document_binary_url' => json.dig('_embedded', 'documents').first.dig('_links', 'binary', 'href'),
            'document_filename' => f['filename']
          }
        }
      }
    end
  end

  def files_of_interest(export)
    export.dig('resource', 'uploaded_files').select do |file|
      file['filename'].match?(/\Aet3_.*\.pdf\z|\.rtf\z/) &&
        !disallow_file_extensions.include?(File.extname(file['filename']))
    end
  end

  def response_file?(file)
    file['filename'].match? /\Aet3_.*\.pdf\z/
  end

  def additional_info_file?(file)
    file['filename'].match? /\Aet1.*\.rtf\z/
  end

  def short_description_for(file, export:)
    respondent = export.dig('resource', 'respondent')
    if response_file?(file)
      "ET3 response from #{respondent['name']}"
    elsif additional_info_file?(file)
      "ET3 Additional information file from #{respondent['name']}"
    else
      "Unknown"
    end
  end

end
