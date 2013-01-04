#!/usr/bin/perl

use POSIX qw/strftime/;

$FEATURED = 10;

my @skipfiles_a = ( "media/index.html", "header.html", "footer.html", "missing.html", "index.html", "med_header.html", "med_footer.html", "blog.html", "log/index.html" );
my %skipfiles;
@skipfiles{@skipfiles_a} = (1) x @skipfiles_a;

#print "skipfiles: " . join(", ", keys %skipfiles) . "\n";

@files = <log/*.html media/*.html>;

print "files: " . @files . "\n";
for(my $i = 0; $i < @files;) {
    print "check $i: $files[$i] " . exists($skipfiles{$files[$i]}) . "\n";

    if(exists($skipfiles{$files[$i]}) || 1 > length($files[$i])) {
	splice(@files, $i, 1);
	print  "splice $i " . @files . "\n";
    } else { $i++; }
}

my %mtimes;
@mtimes{@files} = map { (stat($_))[9] } @files;

@files_sort = sort { $mtimes{$b} <=> $mtimes{$a} } @files;
@files_sort = @files_sort[0..$FEATURED] if $FEATURED < @files_sort;

@FIELDS = qw/__PAGE_TITLE __PAGE_DESCR __PAGE_CREATED __MEDIA_TITLE __MEDIA_SUBTITLE  __MEDIA_READNOTES __MEDIA_AUTHOR __MEDIA_PURCHASED/;

my %fields;
my %bodies;

sub load_file {
  my $f = shift;

  next unless $f;

  print "$f: $mtimes{$f}\n";

  open(FILE, $f);
  my %values;
  my $body = "";
  while(my $l = <FILE>) {
      if($l =~ /^\s*\#/) {
	  for my $F (@FIELDS) {
	      if ($l =~ /^\#define\s+(\S+)\s+(.*)$/) {
		  $values{$1} = $2;
		  break;
	      }
	  } 
      } else {
	  $body .= $l;
      }
  }
  close(FILE);
  $fields{$f} = \%values;
  $bodies{$f} = $body;
}

open(INDEX, ">", "log/index.html");
print INDEX "#define __PAGE_TITLE blog index\n";
print INDEX "#define __P_BLOG\n";
print INDEX "#include <header.html>\n";
print INDEX "      <div class='blogwrap'>\n";
# print INDEX "<h2 class='content'>Blog Index</h2>\n";
# print INDEX "<P>This is a generated index of blog-like content</p>\n";



sub file_to_entry {
  my $f = shift;
  my %values = %{$fields{$f}};
  next unless $f;
  my $title;
  if($values{__MEDIA_TITLE}) {
      $title = "Media log: " . $values{__MEDIA_TITLE};
      $title .= " " . $values{__MEDIA_SUBTITLE} if exists($values{__MEDIA_SUBTITLE});
  } else {
     $title = $values{__PAGE_TITLE};
  }

    my $retval = "";
    $retval .= "<h2><a href='/$f'>$title</a> <small>" . scalar(localtime($mtimes{$f})) . "</small></h2>\n";
    $retval .= $bodies{$f};
    return $retval;
}

for my $f (@files_sort) {
  load_file($f);
}
my @entries = map { file_to_entry($_) } @files_sort;

print INDEX join("\n\n", @entries);

print INDEX "</div>\n";
print INDEX "#include <footer.html>\n";

close INDEX;
