#!/usr/bin/perl

$FEATURED = 4;

@files = <media/*.html>;
for(my $i = 0; $i < @files; $i++) {
  splice(@files, $i, 1) if($files[$i] eq "media/index.html");
}

@mtimes = map { (stat($_))[9] } @files;

@mtimes{@files} = @mtimes;

@files_sort = sort { $mtimes{$b} <=> $mtimes{$a} } @files;


@FIELDS = qw/__MEDIA_TITLE __MEDIA_SUBTITLE __MEDIA_AUTHOR __MEDIA_PURCHASED __MEDIA_READNOTES/;

my %fields;
for my $f (@files_sort) {
  print "$f: $mtimes{$f}\n";

  open(FILE, $f);
  my %values;
  while(my $l = <FILE>) {
    for my $F (@FIELDS) {
      if($l =~ /^#define\s+$F\s+(.*)$/) {
	$values{$F} = $1;
	break;
      }
    }
  }
  close(FILE);
  $fields{$f} = \%values;
}

# Generate the main list:

open(INDEX, ">", "media/index.html");

print INDEX "#define __PAGE_TITLE Media log index\n";
print INDEX "#include <header.html>\n";
print INDEX "      <div class='content'>\n";
print INDEX "<h2>Media Log Index</h2>\n";
print INDEX "<P>This is a generated index list of all the entries in the media log, in descending chronological order (from modified times).  It probably isn't too useful to you, but I find it handy.</p>\n";

for my $f (@files_sort) {
  my %values = %{$fields{$f}};

  my ($filename) = $f =~ /media\/(.*)\.html$/;

  print INDEX "<ul>\n";
  print INDEX "<li> __REF($filename, $values{__MEDIA_TITLE}): " . substr($values{__MEDIA_READNOTES}, 0, 50) .  "</ul>\n";
  print INDEX "</ul>\n"
}

print INDEX "</div>\n";
print INDEX "#include <footer.html>\n";

close INDEX;
