#!/usr/bin/env perl6

#This will figure out the average size of the files or directories in a certain
#location.

sub MAIN (Str $location = ".", Bool :$dir) {
    #Make some vars
    my $total = 0;
    my $count = 0;

    #Display the progress bar to the user and start calculating.
    waiting(
        {
            for dir($location) -> $file {
                #Exit depending on what the option '$dir' var is set to.
                next if $file.f & $dir;
                next if $file.d & !$dir;

                #Add one to count add add the size to total
                say $file;
                ++$count;
                $total += getSize($file);
            }
        },
        "Figuring average size"
    );

    #Display the results to the user.
    say "Total size:   " ~ niceSize($total);
    say "Average size: " ~ niceSize($total/$count) if $count;
}

#Return the size of the file or directory.
sub getSize (IO::Path:D $file) {
    #Return the size if it is a file.
    return $file.s if $file.f;

    if ($file.d) {
        #The file is a directory, recurse down it to find the size.
        my $total = 0;
        for dir($file) -> $subfile {
            #Add the size as long as the file is not a link and readable.
            $total += getSize($subfile) if !$subfile.l;
        }
        return $total;
    }

    #Not sure what it is, so going to say 0. :/
    return 0;
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

#Found the following at: http://ugexe.com/create-a-perl6-terminal-progress-bar/

#Function to start a waiting animation.
sub waiting (&code, $msg) is export {
    #Display a message to show that it is starting.
    say "Starting...";
    #Make a new promise.
    my $prom = Promise.new;
    my $vow = $prom.vow;

    #Make a promise to get the STDOUT and wait for the code passed in to finish.
    my $wait = start { show-await $msg, $prom };

    #Get the return value.
    my $retval = code();

    #Run the code every second until the code passed in is done.
    $vow.keep(1);
    await($wait);

    return $retval;
}


#Function to run some code and grab STDOUT to make a progress bar.
sub show-await ($status, *@promises) {
    #Make a new supply with a one second interval.
    my $loading = Supply.interval(1);
    my $animation;
    #Stave the current state/config of STDOUT and STDERR.
    my $out = $*OUT;
    my $err = $*ERR;

    #Make an anon class to override the 'print' and 'flush' methods. This will
    #make sure that the progress bar is at the bottom.
    $*ERR = $*OUT = class {
        #Hold each state of the progress bar.
        my $bar;
        #Keep track of the string index so we know which to change.
        my $i;
        #Keep track of the previous line so that the curser can go back to the
        #beginning of the line correctly and overwrite it with spaces.
        my $last-line-len = 0;

        #This will be run once every seccond, due to the supply made earlier.
        $animation = $loading.tap( {
                #Set bar to the next animation state.
                $bar = do given ++$i {
                    when 2 { ".  " }
                    when 3 { ".. " }
                    when 4 { "..." }
                    default { $i = 1; "   " }
                }

                #Call print so that the progress bar is updated.
                print "";
            }
        );

        #Override Perl6's 'print' method.
        method print(*@_) {
            if @_ {
                my $hijacked = @_.join;
                my $msg = "$status$bar\r";
                #Overwrite the line with spaces and place the curser at the
                #beginning with '\r'.
                my $output = (
                        $last-line-len
                        ?? ((" " x $last-line-len) ~ "\r")
                        !! ''
                    ) ~ $hijacked ~ $msg;

                $last-line-len = $output.lines.[*-1].chars;

                #Return STDOUT and STDERR to normal, print the stuff out, and
                #capture the output again.
                my $out2 = $*OUT;
                $*ERR = $*OUT = $out;
                print $output;
                $*ERR = $*OUT = $out2;
            }
        }

        method flush {}
    }

    await Promise.allof: @promises;
    $animation.close;
    $*ERR = $err;
    $*OUT = $out;
    say "";
}
