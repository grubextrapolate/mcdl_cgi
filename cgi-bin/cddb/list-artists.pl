#!/usr/bin/perl -wT
# This is list-artists.pl, which lists the artists
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

# Send a MIME header
print $q->header("text/html");

$body .= "<H1>Select an artist</H1>\n";

$body .= "<P>Clicking on an artist will display all releases ";
$body .= "in the archive.</P>\n";

# ------------------------------------------------------------
# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                       $dbusername, $dbpassword);
die "DBI error from connect: ", $DBI::errstr unless $dbh;

my $sql = "SELECT ARTIST_ID,ARTIST_NAME FROM Artist ORDER BY ARTIST_NAME";

# Send the query
my $sth = $dbh->prepare($sql);
die "DBI error with prepare:", $sth->errstr unless $sth;

# Execute the query
my $result = $sth->execute;
die "DBI error with execute:", $sth->errstr unless $result;

# If we received artists from the SELECT, print them out
if ($sth->rows) {

   $body .= "<ul>\n";

   # Iterate through artist IDs and names
   while (my @row = $sth->fetchrow) {
      my ($aid, $aname) = @row;
      $aname = escape($aname);
      $body .= qq(  <li><a href="$cgidir/view-artist.pl?artist=$aid">$aname</a></li>\n);
   }

   $body .= "</ul>\n";

} else {
   $body .= "<P>No artists to display!</P>\n";
}

# Finish that database call
$sth->finish;

# Menu bar
my $menu = menu_bar();

$body = $menu . $body . $menu;

$template->param("BODY" => $body);
print $template->output;

# Disconnect from db
$dbh->disconnect;
