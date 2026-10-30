Config.find_or_create_by!(id: 1) do |c|
  c.local_app_data  = "~/.local/share/job-search-dashboard/resume"
  c.delimiter       = "@@@startdelim@@@"
  c.compare_prompt  = nil
end
