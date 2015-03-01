use v6;

use DBIish;
use FileDocument;

class SqlWrapper {
	has $.dbh;
	has $.database;
	has $.user;
	has $.password;

	method new(:$database, :$user, :$password)  {
		my $dbih = DBIish.connect("SQLite", database => $database);
		return self.bless(dbh => $dbih, database => $database, user => $user, password => $password);
	}

	method add_file(FileDocument $file_doc) {
		my $cat_id = self.find_or_create_category($file_doc.file_category());
		my @tag_ids = self.find_or_create_tags($file_doc.file_tags());

		# insert file into db
		$!dbh.do(q:to/STATEMENT/, $file_doc.file_name, $cat_id, $file_doc.file_path, $file_doc.file_date, $file_doc.file_import_date, $file_doc.file_version, $file_doc.file_name_hash, $file_doc.file_name_version_hash, $file_doc.file_description);
		INSERT INTO FILE(file_name,category_id,file_path,file_date,file_import_date,file_version,file_name_hash,file_name_version_hash, file_description) VALUES(?,?,?,?,?,?,?,?,?)
		STATEMENT

		# read file id from the db
		my $insert_file_sth = $!dbh.prepare('SELECT file_id FROM FILE WHERE file_name_version_hash = ?');
		$insert_file_sth.execute($file_doc.file_name_version_hash);
		
		my $file_id = ($insert_file_sth.fetchrow_array())[0];
		say "File id: $file_id";
		$insert_file_sth.finish();

		# write an entry for each tag into the assignedtag table
		my $sth = $!dbh.prepare('INSERT INTO ASSIGNEDTAG(file_id,tag_id) VALUES(?,?)');
		for @tag_ids -> $tag {
			$sth.execute($file_id, $tag);
		}
		$sth.finish;
	}

	method find_file_name($file_name) {
		my $sth = $!dbh.prepare(q:to/STATEMENT/);
		SELECT * FROM FILE 
		STATEMENT

		$sth.execute();
		my @return_docs;
		while my $ar = $sth.fetchrow_hashref() {
			if $ar<file_name> ~~ /:i $file_name/ {
				@return_docs.push(FileDocument.new($ar));
			}
		}

		return @return_docs;
	}

	method find_category_name($category) {
		my $sth = $!dbh.do(q:to/STATEMENT/, $category);
		SELECT * FROM FILE WHERE cat_name = ?
		STATEMENT

		my $array = $sth.fetchrow_array();
		say $array.perl;
	}

	method find_tag_names($tags) {

	}

	method find_or_create_category($category) {
		return unless $category;
		my $catlc = $category.lc;
		my $sth = $!dbh.prepare('SELECT cat_id,cat_name FROM CATEGORY WHERE cat_name = ?');
		$sth.execute($catlc);
		
		my $array = $sth.fetchrow_array();
		if $array.elems == 0 {
			$!dbh.do(q:to/CREATEEND/, $catlc);
			INSERT INTO CATEGORY(cat_name) VALUES(?);
			CREATEEND

			$sth.execute($catlc);
			my $narray = $sth.fetchrow_array();
			$sth.finish;
			return $narray[0];
		}
		else {
			$sth.finish;
			return $array.[0];
		}
	}

	method find_or_create_tags(@tags) {
		return unless @tags;
		my @tag_ids;

		my $sth = $!dbh.prepare('SELECT tag_id,tag_name FROM TAG WHERE tag_name = ?');

		for @tags -> $tag {
			my $taglc = $tag.lc;
			$sth.execute($taglc);
			my @ar = $sth.fetchrow_array();
			if 0 == @ar.elems {
				$!dbh.do(q:to/STATEMENT/, $taglc);
				INSERT INTO TAG(tag_name) VALUES(?)
				STATEMENT

				$sth.execute($taglc);
				@ar = $sth.fetchrow_array();
			}
			@tag_ids.push(@ar[0]);
		}

		$sth.finish;

		return @tag_ids;
	}

	method drop_table {
		$!dbh.do(q:to/DROPFILE/);
		DROP TABLE FILE
		DROPFILE

		$!dbh.do(q:to/DROPCAT/);
		DROP TABLE CATEGORY
		DROPCAT

		$!dbh.do(q:to/DROPTAG/);
		DROP TABLE TAG
		DROPTAG

		$!dbh.do(q:to/DROPASSIGNED/);
		DROP TABLE ASSIGNEDTAG
		DROPASSIGNED
	}

	method create_table {
		$!dbh.do(q:to/STATEMENT/);
		CREATE  TABLE "main"."FILE" ("file_id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL , "file_name" TEXT, "category_id" INTEGER NOT NULL , "file_path" TEXT, "file_date" DATETIME, "file_import_date" DATETIME, "file_version" INTEGER, "file_name_hash" TEXT, "file_name_version_hash", "file_description" TEXT)
		STATEMENT

		$!dbh.do(q:to/CREATECAT/);
		CREATE  TABLE "main"."CATEGORY" ("cat_id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL , "cat_name" TEXT)	
		CREATECAT

		$!dbh.do(q:to/CREATETAG/);
		CREATE  TABLE "main"."TAG" ("tag_id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL , "tag_name" TEXT)
		CREATETAG

		$!dbh.do(q:to/CREATEASSIGNED/);
		CREATE  TABLE "main"."ASSIGNEDTAG" ("assigned_id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL , "file_id" INTEGER NOT NULL , "tag_id" INTEGER NOT NULL )
		CREATEASSIGNED
	}
}
