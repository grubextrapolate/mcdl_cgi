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

# Menu bar
sub menu_bar(;$) {
    my $aid = shift;
    if (!$aid) { $aid = ""; }
    my $ret = "";

    $ret .= "<P>\n";

    if ($aid ne "") {
       # Send the user to the posting form
       $ret .= qq(<a href="$cgidir/view-artist.pl?artist=$aid">[view this artist]);
       $ret .= qq(</a>\n);

       # Send the user to the posting form
       $ret .= qq(<a href="$cgidir/view-artist-long.pl?artist=$aid">[view this artist (long)]);
       $ret .= qq(</a>\n);
    }

    # Send the user to the artist list
    $ret .= qq(<a href="$cgidir/list-artists.pl">[view all artists]</a>\n);

    # Send the user to the artist list
    $ret .= qq(<a href="$cgidir/view-all.pl">[view all albums]</a>\n);

    # Send the user to the artist list
    $ret .= qq(<a href="$cgidir/view-everything.pl">[view all albums and songs]</a>\n);

    # Send the user to the artist list
    $ret .= qq(<a href="$cgidir/stats.pl">[stats]</a>\n);

    # Send the user to the search
    $ret .= qq(<a href="$htmldir/search-form.shtml">[search]</a>\n);

    # Give a plug for the ATF and home
    $ret .= qq(<a href="http://www.lerner.co.il/atf/">[ATF]</a>\n);

    # Home link
#    $ret .= qq(<a href="$htmldir">[home]</a>\n);

    $ret .= "</P>\n";

    return $ret;
}

1;
