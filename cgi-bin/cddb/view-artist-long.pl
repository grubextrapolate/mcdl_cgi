#!/usr/bin/perl -wT
# view-artist-long.pl, shows all info on all albums by artist
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

# ------------------------------------------------------------
# Create an instance of CGI
my $q = new CGI;

my $artist_id = $q->param("artist");

# Send a MIME header
print $q->header("text/html");

# ------------------------------------------------------------
# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                       $dbusername, $dbpassword);
die "DBI error from connect: \"$DBI::errstr\"" unless $dbh;

# ------------------------------------------------------------
my $artist = "";

# Get information about the artist
my $sql = "SELECT ARTIST_NAME FROM Artist ";
$sql .= "WHERE ARTIST_ID = " . $dbh->quote($artist_id);

# Send the query
my $sth = $dbh->prepare($sql);
die "DBI error with prepare: \"$sth->errstr\"" unless $sth;

# Execute the query
my $result = $sth->execute;
die "DBI error with execute: \"$sth->errstr\"" unless $result;

# We should only have received a single row.  Print it out.
if ($sth->rows) {

   # Iterate through artist IDs and names
   while (my @row = $sth->fetchrow) {
      ($artist) = @row;
   }

} else {
    $body .= "<P>Error retrieving artist information!  Aborting.</P>\n";

    $template->param("BODY" => $body);
    print $template->output;

    exit;
}

$artist = escape($artist);
$body .= "<H1>Artist: $artist</H1>\n";
$body .= "<HR>\n";

# ------------------------------------------------------------
$sql = "SELECT CD_ID, CD_TITLE, CDDB_ID, CD_YEAR FROM CD ";
$sql .= "WHERE ARTIST_ID = " . $dbh->quote($artist_id);
$sql .= " ORDER BY CD_YEAR, CD_TITLE";

# Send the query
$sth = $dbh->prepare($sql);
die "DBI error with prepare: \"$sth->errstr\"" unless $sth;

# Execute the query
$sth->execute;
die "DBI error with execute: \"$sth->errstr\"" unless $sth;

# If we received albums from the SELECT, print them out
if ($sth->rows) {

   $body .= "<ul>\n";

   # Iterate through artist IDs and names
   while (my @row = $sth->fetchrow) {
      my ($id, $album, $cddb, $year) = @row;

      $album = escape($album);
      $body .= qq(  <li><a href="$cgidir/view-album.pl?album=$id">$album</a> ($year)\n);

      # ------------------------------------------------------------
      $sql = "SELECT SONG_ID, SONG_NAME FROM Song ";
      $sql .= "WHERE CD_ID = " . $dbh->quote($id);
      $sql .= " ORDER BY SONG_ID";

      # Send the query
      my $sth2 = $dbh->prepare($sql);
      die "DBI error with prepare: \"$sth2->errstr\"" unless $sth2;

      # Execute the query
      $sth2->execute;
      die "DBI error with execute: \"$sth2->errstr\"" unless $sth2;

      my $sid = "";
      my $sname = "";

      if ($sth2->rows) {

         $body .= "  <ol>\n";
         # Iterate through artist IDs and names
         while (my @row = $sth2->fetchrow) {
            ($sid, $sname) = @row;
            $sname = escape($sname);
            $body .= "    <li>$sname</li>\n";
         }

         $body .= "  </ol>\n";

         # Finish that database call   
         $sth2->finish;
      } else {
         $body .= "<P>album does not exist!</P>\n";
      }

   }

   $body .= "</ul>\n";

   # Finish that database call
   $sth->finish;

} else {
   $body .= "<P>There are currently no albums here.</P>\n";
}

# Menu bar
my $menu = menu_bar($artist_id);

$body = $menu . $body . $menu;

$template->param("BODY" => $body);
print $template->output;

# Disconnect from the database
$dbh->disconnect;
