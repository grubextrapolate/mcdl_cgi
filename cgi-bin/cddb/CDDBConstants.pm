#!/usr/bin/perl -wT
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

# Declare some commonly used variables
use vars qw($dbdatabase $dbserver $dbport $dbusername $dbpassword $tmpldir $tmplfile $cgidir $htmldir $pagetitle);

$dbdatabase = "MCDL_DB_NAME";
$dbserver = "MCDL_DB_HOST_OR_IP";
$dbport = "3306";
$dbusername = "MCDL_DB_USR";
$dbpassword = "MCDL_DB_PASSWORD";

# this is a full path to the directory where you have your templates
$tmpldir = "/var/www/html/templates";

# name of the template file to use (located in the above directory)
$tmplfile = "sample.tmpl";

# these directories are relative to your document root
$cgidir = "/cgi-bin/cddb";
$htmldir = "/cddb";

# this will become the title element for all html pages
$pagetitle = "My CD Library";

my $escape;
sub escape {
   my $ret = shift;

   $ret =~ s/& /&amp; /g;
   $ret =~ s/</&lt;/g;
   $ret =~ s/>/&gt;/g;

   return $ret;
}

# Exit normally;
1;

