require "fileutils"

# Implements FileStoragePort by writing to a real folder on disk (localAppData).
# Returns the file_path stored in the database, which is relative to the
# directory (just the file name) per the PRD.
class LocalDiskStorageAdapter
  include FileStoragePort

  def store(file_name:, bytes:, directory:)
    dir = File.expand_path(directory)
    FileUtils.mkdir_p(dir)
    file_name = File.basename(file_name)
    File.binwrite(File.join(dir, file_name), bytes)
    file_name
  rescue SystemCallError => e
    # A bad localAppData path is a config problem the user can fix in the
    # Config modal, so surface it as a validation failure, not a 500.
    raise Errors::ValidationFailed,
          "Can't save to localAppData folder #{dir} (#{e.class.name.demodulize}). Check the path in Config."
  end

  def read(file_path:, directory:)
    dir = File.expand_path(directory)
    # file_path is only ever a bare file name; basename keeps a bad row from
    # reading outside localAppData.
    path = File.join(dir, File.basename(file_path.to_s))
    raise Errors::NotFound, "The PDF #{File.basename(path)} is no longer in #{dir}." unless File.file?(path)

    File.binread(path)
  end
end
