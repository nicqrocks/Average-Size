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
    say "Total size:   $total bytes";
    say "Average size: {$total/$count} bytes";
}

sub getSize (IO::Path:D $file) {
    #Return the size if it is a file.
    return $file.s if $file.f;

    #The file is a directory, recurse down it to find the size.
    my $total = 0;
    for dir($file) -> $file {
        $total += getSize($file);
    }
    return $total;
}
