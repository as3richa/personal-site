require 'erb'
require 'yaml'
require 'fileutils'
require 'kramdown'

FileUtils.remove_dir('build', true) if File.exist?('build')
Dir.mkdir('build')

class Project
  TEMPLATE = ERB.new(File.read('project.erb'))

  def initialize(name:, description:, demo: nil, screenshot: nil)
    @name = name
    @description = description
    @demo = demo
    @screenshot = screenshot
  end

  def render
    TEMPLATE.result(Kernel.binding)
  end
end

class Job
  TEMPLATE = ERB.new(File.read('job.erb'))

  def initialize(company:, title:, dates:, bullets:)
    @company = company
    @title = title
    @dates = dates
    @bullets = bullets
  end

  def render
    TEMPLATE.result(Kernel.binding)
  end
end

class Index
  TEMPLATE = ERB.new(File.read('index.erb'))

  def initialize(title:, style:, content:)
    @title = title
    @style = style
    @content = content
  end

  def render
    TEMPLATE.result(Kernel.binding)
  end
end

style = File.read('style.css')

content_html = Kramdown::Document.new(File.read('content.md')).to_html

projects_html = ""

YAML.load_file('projects.yml').fetch('projects').each do |raw|
  raw = raw.map { |key, value| [key.to_sym, value] }.to_h
  project = Project.new(**raw)
  projects_html += project.render
end

work_html = ""

YAML.load_file('work.yml').fetch('jobs').each do |raw|
  raw = raw.map { |key, value| [key.to_sym, value] }.to_h
  job = Job.new(**raw)
  work_html += job.render
end

content_html = content_html.gsub('{{PROJECTS}}', projects_html)
content_html = content_html.gsub('{{WORK}}', work_html)

unminified_index_html = Index.new(title: 'Adam Richardson', style: style, content: content_html).render
File.write('build/index.unmin.html', unminified_index_html)
system('npm run minify -- --collapse-whitespace --minify-css --output build/index.html build/index.unmin.html')
File.delete('build/index.unmin.html')

Dir['assets/*'].each do |filename|
  system("cp #{filename} build/#{File.basename(filename)}")
end
