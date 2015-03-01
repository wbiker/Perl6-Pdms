use v6;
use lib '.';
use SqlWrapper;
use FileDocument;

my $debug = False;
my $sql = SqlWrapper.new(database => 'pdms.db');

multi sub MAIN(Bool :$add!, Str :$file!, Str :$category!, Str :$tags, Str :$date, Str :$desc) {
	my @tags = get_tag_array($tags);
	file_add(file => $file, category => $category, tags => @tags, date => $date, desc => $desc);

}

multi sub MAIN(Bool :$delete!, Str :$file, Str :$category, Str :$tags) {
	say "delete";
}

multi sub MAIN(Bool :$search!, Str :$file_name, Str :$category, Str :$tags) {
	if $file_name {
		say "search file name: '$file_name'";
		my @docs = $sql.find_file_name($file_name);
		for @docs -> $doc {
			say "File: ", "-" x 30;
			my $width = $doc.file_path.chars;
			my $print_pattern = "%s %s\n";
			printf($print_pattern, " ID:", $doc.file_id);
			printf($print_pattern, " Name:", $doc.file_name);
			printf($print_pattern, " Path:", $doc.file_path);
		}
	}
	elsif $category {
		say "search category name: '$category'";
		$sql.find_category_name($category);
	}
	elsif $tags {
		say "search tags: $tags";
		$sql.find_tag_names($tags);
	}
}

multi sub MAIN(Bool :$checkin!, Str :$file, Str :$category, Str :$tags, Int :$version) {
	say "checkin";
}

multi sub MAIN(Bool :$update!, Int :$id!) {
	
}

multi sub MAIN(Bool :$createdb!) {
	say "Create DB";
	$sql.create_table();
	say "Done";
}

multi sub MAIN(Bool :$deletedb!) {
	say "delete DB";
	$sql.drop_table();
	say "done";
}

=comment
	Sub section. Contains all subs for this scripts.

#| adds a file to the database
sub file_add(Str :$file!, Str :$category, :@tags, Str :$date, Str :$desc) {
	my $file_date = parse_date_string($date);
	my $file_to_add;
	try {
		$file_to_add = FileDocument.new($file.IO, $category, @tags, $file_date, $desc);

		CATCH {
			say $_.payload;
			exit;
		}
	}
	
	say $file_to_add.perl;
	$file_to_add.copy_file();
	$sql.add_file($file_to_add);
}

#| deletes a file in the database.
sub file_delete(Str :$file) {
	say "file_delete";	
}

sub file_search(Str :$file, Str :$category, :@tags, :$date) {
	say "file_search";
}

sub get_tag_array(Str $tags) {
	unless $tags {
		return Array.new;
	}
	if $tags ~~ /\,/ {
		return $tags.split(/\,/);
	}

	return $tags;
}

sub parse_date_string(Str $date) {
	return time unless $date;

	my $year;
	my $month;
	my $day;
	if $date ~~ /(\d ** 4) \- (\d ** 1..2) \- (\d**1..2)/ {
		$year = +$0;
		$month = +$1;
		$day = +$2;
	}
	elsif $date ~~ /(\d ** 1..2) \. (\d ** 1..2) \. (\d ** 4)/ {
		$year = +$2;
		$month = +$1;
		$day = +$0;
	}
	else {
		die "Could not find date in string '$date'";
	}

	say "Year: $year Month: $month Day: $day";
	my $d = DateTime.new(:year($year), :month($month), :day($day));
	return $d.Instant;
}
