#!/usr/bin/perl -wT
# This is stats.pl, which shows stats about the database
#
# Copyright (C) 2002-2004 Russ Burdick, grub@extrapolation.net
#
# This file is part of mcdl_cgi.
#  
# mcdl_cgi is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# mcdl_cgi is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with mcdl_cgi; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use HTML::Template;

use lib qw(.);
use CDDBConstants;
use menu;

my $num_top = 10;
my $num_artist = 0;
my $num_cd = 0;
my $num_song = 0;
my $avg_cd = 0;
my $avg_song = 0;
my %cd_count = ();
my %aid = ();
my %song_count = ();
my @top_artist_cd = ();

# Remove buffering
$| = 1;

my $body = "";

# open the html template
my $template = HTML::Template->new(filename => "$tmpldir/$tmplfile");

# fill in some parameters
my $mtime = localtime((stat $0)[9]);
$template->param("MOD_TIME" => $mtime);
$template->param("TITLE" => $pagetitle);

# ------------------------------------------------------------
# Create an instance of CGI
my $q = new CGI;

# Send a MIME header
print $q->header("text/html");

$body .= "<H1>CD Database Stats</H1>\n";

# ------------------------------------------------------------
# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                       $dbusername, $dbpassword);
die "DBI error from connect: ", $DBI::errstr unless $dbh;

my $sql = "SELECT COUNT(ARTIST_ID) FROM Artist";

# Send the query
my $sth = $dbh->prepare($sql);
die "DBI error with prepare:", $sth->errstr unless $sth;

# Execute the query
my $result = $sth->execute;
die "DBI error with execute:", $sth->errstr unless $result;

# If we received artists from the SELECT, print them out
if ($sth->rows) {

   my @row = $sth->fetchrow;
   $num_artist = $row[0];
}

# Finish that database call
$sth->finish;

$sql = "SELECT COUNT(CD_ID) FROM CD";

# Send the query
$sth = $dbh->prepare($sql);
die "DBI error with prepare:", $sth->errstr unless $sth;

# Execute the query
$result = $sth->execute;
die "DBI error with execute:", $sth->errstr unless $result;

# If we received artists from the SELECT, print them out
if ($sth->rows) {

   my @row = $sth->fetchrow;
   $num_cd = $row[0];
}

# Finish that database call
$sth->finish;

$sql = "SELECT COUNT(SONG_ID) FROM Song";

# Send the query
$sth = $dbh->prepare($sql);
die "DBI error with prepare:", $sth->errstr unless $sth;

# Execute the query
$result = $sth->execute;
die "DBI error with execute:", $sth->errstr unless $result;

# If we received artists from the SELECT, print them out
if ($sth->rows) {

   my @row = $sth->fetchrow;
   $num_song = $row[0];
}

# Finish that database call
$sth->finish;

if ($num_artist) { $avg_cd = $num_cd / $num_artist; }
if ($num_cd) { $avg_song = $num_song / $num_cd; }

$body .= qq(<p>Total Artists: $num_artist<br>\n);
$body .= qq(Total CDs: $num_cd<br>\n);
$body .= qq(Total Songs: $num_song<br>\n);
$body .= qq(Average CDs Per Artist: $avg_cd<br>\n);
$body .= qq(Average Songs Per CD: $avg_song</p>\n);

$sql = "SELECT * FROM Artist";

# Send the query
$sth = $dbh->prepare($sql);
die "DBI error with prepare:", $sth->errstr unless $sth;

# Execute the query
$result = $sth->execute;
die "DBI error with execute:", $sth->errstr unless $result;

# If we received artists from the SELECT, print them out
if ($sth->rows) {

   # Iterate through artist IDs and names
   while (my $row = $sth->fetchrow_hashref) {

      $aid{$row->{ARTIST_NAME}} = $row->{ARTIST_ID};
      my $sql2 = "SELECT COUNT(CD_ID) FROM CD ";
      $sql2 .= "WHERE ARTIST_ID = " . $dbh->quote($row->{ARTIST_ID});

      # Send the query
      my $sth2 = $dbh->prepare($sql2);
      die "DBI error with prepare:", $sth2->errstr unless $sth2;

      # Execute the query
      my $result2 = $sth2->execute;
      die "DBI error with execute:", $sth2->errstr unless $result2;

      # If we received artists from the SELECT, print them out
      if ($sth2->rows) {

         my @row2 = $sth2->fetchrow;
         $cd_count{$row->{ARTIST_NAME}} = $row2[0];
      }

      # Finish that database call
      $sth2->finish;

   }
}

# Finish that database call
$sth->finish;

foreach my $key (sort {$cd_count{$b} <=> $cd_count{$a} ||
                       $a cmp $b} (keys %cd_count)) {
   push @top_artist_cd, $key;
}

$body .= qq(<p>Top $num_top Artists By Number of CDs:</p>\n);
$body .= qq(<ol>\n);
my $count = 0;
# foreach my $key (@top_artist_cd) {
for (my $i = 0; (($i < $num_top) && ($i <= $#top_artist_cd) && 
                 ($count <= $#top_artist_cd)); $i++) {
   $body .= qq(<li>);
   my $done = 0;
   while (!$done) {
      $body .= qq(<a href="$cgidir/view-artist.pl?artist=$aid{$top_artist_cd[$count]}">);
      $body .= escape($top_artist_cd[$count]);
      $body .= qq(</a>: );
      $body .= qq($cd_count{$top_artist_cd[$count]});
      if ($cd_count{$top_artist_cd[$count]} == 1) {
         $body .= qq( CD);
      } else {
         $body .= qq( CDs);
      }
      if (($count <= $#top_artist_cd) && ($cd_count{$top_artist_cd[$count]} == $cd_count{$top_artist_cd[$count+1]})) {
         $body .= qq(<br>\n);
      } else {
         $body .= qq(\n);
         $done = 1;
      }
      $count++;
   }
   $body .= qq(</li>\n);
}
$body .= qq(</ol>\n);

# Menu bar
my $menu = menu_bar();

$body = $menu . $body . $menu;

$template->param("BODY" => $body);
print $template->output;

# Disconnect from the database
$dbh->disconnect;
