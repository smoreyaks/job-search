require "rails_helper"
require "tmpdir"

RSpec.describe LocalDiskStorageAdapter do
  subject(:adapter) { described_class.new }

  it "honors the FileStoragePort contract" do
    expect(adapter).to be_a(FileStoragePort)
  end

  it "writes the bytes under the directory and returns the relative file_path" do
    Dir.mktmpdir do |dir|
      path = adapter.store(file_name: "cv.pdf", bytes: "%PDF-1.7 body", directory: dir)

      expect(path).to eq("cv.pdf")
      expect(File.binread(File.join(dir, "cv.pdf"))).to eq("%PDF-1.7 body")
    end
  end

  it "creates the directory if it does not exist" do
    Dir.mktmpdir do |dir|
      nested = File.join(dir, "nested", "resumes")
      adapter.store(file_name: "cl.pdf", bytes: "%PDF", directory: nested)

      expect(File).to exist(File.join(nested, "cl.pdf"))
    end
  end

  it "raises ValidationFailed naming the folder when it can't be written" do
    Dir.mktmpdir do |dir|
      File.chmod(0o500, dir)
      locked = File.join(dir, "resumes")

      expect { adapter.store(file_name: "cv.pdf", bytes: "%PDF", directory: locked) }
        .to raise_error(Errors::ValidationFailed, /#{Regexp.escape(locked)}.*EACCES/)
    ensure
      File.chmod(0o700, dir)
    end
  end

  describe "#read" do
    it "returns the bytes of a stored file" do
      Dir.mktmpdir do |dir|
        adapter.store(file_name: "cv.pdf", bytes: "%PDF-1.7 body", directory: dir)

        expect(adapter.read(file_path: "cv.pdf", directory: dir)).to eq("%PDF-1.7 body")
      end
    end

    it "raises NotFound naming the file when it's gone" do
      Dir.mktmpdir do |dir|
        expect { adapter.read(file_path: "missing.pdf", directory: dir) }
          .to raise_error(Errors::NotFound, /missing\.pdf/)
      end
    end

    it "never reads outside the directory" do
      Dir.mktmpdir do |dir|
        File.binwrite(File.join(File.dirname(dir), "outside.pdf"), "secret")

        expect { adapter.read(file_path: "../outside.pdf", directory: dir) }.to raise_error(Errors::NotFound)
      ensure
        FileUtils.rm_f(File.join(File.dirname(dir), "outside.pdf"))
      end
    end
  end
end
