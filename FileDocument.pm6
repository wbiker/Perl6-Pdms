use v6;

use Digest::MD5;

class FileDocument {
	has $.file_id;
	has $.file_name;
	has $.file_path;
	has $.file_name_path;
	has $.file_name_hash;
	has $.file_name_version_hash;
	has $.file_version = 1;
	has $.file_origin;
	has $.file_category;
	has @.file_tags;
	has $.file_date;
	has $.file_import_date;
	has $.File_description;

	multi method new(IO::Path $file, $category, @tags, $date, $desc) {
		die "File does not exists: $file" unless $file.e;
		my $file_path = $*SPEC.catdir('dms', Digest::MD5.md5_hex($file.basename));
		die "File already exists in dms/. Do you want to --check-in it and create a new version?" if $file_path.IO.e;
		my $file_name_version_hash = Digest::MD5.md5_hex($file.basename ~1);

		my $file_date = $date // time;

		self.new(
			file_name => $file.basename,
			file_path => $file_path,
			file_name_hash => Digest::MD5.md5_hex($file.basename),
			file_name_version_hash => $file_name_version_hash,
			file_name_path => $*SPEC.catfile($file_path, $file_name_version_hash),
			file_origin => $file,
			file_category => $category,
			file_tags => @tags,
			file_import_date => time,
			file_date => $file_date,
			file_description => $desc,
		);
	}

	multi method new($hash) {
		self.new(
			file_id => $hash<file_id>,
			file_name => $hash<file_name>,
			file_path => $hash<file_path>,
			file_name_hash => $hash<file_name_hash>,
			file_name_version_hash => $hash<file_name_version_hash>,
			file_name_path => $hash<file_name_path>,
			file_category => $hash<category_id>,
			file_tags => $hash<file_tags>,
			file_import_date => $hash<file_import_date>,
			file_date => $hash<file_date>,
			file_version => $hash<file_version>,
			file_description => $hash<file_description>,
		);
	}

	method copy_file {
		unless $!file_path.IO.e {
			mkdir($!file_path.IO);
		}

		$!file_origin.copy($!file_name_path);
	}
}
