# Fast locale is light weight localization converter.
# Contact gp.anthony@gmail.com


#!/usr/bin/env ruby
require 'csv'
require 'fileutils'
require_relative 'xlsx_to_csv.rb'

xlsx_to_csv("StringLocalization.xlsx" ,".StringLocalizationParsed.csv")

class Value
  attr_accessor :key  , :value

  def value_android
    value.gsub(/[']/, "\'")
  end

end

class Language
  attr_accessor :name, :values
  def initialize
    @values = []
  end
end

languages = Hash.new
headers = []

csv_text = File.read('.StringLocalizationParsed.csv')
csv = CSV.parse(csv_text, :headers => true)
csv.headers.each do |header|
  if header != nil && header != 'Key'
    language = Language.new
    language.name = header
    languages[header] = language
    headers << header
  end
end

csv.each do |row|
  headers.each do |header|
    language = languages[header]
    value  = Value.new
    value.key = row['Key']
    value.value = row[header]
    language.values << value
    languages[header] = language
  end
end

def get_file_path(name, config)
  file_path = ''
  if config == :ios
    file_path = "output-ios/" + name + ".lproj" + "/Localizable.strings"
  else
    file_path = "output-android/" + "values-"+ name + "/strings.xml"
  end
  dir = File.dirname(file_path)
  unless File.directory?(file_path)
      FileUtils.mkdir_p(dir)
  end
  file_path
end

def create_file_from_language_android(language)
  file_path = get_file_path(language.name, :android)
  open(file_path, 'w+') do |f|
    f.puts "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>"
        language.values.each do |value|
          f.puts "<string name=\"%{name}\">%{value}</string>" % {:name => value.key, :value => value.value_android}
        end
    f.puts "</resources>"
  end
end

def create_file_from_language_ios(language)
  file_path = get_file_path(language.name, :ios)
  open(file_path, 'w+') do |f|
    f.puts "/* \nLocalizable.strings \nReferenceApp-ios\n*/"
        language.values.each do |value|
          f.puts "\"%{name}\" = \"%{value}\";" % {:name => value.key, :value => value.value}
    end
  end
end

headers.each do |header|
  Thread.new{create_file_from_language_android(languages[header])}.join
  Thread.new{create_file_from_language_ios(languages[header])}.join
end

longest_file_path = "longest_string.txt"
Thread.new{
  open(longest_file_path, 'w+') do |f|
    first_key = languages.each_key.first
    languages[first_key].values.each_with_index do
      |value, index|
        all_values = []
        headers.each do |header|
            language = languages[header]
            all_values << language.values[index]
        end
        f.puts value.key + "=" + all_values.max_by{|value| value.value.length}.value
    end
  end
}.join
