#!/usr/bin/env perl6

#This will figure out the average size of the files or directories in a certain
#location.

sub MAIN (Str $location = ".", Bool :$dir) {
    #Make some vars
    my $total = 0;
    my $count = 0;

    for dir($location) -> $file {
        #Exit depending on what the option '$dir' var is set to.
        next if $file.f & $dir;
        next if $file.d & !$dir;

        #Add one to count add add the size to total
        ++$count;
        $total += getSize($file);
    }

    #Display the results to the user.
    say "Total size:   " ~ niceSize($total);
    say "Average size: " ~ niceSize($total/$count) if $count;
}

#Return the size of the file or directory.
sub getSize (IO::Path:D $file) {
    #Return the size if it is a file.
    return $file.s if $file.f;

    #The file is a directory, recurse down it to find the size.
    my $total = 0;
    for dir($file) -> $subfile {
        #Add the size as long as the file is not a link and readable.
        $total += getSize($subfile) if !$subfile.l && $subfile.r;
    }
    return $total;
}


#Display the size of files nicely.
sub niceSize ($bytes) {
    #Make some vars
    my $KB = 1024;
    my $MB = 1024 * 1024;

    #Return a nice string depending on the amount of bytes.
    given ($bytes) {
        when * > $MB { return (($bytes / $MB) ~ " mb") }
        when * > $KB { return (($bytes / $KB) ~ " kb") }
        when * < $KB { return "$bytes bytes" }
    }
}
