require 'sinatra'
require 'sass'
require 'haml'
require 'sprockets'
require 'compass'
require 'sprockets-sass'
require 'bootstrap-sass'
require 'coffee-script'

require './setup'

map '/assets' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets/javascripts'
  environment.append_path 'assets/stylesheets'
  environment.append_path 'assets/images'
  environment.append_path Compass::Frameworks['bootstrap'].templates_directory + '/../vendor/assets/javascripts'
  environment.append_path Compass::Frameworks['bootstrap'].templates_directory + '/../vendor/assets/images'

  environment.context_class.class_eval do
    def asset_path(path, options={})
      "/assets/#{path}"
    end
  end

  run environment
end

get '/' do
  @pattern = Hospice::Pattern.all.select{|p| p.name == params[:pattern]}.first if params[:pattern]

  @configuration   = @pattern.try(:configuration)
  @configuration ||= Hospice::Builder.find(params[:id].try(:strip)).try(:configuration)
  @configuration ||= {}
  haml :index
end

get '/:id' do
  send_file Hospice::Builder.find(params[:id]).zip, disposition: :attachment, filename: 'hospice.zip'
end

post '/' do
  if !params['packages']
    redirect '/'
    return
  end

  configuration = {}

  params['packages'].each do |package, _|
    configuration[package] = {}

    if params['selects'] && params['selects'][package]
      params['selects'][package].each do |_, option|
        configuration[package][option] = true
      end
    end

    if params['options'] && params['options'][package]
      params['options'][package].each do |option, value|
        configuration[package][option] = value.blank? ? true : value
      end
    end
  end

  builder = Hospice::Builder.new(configuration)
  builder.save
end

run Sinatra::Application