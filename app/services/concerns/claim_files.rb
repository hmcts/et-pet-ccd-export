module ClaimFiles
  extend ActiveSupport::Concern


  private

  def files_data(client, export)
    files_of_interest(export).map do |f|
      json = client.upload_file_from_url(f['url'], content_type: f['content_type'], original_filename: f['filename'])
      {
        'document_type' => application_file?(f) ? 'Application' : 'Other',
        'short_description' => short_description_for(f, export: export),
        'document_url' => json.dig('_embedded', 'documents').first.dig('_links', 'self', 'href'),
        'document_binary_url' => json.dig('_embedded', 'documents').first.dig('_links', 'binary', 'href'),
        'document_filename' => f['filename']
      }
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

  def short_description_for(file, export:)
    claimant = export.dig('resource', 'primary_claimant')
    respondent = export.dig('resource', 'primary_respondent')
    if application_file?(file)
      "ET1 application for #{claimant['first_name']} #{claimant['last_name']}"
    elsif claimants_file?(file)
      "Additional claimants file for #{claimant['first_name']} #{claimant['last_name']}"
    elsif additional_info_file?(file)
      "Additional information file for #{claimant['first_name']} #{claimant['last_name']}"
    elsif acas_file?(file)
      "ACAS certificate for #{respondent['name']}"
    else
      "Unknown"
    end
  end

end
