#!/usr/bin/perl -wT
# view-album.pl, which allows people to view specific album information.
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

my $album_id = $q->param("album");

# Send a MIME header
print $q->header("text/html");

# ------------------------------------------------------------
# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                       $dbusername, $dbpassword);
die "DBI error from connect: \"$DBI::errstr\"" unless $dbh;

# ------------------------------------------------------------
my $sql = "SELECT CD_TITLE,ARTIST_ID,CD_YEAR,GENRE_ID ";
$sql .= "FROM CD WHERE CD_ID = " . $dbh->quote($album_id);

# Send the query
my $sth = $dbh->prepare($sql);
die "DBI error with prepare: \"$sth->errstr\"" unless $sth;

# Execute the query
$sth->execute;
die "DBI error with execute: \"$sth->errstr\"" unless $sth;

my $album = "";
my $artist_id = 0;
my $year="";
my $gid=0;
my $genre="";
my $artist = "";

# should only return one row
if ($sth->rows) {

   # Iterate through artist IDs and names
   while (my @row = $sth->fetchrow) {
      ($album, $artist_id, $year, $gid) = @row;
   }

   # Finish that database call
   $sth->finish;

} else {
   $body .= "<P>album does not exist!</P>\n";
}

# ------------------------------------------------------------
# Get information about the genre
$sql = "SELECT GENRE_NAME FROM Genre ";
$sql .= "WHERE GENRE_ID = " . $dbh->quote($gid);

# Send the query
$sth = $dbh->prepare($sql);
die "DBI error with prepare: \"$sth->errstr\"" unless $sth;

# Execute the query
my $result = $sth->execute;
die "DBI error with execute: \"$sth->errstr\"" unless $result;

# We should only have received a single row.  Print it out.
if ($sth->rows) {

   # Iterate through artist IDs and names
   while (my @row = $sth->fetchrow) {
      ($genre) = @row;
   }

} else {
    $body .= "<P>Error retrieving artist information!  Aborting.</P>\n";

    $template->param("BODY" => $body);
    print $template->output;

    exit;
}

# ------------------------------------------------------------
# Get information about the artist
$sql = "SELECT ARTIST_NAME FROM Artist ";
$sql .= "WHERE ARTIST_ID = " . $dbh->quote($artist_id);

# Send the query
$sth = $dbh->prepare($sql);
die "DBI error with prepare: \"$sth->errstr\"" unless $sth;

# Execute the query
$result = $sth->execute;
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
$body .= "Artist: $artist<br>\n";
$album = escape($album);
$body .= "CD: $album<br>\n";
$body .= "Year: $year<br>\n";
$body .= "Genre: $genre<br>\n";
$body .= "<HR>\n";

# ------------------------------------------------------------
$sql = "SELECT SONG_ID, SONG_NAME FROM Song ";
$sql .= "WHERE CD_ID = " . $dbh->quote($album_id);
$sql .= " ORDER BY SONG_ID";

# Send the query
$sth = $dbh->prepare($sql);
die "DBI error with prepare: \"$sth->errstr\"" unless $sth;

# Execute the query
$sth->execute;
die "DBI error with execute: \"$sth->errstr\"" unless $sth;

my $sid = "";
my $sname = "";

if ($sth->rows)
{

    $body .= "<ol>\n";
    # Iterate through artist IDs and names
    while (my @row = $sth->fetchrow)
    {
	($sid, $sname) = @row;

        $sname = escape($sname);
	$body .= qq(<li><a name="$sid">$sname</li>\n);
    }

    $body .= "</ol>\n";

    # Finish that database call
    $sth->finish;
}
else
{
    $body .= "<P>album does not exist!</P>\n";
}

# Menu bar
my $menu = menu_bar($artist_id);

$body = $menu . $body . $menu;

$template->param("BODY" => $body);
print $template->output;

# Disconnect from the database
$dbh->disconnect;
