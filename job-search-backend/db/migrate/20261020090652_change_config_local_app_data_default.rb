# The PRD's "/localAppData/resume" sits at the filesystem root, which a normal
# user can't create, so every upload failed on a fresh install. Default to the
# per-user app data folder instead; LocalDiskStorageAdapter expands the "~".
class ChangeConfigLocalAppDataDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :config, :local_app_data,
                          from: "/localAppData/resume",
                          to: "~/.local/share/job-search-dashboard/resume"
  end
end
