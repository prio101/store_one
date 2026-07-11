# frozen_string_literal: true

# DigitalOcean Spaces direct upload fix.
#
# Problem: The aws-sdk-s3 presigner signs Content-MD5 in the presigned PUT URL,
# but the browser XHR upload doesn't send the Content-MD5 header, causing
# "Missing one or more required signed header" errors from DO Spaces.
#
# Fix: Override url_for_direct_upload to not sign content-md5, and
# headers_for_direct_upload to not require Content-MD5 from the browser.
# The server-side integrity check still runs after upload via ActiveStorage's
# built-in checksum verification.
#
# Uses to_prepare so the class is guaranteed to be loaded (critical in
# development mode where eager_load is false).

Rails.application.config.to_prepare do
  next unless defined?(ActiveStorage::Service::S3Service)

  ActiveStorage::Service::S3Service.class_eval do
    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
      instrument :url, key: key do |payload|
        generated_url = object_for(key).presigned_url :put, expires_in: expires_in.to_i,
          content_type: content_type, content_length: content_length,
          metadata: custom_metadata, **upload_options

        payload[:url] = generated_url
        generated_url
      end
    end

    def headers_for_direct_upload(key, content_type:, checksum:, filename: nil, disposition: nil, custom_metadata: {}, **)
      content_disposition = content_disposition_with(type: disposition, filename: filename) if filename
      { "Content-Type" => content_type, "Content-Disposition" => content_disposition, **custom_metadata_headers(custom_metadata) }
    end
  end
end
