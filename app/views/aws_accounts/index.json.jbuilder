json.array!(@aws_accounts) do |aws_account|
  json.extract! aws_account, :id, :name, :aws_access_key_id, :aws_secret_access_key, :admin_password
  json.url aws_account_url(aws_account, format: :json)
end
