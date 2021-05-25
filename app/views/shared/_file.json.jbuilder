json.set! 'id', nil
json.set! 'value' do
  json.set! 'typeOfDocument', file['document_type']
  json.set! 'uploadedDocument' do
    json.set! 'document_url', file['document_url']
    json.set! 'document_binary_url', file['document_binary_url']
    json.set! 'document_filename', file['document_filename']
  end
end
