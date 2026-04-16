require 'xcodeproj'
project_path = '../LawMate.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the target
target = project.targets.first

# Find or create group Models/CoreData
lawmate_group = project.main_group.children.find { |g| g.display_name == 'LawMate' || g.name == 'LawMate' }
models_group = lawmate_group.children.find { |g| g.display_name == 'Models' || g.name == 'Models' }
core_data_group = models_group.children.find { |g| g.display_name == 'CoreData' || g.name == 'CoreData' }
if core_data_group.nil?
  core_data_group = models_group.new_group('CoreData', 'CoreData')
end

# Files to add
files = ['CDUser.swift', 'CDLegalCase.swift', 'CDDocument.swift']

files.each do |file_name|
  file_path = File.join('Models', 'CoreData', file_name)
  
  # Check if already added
  unless core_data_group.files.any? { |f| f.path == file_name || f.path == file_path }
      file_ref = core_data_group.new_file(file_name)
      target.source_build_phase.add_file_reference(file_ref)
      puts "Added #{file_name} to project"
  end
end

project.save
