module ClaimFiles
  extend ActiveSupport::Concern


  private

  def files_data(client, export)
    files_of_interest(export).map do |f|
      json = client.upload_file_from_url(f['url'], content_type: f['content_type'], original_filename: f['filename'])
      {
        'document_type' => document_type(f),
        'document_url' => json.dig('_embedded', 'documents').first.dig('_links', 'self', 'href'),
        'document_binary_url' => json.dig('_embedded', 'documents').first.dig('_links', 'binary', 'href'),
        'document_filename' => f['filename']
      }
    end
  end

  def document_type(file)
    if application_file?(file)
      'ET1'
    elsif acas_file?(file)
      'ACAS Certificate'
    else
      'Other'
    end
  end

  def files_of_interest(export)
    export.dig('resource', 'uploaded_files').select do |file|
      file['filename'].match?(/\Aet1_.*\.pdf\z|\Aacas_.*\.pdf\z|\.rtf\z|\.csv/) &&
        !disallow_file_extensions.include?(File.extname(file['filename']))
    end
  end

  def application_file?(file)
    file['filename'].match? /\Aet1_.*\.pdf\z/
  end

  def acas_file?(file)
    file['filename'].match? /\Aacas_.*\.pdf\z/
  end

  def claimants_file?(file)
    file['filename'].match? /\Aet1a.*\.csv\z/
  end

  def additional_info_file?(file)
    file['filename'].match? /\Aet1.*\.rtf\z/
  end
end
