#!/usr/bin/env ruby

require 'dotenv/load'
Dir['./client/*.rb'].each { |file| require file }
Dir['./client/response/*.rb'].each { |file| require file }

# Een client
een_client = Client::Een.new

# Authenticate
een_client.authenticate
een_client.authorize

# Take random camera id
random_camera_id = een_client.camera_list.map(&:camera_id).sample

# Retreive 20 imaages
een_client.get_images(20, random_camera_id)
