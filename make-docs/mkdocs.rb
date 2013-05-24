#!/usr/bin/env ruby

# Automated script to update docs.editorconfig.org

require 'date'
require 'fileutils'
require 'tmpdir'

git_cmd = 'git'
cmake_cmd = 'cmake'
c_core_repo = 'git://github.com/editorconfig/editorconfig-core-c.git'
docs_repo = 'git@github.com:editorconfig/docs.editorconfig.org.git'
c_core_branch = 'master'
docs_branch = 'gh-pages'

user_name = `git config --get user.name`
user_email = `git config --get user.email`

# temporary dir
dir = "#{Dir.pwd}/tmp"

FileUtils.rm_rf dir if Dir.exists?(dir)
Dir.mkdir dir

c_core_repo_local_dir = "#{dir}/core"
docs_repo_local_dir = "#{dir}/docs"
abort unless system "#{git_cmd} clone #{c_core_repo} #{c_core_repo_local_dir}"
abort unless system "#{git_cmd} clone #{docs_repo} #{docs_repo_local_dir}"

# versions that already have docs.
existing_versions = Dir.entries "#{docs_repo_local_dir}/en"

Dir.chdir c_core_repo_local_dir

tags = `#{git_cmd} tag`  # get all tags

abort 'Failed to obtain tags' unless $?.exitstatus

tags += "\nmaster"  # as well master

tags.each_line do |tag|
  tag.strip!
  # skip if the version is already available. Always update master
  next if tag.empty? or (existing_versions.include?(tag) and tag != 'master')

  # checkout the tag first
  abort unless system "#{git_cmd} checkout #{tag}"

  Dir.mkdir 'build'
  abort unless system "cd build && #{cmake_cmd} .. && #{cmake_cmd} --build . --target doc"

  # remove the existing tag if possible
  if Dir.exists?("#{docs_repo_local_dir}/en/#{tag}")
    FileUtils.rm_rf "#{docs_repo_local_dir}/en/#{tag}"
  end

  FileUtils.cp_r 'build/doc/html', "#{docs_repo_local_dir}/en/#{tag}"

  FileUtils.rm_rf 'build'
end

Dir.chdir docs_repo_local_dir
abort unless system "#{git_cmd} config user.name #{user_name}"
abort unless system "#{git_cmd} config user.email #{user_email}"
abort unless system "#{git_cmd} add en/"
abort unless system "#{git_cmd} commit -a -m 'Update docs at #{DateTime.now}.'"
abort unless system "#{git_cmd} push origin #{docs_branch}"
