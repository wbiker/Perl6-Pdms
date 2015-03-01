use v6;

module CmdLineArgs;

sub parse_cmd_args(Str $desired_args, @args) is export {
	my %params;
	my %desired_params;
	if @args {	
		my $last_argument;
		for @args -> $arg {
			say "arg: ", $arg;
			if $arg ~~ /^\-\-?(.*)/ {
				$last_argument = ~$0;
				say "last_argument: ", $last_argument;
	
				if $last_argument ~~ /(<-[\=]>*)\=(.*)/ {
					my $argument = ~$0;
					my $value = ~$1;
					say "argument: ", $argument;
					say "value = ", $value;

					if %desired_params.exists_key($argument) {
						if $argument ~~ /tags/ && $value ~~ /\,/ {
							my @tags = $value.split(',');
							%params{$argument} = [ @tags ];
						}
						else {		
							%params{$argument} = $value;
						}
					}
					else {
						say $argument ~ " unknown";
						exit;
					}
					$last_argument = Nil;
				}
			}
			elsif $last_argument {
				say "w/o -- ", $last_argument, " ", $arg;
				if %desired_params.exists_key($last_argument) {
					if $last_argument ~~ /tags/ && $arg ~~ /\,/ {
						my @tags = $arg.split(',');
						%params{$last_argument} = [@tags];
					}
					else {
						%params{$last_argument} = $arg;
					}
				}
				else {
					say $last_argument ~ " unknown";
					exit;
				}
				$last_argument = Nil;
			}
		}
	}
}
