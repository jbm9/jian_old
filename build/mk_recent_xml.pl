#!/usr/bin/perl

use POSIX qw/strftime/;

$FEATURED = 4;

my @skipfiles_a = ( "media/index.html", "header.html", "footer.html", "missing.html", "index.html", "med_header.html", "med_footer.html", "log/index.html" );
my %skipfiles;
@skipfiles{@skipfiles_a} = (1) x @skipfiles_a;

#print "skipfiles: " . join(", ", keys %skipfiles) . "\n";

@files = <*.html media/*.html log/*.html>;
#@files = <log/*.html>;

for(my $i = 0; $i < @files;) {
    # print "check: $files[$i] " . exists($skipfiles{$files[$i]}) . "\n";

    if(exists($skipfiles{$files[$i]})) {
	splice(@files, $i, 1);
    } else { $i++; }
}

@mtimes = map { (stat($_))[9] } @files;

@mtimes{@files} = @mtimes;

@files_sort = sort { $mtimes{$b} <=> $mtimes{$a} } @files;


@FIELDS = qw/__PAGE_TITLE __PAGE_DESCR __PAGE_CREATED __MEDIA_TITLE __MEDIA_SUBTITLE  __MEDIA_READNOTES __MEDIA_AUTHOR __MEDIA_PURCHASED/;

my %fields;
for my $f (@files_sort) {
#  print "$f: $mtimes{$f}\n";

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

open(INDEX, ">", "index.xml");
open(HEADER, "<", "rss_head.xml");
while(my $l = <HEADER>) { print INDEX $l }
close(HEADER);

print INDEX "<lastBuildDate>" . scalar(gmtime()) . "</lastBuildDate>\n";

for my $f (@files_sort) {
  my %values = %{$fields{$f}};

  my $title;
  if(exists($values{__MEDIA_TITLE})) {
      $title = "Media log: " . $values{__MEDIA_TITLE};
      $title .= " " . $values{__MEDIA_SUBTITLE} if exists($values{__MEDIA_SUBTITLE});
  } else {
     $title = $values{__PAGE_TITLE};
  }

  print INDEX "<item>\n";
  print INDEX "<title>$title</title>\n";
  print INDEX "<link>http://www.joshisanerd.com/$f</link>\n";
#  print INDEX "<guid>http://www.joshisanerd.com/$f</guid>\n";
# Guid is used for freshness checks exclusive of dc:date??  Skipping just in case
  print INDEX "<description>$values{__PAGE_DESCR}</description>\n" if exists($values{__PAGE_DESCR});
  print INDEX "<dc:date>" . strftime("%FT%H:%M:%SZ", gmtime($mtimes{$f})) . "</dc:date>\n";
#      <dc:creator>Antoine Quint</dc:creator>
#      <dc:date>2002-12-04</dc:date>    


  print INDEX "</item>\n";

}



open(HEADER, "<", "rss_foot.xml");
while(my $l = <HEADER>) { print INDEX $l }
close(HEADER);


close INDEX;
