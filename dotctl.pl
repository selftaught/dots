#!/usr/bin/env perl

package Dotctl;

use strict;
use warnings;
use feature qw(say);

use FindBin qw($Bin);

use Cwd;
use Digest::MD5;
use Getopt::Long;
use Data::Dumper;
use Term::ANSIColor qw(:constants);

sub new {
    my $self = shift;
    my $args = {
        'repo-path' => Cwd::realpath $Bin,
    };

    my $blessed = bless $args, $self;
    $blessed->get_opts;
    return $blessed;
}

sub help {
    say q{
NAME

   dotctl

DESCRIPTION

    Provides helpful functionality for syncing dot files to and from $HOME

SYNOPSIS

    dotctl [...option] [...value]

OPTIONS

    -h,   --help                           outputs this help information
    -f,   --force                          overrides user input prompts and assumes 'yes'
    -c,   --compare-checksum               compares the checksum of our dot files from the repo to the dots stored in $HOME
    -d,   --diff                           show a diff between the dot files in ~ and .
    -s2h, --sync-to-home                   sync dot files from the repository to $HOME
    -s2r, --sync-to-repo                   sync dot files from $HOME to the repository
    -dac, --decrypt-all-sec                triggers decrypt prompt for all files in ./sec
    -eac, --encrypt-all-sec                triggers encrypt prompt for all files in ./sec
    -dec, --decrypt         <path>         trigger a prompt to decrypt a specific file
    -enc, --encrypt         <path>         trigger a prompt to encrypt a specific file
};
    exit;
}

sub get_opts {
    my $self = shift;

    GetOptions(
        'h|help'              => sub { &help },
        'd|diff'              => \$self->{'diff'},
        'f|force'             => \$self->{'force'},
        'c|compare-checksums' => \$self->{'compare-checksums'},
        's2h|sync-to-home'    => \$self->{'sync-to-home'},
        's2r|sync-to-repo'    => \$self->{'sync-to-repo'},
        'dac|decrypt-all-sec' => \$self->{'decrypt-all-sec'},
        'eac|encrypt-all-sec' => \$self->{'encrypt-all-sec'},
        'dec|decrypt=s'       => \$self->{'decrypt'},
        'enc|encrypt=s'       => \$self->{'encrypt'},
    );
}

sub main {
    shift->pre_run->run->post_run;
}

sub pre_run {
    my $self = shift;
    $self->validate_options;
    return $self;
}

sub run {
    my $self = shift;

    if ($self->{'diff'}) {
        $self->compare_checksums;
    } elsif ($self->{'compare-checksums'}) {
        $self->compare_checksums;
    } elsif ($self->{'sync-to-home'}) {
        $self->sync_to_home;
    } elsif ($self->{'sync-to-repo'}) {
        $self->sync_to_repo;
    } elsif ($self->{'encrypt'}) {
        $self->encrypt($self->get_password_input_prompt);
    } elsif ($self->{'decrypt'}) {
        $self->encrypt($self->get_password_input_prompt);
    } elsif ($self->{'decrypt-all-sec'}) {
        $self->decrypt_all_files_in_sec_dir($self->get_password_input_prompt);
    } elsif ($self->{'encrpyt-all-sec'}) {
        $self->encrypt_all_files_in_sec_dir($self->get_password_input_prompt);
    }

    return $self;
}

sub post_run {
    my $self = shift;
}

sub sync_to_home {
    my $self = shift;
    foreach my $dot (@{$self->get_authoritative_dot_list}) {
        my $home_path = sprintf '%s/%s', $ENV{'HOME'}, $dot;
        my $repo_path = sprintf '%s/%s', $self->{'repo-path'}, $dot;

        say sprintf "%s%sSyncing from repo -> home%s: %s", BOLD, BLUE, RESET, $dot;

        if (-d $repo_path) {
            say `rsync -avc $repo_path/ $home_path`;
            next;
        }
        my $ret = '';

        eval {
            my $contents;
            open my $fh, '<', $repo_path or die "opening $repo_path failed: $!\n";
            {
                local $/;
                $ret = <$fh>;
            }
            close $fh;
        };

        if (!$@ && $ret) {
            eval {
                open my $fh, '>', $home_path or die "opening $home_path failed: $!\n";
                print $fh $ret;
                close $fh;
            };

            say sprintf "%s%s%s%s", BOLD, RED, $@, RESET if $@;
        }
    }

    say sprintf "\n%s%sDone%s!", BOLD, GREEN, RESET;
    exit;
}

sub sync_to_repo {
    my $self = shift;
    foreach my $dot (@{$self->get_authoritative_dot_list}) {
        my $home_path = sprintf '%s/%s', $ENV{'HOME'}, $dot;
        my $repo_path = sprintf '%s/%s', $self->{'repo-path'}, $dot;

        say sprintf "%s%sSyncing from home -> repo%s: %s", BOLD, BLUE, RESET, $dot;

        my $ret = eval {
            my $contents;
            open my $fh, '<', $home_path or die "opening $home_path failed: $!\n";
            {
                local $/;
                $contents = <$fh>;
            }
            close $fh;
            return $contents;
        } || '';

        if (!$@ && $ret) {
            eval {
                open my $fh, '>', $repo_path or die "opening $repo_path failed: $!\n";
                print $fh $ret;
                close $fh;
            };

            say sprintf "%s%s%s%s", BOLD, RED, $@, RESET if $@;
        }
    }

    say sprintf "\n%s%sDONE%s!", BOLD, GREEN, RESET;
    exit;
}

sub validate_options {
    my $self = shift;

    return if $self->{'compare-checksums'} || $self->{'diff'};

    if (!$self->{'sync-to-home'} &&
        !$self->{'sync-to-repo'}) {
        die "Sync direction unknown: please use --sync-to-home (-s2h) or --sync-to-repo (-s2r)!\n";
    }
}

sub compare_checksums {
    my $self = shift;
    my $repo = $self->get_repo_dot_md5_checksums;
    my $home = $self->get_home_dot_md5_checksums;

    foreach my $dot (keys %{$repo}) {
        my $home_path = sprintf '%s/%s', $ENV{'HOME'}, $dot;
        my $repo_path = sprintf '%s/%s', $self->{'repo-path'}, $dot;

        if (!-e $home_path) {
            say sprintf '%-30s => %s%sREMOVED%s', $home_path, BOLD, RED, RESET;
            next;
        }

        if ($home->{$dot} ne $repo->{$dot}) {
            say sprintf '%-30s => %s%sCHANGED%s', $home_path, BOLD, YELLOW, RESET;

            if ($self->{'diff'}) {
                my $cmd = 'diff ' . ($^O eq 'darwin' ? ' -u' : '--color -u') . " $home_path $repo_path";
                say $cmd;
                chomp(my $diff = `$cmd | bat --pager never --color always -l diff`);
                say "\n$diff\n";
            }
        }
    }
}

sub get_authoritative_dot_list {
    my $self = shift;
    my @list = ();

    if (!opendir DIR, $self->{'repo-path'}) {
        die "opendir failed: $!\n";
    }

    foreach my $ent (readdir(DIR)) {
        next if $ent =~ /^\.{1,2}$/;
        push @list, $ent;
    }

    close DIR;
    return \@list;
}

sub get_repo_dot_md5_checksums {
    my $self = shift;
    return $self->get_dot_md5_checksums(
        $self->{'repo-path'}
    );
}

sub get_home_dot_md5_checksums {
    return shift->get_dot_md5_checksums($ENV{'HOME'});
}

sub get_dot_md5_checksums {
    my ($self, $path) = @_;
    my $sums = {};

    foreach my $ent (@{$self->get_authoritative_dot_list}) {
        my $abs_path = sprintf '%s/%s', $path, $ent;
        if (!-e $abs_path) {
            next;
        }

        my $hex_digest = eval {
		if (-f $abs_path) {
		    open FILE, $abs_path or die "open($abs_path) failed: $!\n";
		    my $context = Digest::MD5->new;
		    $context->addfile(*FILE);
		    my $digest = $context->hexdigest;
		    close FILE;
		    return $digest;
		}

		# If the entry is a directory.
		return Digest::MD5::md5_hex($abs_path);
        };

        if (my $error = $@) {
            say STDERR $error;
            next;
        }

        $sums->{$ent} = $hex_digest;
    }

    return $sums;
}

sub is_an_ignored_entry {
    my ($self, $name) = @_;
    return 1 if !defined $name or !$name;
    return 1 if $name eq '.';
    return 1 if $name eq '..';
    return 1 if $name eq 'sec';
    return 1 if $name eq 'fonts';
    return 1 if $name eq '.git';
    return 1 if $name eq 'dotctl';
    return 1 if $name eq '.ssh/known_hosts';
    return 0;
}

1;

Dotctl->new->main;
exit;
