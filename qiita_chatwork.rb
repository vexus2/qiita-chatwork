#!/usr/bin/env ruby
#-*- encoding: utf-8 -*-
# @see http://qiita.com/hakobera/items/6cf7844b070e8218837a

require 'qiita'
require 'pit'
require 'time'

## get config from pit
Config = Pit.get('restore_config',
  :require => {
     'qiita' => {
         'chatwork_api_key' => 'chatwork_api_key',
         'chatwork_room_id' => 'chatwork_room_id',
         'user_name' => ['user','name'],
         'team_name' => 'team_name',
         'api_token' => 'api_token',
  },
})

qiita = Qiita.new token: Config['qiita']['api_token']

Config['qiita']['user_name'].each do |user|
  items = qiita.user_items user, team_url_name: Config['qiita']['team_name']
  # 300sec
  items.select { |item| Time.parse(item.created_at) > (Time.now - 300) }.each do |item|
    body = <<-EOF
★Qiita Team新着投稿 (#{item.user.url_name}さん)
#{item.title}
#{item.url}
EOF

    uri = URI.parse("https://api.chatwork.com/v1/rooms/#{Config['qiita']['chatwork_room_id']}/messages")

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request['X-ChatWorkToken'] = Config['qiita']['chatwork_api_key']
    request.set_form_data({:body => body})

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    https.set_debug_output $stderr

    https.request(request)

  end
end

