# Keep development device subscriptions valid across server and worker restarts.
# Production must supply its own VAPID environment variables.
if Rails.env.development? && ENV["VAPID_PUBLIC_KEY"].blank? && ENV["VAPID_PRIVATE_KEY"].blank?
  path = Rails.root.join("storage/development_vapid.json")
  File.open(path, File::RDWR | File::CREAT, 0o600) do |file|
    file.flock(File::LOCK_EX)
    contents = file.read
    if contents.empty?
      key = WebPush.generate_key
      contents = JSON.generate(public_key: key.public_key, private_key: key.private_key)
      file.write(contents)
      file.flush
    end
    keys = JSON.parse(contents)
    ENV["VAPID_PUBLIC_KEY"] = keys.fetch("public_key")
    ENV["VAPID_PRIVATE_KEY"] = keys.fetch("private_key")
  end
end
