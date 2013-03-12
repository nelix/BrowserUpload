json.array!(@uploads) do |upload|
  json.extract! upload, :filename, :url
  json.url upload_url(upload, format: :json)
end