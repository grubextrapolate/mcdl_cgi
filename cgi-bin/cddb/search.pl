#!/usr/bin/perl -wT
# search.pl, which allows people to search through the database
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

# Remove buffering
$| = 1;

my $body = "";

# open the html template
my $template = HTML::Template->new(filename => "$tmpldir/$tmplfile");

# fill in some parameters
my $mtime = localtime((stat $0)[9]);
$template->param("MOD_TIME" => $mtime);
$template->param("TITLE" => $pagetitle);

my $album_id = "";
my $artist_id = "";
my $album = "";
my $sid = "";
my $artist_name = "";
my $name = "";

# ------------------------------------------------------------
# Create an instance of CGI
my $q = new CGI;

my $term = $q->param("term");
my $type = $q->param("type");

# Send a MIME header
print $q->header("text/html");

$body .= "<H1>Search results</H1>\n";

# ------------------------------------------------------------
# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                       $dbusername, $dbpassword);
die "DBI error from connect: \"$DBI::errstr\"" unless $dbh;

my $sql = "";

# search for items with any match?
if ($type eq "all") {

   # Remove SQL regexp characters
   $term =~ s|%|\\\%|g;
   $term =~ s|_|\\\_|g;
   $term = $dbh->quote("%$term%");

   $sql = "SELECT A.ARTIST_ID, A.ARTIST_NAME, C.CD_ID, ";
   $sql .= "C.CD_TITLE, S.SONG_ID, S.SONG_NAME ";
   $sql .= "FROM CD C, Artist A, Song S ";
   $sql .= "WHERE (S.SONG_NAME LIKE $term ";
   $sql .= "OR A.ARTIST_NAME LIKE $term ";
   $sql .= "OR C.CD_TITLE LIKE $term) ";
   $sql .= "AND C.ARTIST_ID = A.ARTIST_ID ";
   $sql .= "AND S.CD_ID = C.CD_ID ";
   $sql .= "ORDER BY A.ARTIST_NAME, C.CD_TITLE";

} elsif ($type eq "song") {

   # Remove SQL regexp characters
   $term =~ s|%|\\\%|g;
   $term =~ s|_|\\\_|g;
   $term = $dbh->quote("%$term%");

   $sql = "SELECT A.ARTIST_ID, A.ARTIST_NAME, C.CD_ID, ";
   $sql .= "C.CD_TITLE, S.SONG_ID, S.SONG_NAME ";
   $sql .= "FROM CD C, Artist A, Song S ";
   $sql .= "WHERE S.SONG_NAME LIKE $term ";
   $sql .= "AND C.ARTIST_ID = A.ARTIST_ID ";
   $sql .= "AND S.CD_ID = C.CD_ID ";
   $sql .= "ORDER BY A.ARTIST_NAME, C.CD_TITLE";

} elsif ($type eq "album") {

   # Remove SQL regexp characters
   $term =~ s|%|\\\%|g;
   $term =~ s|_|\\\_|g;
   $term = $dbh->quote("%$term%");

   $sql = "SELECT A.ARTIST_ID, A.ARTIST_NAME, C.CD_ID, ";
   $sql .= "C.CD_TITLE ";
   $sql .= "FROM CD C, Artist A ";
   $sql .= "WHERE C.CD_TITLE LIKE $term ";
   $sql .= "AND C.ARTIST_ID = A.ARTIST_ID ";
   $sql .= "ORDER BY A.ARTIST_NAME, C.CD_TITLE";

} elsif ($type eq "artist") {

   # Remove SQL regexp characters
   $term =~ s|%|\\\%|g;
   $term =~ s|_|\\\_|g;
   $term = $dbh->quote("%$term%");

   $sql = "SELECT A.ARTIST_ID, A.ARTIST_NAME ";
   $sql .= "FROM Artist A WHERE A.ARTIST_NAME LIKE $term ";
   $sql .= "ORDER BY A.ARTIST_NAME";
}

# Send the query
my $sth = $dbh->prepare($sql);
die "DBI error with prepare: \"$sth->errstr\"" unless $sth;

# Execute the query
$sth->execute;
die "DBI error with execute: \"$sth->errstr\"" unless $sth;

# We should only have received a single row.  Print it out.
if ($sth->rows) {

   $body .= "<ul>\n";

   # Iterate through artist IDs and names
   while (my @row = $sth->fetchrow) {

      if (($type eq "all") || ($type eq "song")) {
         ($artist_id, $artist_name, $album_id, $album, $sid, $name) = @row;

         $artist_name = escape($artist_name);
         $album = escape($album);
         $name = escape($name);
         $body .= qq(  <li><a href="$cgidir/view-artist.pl?artist=);
         $body .= qq($artist_id">$artist_name</a>, );
         $body .= qq(<a href="$cgidir/view-album.pl?album=$album_id">);
         $body .= qq($album</a> );
         $body .= qq($name</li>\n);
      } elsif ($type eq "album") {
         ($artist_id, $artist_name, $album_id, $album) = @row;

         $artist_name = escape($artist_name);
         $album = escape($album);
         $body .= qq(  <li><a href="$cgidir/view-artist.pl?artist=);
         $body .= qq($artist_id">$artist_name</a>, );
         $body .= qq(<a href="$cgidir/view-album.pl?album=$album_id">);
         $body .= qq($album</a></li>\n);
      } elsif ($type eq "artist") {
         ($artist_id, $artist_name) = @row;

         $artist_name = escape($artist_name);
         $body .= qq(  <li><a href="$cgidir/view-artist.pl?artist=);
         $body .= qq($artist_id">$artist_name</a></li>\n);
      }
   }

   $body .= "</ul>\n";

} else {
   $body .= "<P>No matches.</P>\n";
}

# Finish that database call
$sth->finish;

# Menu bar
my $menu = menu_bar();

$body = $menu . $body . $menu;

# Disconnect from the database
$dbh->disconnect;

$template->param("BODY" => $body);
print $template->output;
