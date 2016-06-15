#!/usr/bin/perl 
# This Perl script generates a LaTeX-format cookbook from a directory tree
# containing recipes, in JPEG or PDF format; a file containing index
# tags for the recipes; and a file containing any size overrides for the
# recipes.
#
# 
#
# Copyright (C) 2016  Brian Pike
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

# We'll use an optional configfile so that I can use the script unmodified
# for my personal project.  It looks just like the lines defining the default
# value of the %config variable.  See http://www.perlmonks.org/?node_id=393426
my $configfile = 'config.pl';
my %config = (
	image_dir => "./sample",
	tag_file  => "./sample/tags.txt",
	sizes_file=> "./sample/sizes.txt",
	pdf_title => "A sample cookbook",
	pdf_author=> "Jane Doe",
	# This is LaTeX for the title page.  It's inside {titlepage} and
	# {center} environments. 
	title_page=><<'END',
\null\vfill
\textit{\Huge \textbf{A sample cookbook}}
\\[\baselineskip]
{\LARGE \textbf{The Doe Family Cookbook}} \\
% Make an integral symbol that's horizontal.
% 109 degrees looks right
\resizebox*{0.3\textwidth}{!}{\rotatebox{109}{$\displaystyle\int$}}
\\
\vfill
\textit{\Large Collected by \textsc{Jane Doe}, et al.
\\[0.1em]
Edited by her children, \textsc{John Doe}, \textsc{William Doe}, \\
\textsc{Fake Name}, and \textsc{Bobby Tables} } 
\vfill
Version 0.6 \\
\today
END
	# This is LaTeX for the back side of the title page. It's inside
	# a {center} environment.
	title_page_reverse=><<'END',
\null
\vfill
Printed by Lulu.com in 
US Letter Hardcover casewrap format
END
	# Consecutive entries in this array list the "directory name"
	# (relative to the image_dir), 
	# and "how the chapter should appear in the book", in the order
	# of how they should appear in the book.
	#
	# Subsections and recipes themselves are sorted alphabetically,
	# or can be rearranged in the LaTeX file. 
	chapters=>[( 
		"main_dishes", "Main Dishes",
		"DRINKS",      "Drinks",
		"starters",    "Starters",
		"side_dishes", "Side Dishes",
		"desserts",    "Desserts",
	)],
);


if (-f $configfile and -r $configfile) {
	print STDERR "Reading config file $configfile\n";
	%config=do $configfile;
} else {
	print STDERR "Using default configuration.\n";
}

# TODO: should probably check configuration? Nah.


# TODO
# Known Issues:
# - because of graphicx limitations, may have some difficulty with image filenames that contain more than one consecutive spaces, or more than one dot? I've used grffile to try to address this, but...


my $tex_head_1 = << 'END';
\documentclass[12pt]{book}
\pdfoutput=1
\usepackage[pdftex]{graphicx}
\usepackage[space]{grffile}
\usepackage{color}
\usepackage{verbatim}
\usepackage{calc}
\usepackage{makeidx}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
% To use this package, we need to disable hyperref, comment \phantomsection, and delete some generated files.  To make room for the indices to appear, we need to increase the margin
%\usepackage{showidx}
\usepackage{hanging}
\usepackage[medium,compact]{titlesec}
%\usepackage{needspace}
\usepackage{rotating}

%  Geometry options from http://texdoc.net/texmf-dist/doc/latex/geometry/geometry.pdf
%    showframe, to display margins on all pages
%    centering, to center horizontally and vertically
%    vcentering, to make top/bottom margins the same [TODO: switch to this]
%\usepackage[letterpaper,text={5.5in,9in},centering,marginparwidth=3cm,marginparsep=0.1cm,showframe]{geometry}
%
% For choosing a gutter, see:
%   http://connect.lulu.com/t5/Suggest/A-gutter-size-calculator/idi-p/34487
%   http://www.thebookdesigner.com/2013/08/book-layouts-page-margins/
%
%% US Letter casewrap
%\usepackage[twoside,pdftex,
%paperwidth=8.25in,paperheight=10.75in,
%bindingoffset=1in,
%% The box we're describing with the margins should include everything.
%includeall,
%outer=1.0in,
%% inner should be figured out automatically, inner:outer=2:3
%top=0.4in,
%bottom=0.4in,
%% bottom should be figured out automatically,
%% Need some footer only because of page number put on pages where chapters begin.
%% Try to have (top/(bottom+footskip))=2/3, which is the default.
%footskip=0.20in,
%verbose,
%heightrounded,
%% No space for margin notes
%marginparwidth=0cm,marginparsep=0.0cm,
%showframe]{geometry}

% US Letter Casewrap
\usepackage[%
twoside,
pdftex,
paperwidth=8.25in,paperheight=10.75in,
% This is probably high
bindingoffset=1.2in,
% The box we're describing with the margins should include everything.
% bottom should be figured out automatically,
% Need some footer only because of page number put on pages where chapters begin.
% Try to have (top/(bottom+footskip))=2/3, which is the default.
textheight=8.30in,
% Setting textheight to various things, we get:
%  textwidth,textheight,number of pages
%  ,10.5in,218,
%  ,10.0in,231,
%  ,9.5in,233,
%  ,9.0in,237,
%  5.24in,8.8in,238,
%  ,8.4in,238,
%  ,8.3in,238,
%  ,8.29in,244,
%  ,8.27in,244,
%  ,8.25in,244,
%  ,8.2in,244,
%  ,8.0in,257,
%  ,7.9in,257,
%  ,7.8in,277,
%  ,7.7in,277,
%  ,7.5in,303,
%  --,7.0in,390 
%
%
textwidth=5.30in,
% 5.24in,240,
% 5.30in,238,
% 5.34in,238,
% 5.44in,238,
% 5.64in,238,
% 5.84in,238,
verbose,
heightrounded,
% No space for margin notes
marginparwidth=0cm,marginparsep=0.0cm
% delete this
%showframe
]{geometry}



% US Trade casewrap, TODO unfinished
%\usepackage[twoside,paperwidth=6in,paperheight=9in,inner=0.8in,outer=0.5in,top=0.6in,bottom=0.6in,verbose,heightrounded,marginparwidth=0cm,marginparsep=0.0cm,showframe]{geometry}



\usepackage[toc]{multitoc}
\usepackage{hyperref}


%%%%%%%%%%%%% Formatting for TOC
% Two columns in TOC
\renewcommand*{\multicolumntoc}{2}
\setlength{\columnseprule}{0.5pt}

% Adjust the indentation of things in the table of contents
\makeatletter
 \renewcommand*\l@section{\@dottedtocline{1}{1.0em}{2.3em}}
 \renewcommand*\l@subsection{\@dottedtocline{2}{2.0em}{3.2em}}
%These indent less and allow more space:
% \renewcommand*\l@section{\@dottedtocline{1}{0.7em}{2.3em}}
% \renewcommand*\l@subsection{\@dottedtocline{2}{1.4em}{3.2em}}
\makeatother

%%%%%%%%%%%%% Formatting for sectioning commands 
% Take the defaults, from
%    http://www.ctex.org/documents/packages/layout/titlesec.pdf
% and modify them a little.
\titleformat{\chapter}[display]
{\normalfont\huge\bfseries}{\chaptertitlename\ \thechapter}{20pt}{\Huge}
\titlespacing*{\chapter} {0pt}{00pt}{25pt}
\titleformat{\section}
{\normalfont\LARGE\bfseries}{\thesection}{1em}{}
\titleformat{\subsection}
{\normalfont\Large\bfseries}{\thesubsection}{1em}{}
%\titlespacing*{\subsection} {0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}
% Require that there not be very much spacing after subsection; otherwise, it looks weird.
\titlespacing*{\subsection} {0pt}{3.25ex plus 1ex minus .2ex}{1.0ex}


% TODO:
%  - How big are these images going to be?  Right now, about 5.65" wide
%  + Add more recipes and index them
%  + Look over index and revise as needed 
%  x choose style of index?
%  + Adjust names of some sections
%  - Look over and adjust any sizes as necessary
%  - Show to siblings 

%%%%%%%%%%%%% Setup PDF data
\hypersetup{
 pdfinfo={
% END tex_head_1
END

my $tex_head_2 = 
"    Title={".$config{pdf_title}."},
   Author={".$config{pdf_author}."}
";

my $tex_head_3 = << 'END';
 }
}

%%%%%%%%%%%%% Page setup.
\parindent0pt
%\parskip5pt
\raggedright
% Want to spread out things on the page. 
%\raggedbottom
\makeindex

\newlength{\mywidth}
%\setlength{\mywidth}{\textwidth-1em}
%\setlength{\mywidth}{\textwidth-0.6em}
\setlength{\mywidth}{5.0in}

% If we have 3x5 index cards scaled to be of width \mywidth, then try to fit
% recipes in a box that allows 1 card wide, 2 cards high.
\newcommand{\putpicture}[1]%
{\noindent\null\hfill\includegraphics[width=\mywidth,height=1.2\mywidth,keepaspectratio=true]{#1}\hfill\null\\[0.01in]}

\newcommand{\putpicturesize}[2]%
{\noindent\null\hfill\includegraphics[#2]{#1}\hfill\null\\[0.01in]}

\newcommand{\starttypeofrecipe}[1]%
{ \chapter{#1}%
}

\newcommand{\startsubtypeofrecipe}[1]%
{ \section{#1}%
}

\newcommand{\startrecipe}[1]%
{ \subsection{#1}%
}

% Want to visually spread-out things on the page by inserting space at the
% end of a recipe.
% Try 1:
% Doing either \vfill or \vspace{\fill} increased page count by some 20 pages,
% apparently trying to make everything look better overall.
% Symptoms: 1 image recipe on page n, 2 image recipe on page n+1, with the
% first image on n+1 clearly having enough space to fit on page n.
%
% Try 2:
% Doing {} here results in big gaps at the beginning of chapters and certain
% sections, b/c they have rubber space and we don't have any here.
%
% Try 3: Allow a small amount of rubber space, but by default don't put any space.
% This seems to work.
\newcommand{\finishrecipe}%
{\vspace{0.0ex plus 10.0ex}}

%%%%%%%%%%% The first definition prints some paragraph in the margin, while
%%%%%%%%%%% the second does nothing.  We use this to list the index tags that
%%%%%%%%%%% are being used, right next to the associated recipe.
%\newcommand{\maybemarginpar}[1]%
%{\marginpar{\raggedright\small\begin{hangparas}{5pt}{1}%
%#1%
%\end{hangparas}}}

\newcommand{\maybemarginpar}[1]%
{}


\title{TODO SHOULD NOT SHOW UP}
\author{TODO SHOULD NOT SHOW UP}
\date{\today}

\begin{document}
\frontmatter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\begin{titlepage}
% This list of sample title pages was useful:
%    ftp://ftp.tex.ac.uk/tex-archive/info/latex-samples/TitlePages/titlepages.pdf
\begin{center}
END

my $tex_head_4 = $config{title_page};

my $tex_head_5 = << 'END';
\end{center}
\end{titlepage}
%\clearpage

\begin{center}
END

my $tex_head_6 = $config{title_page_reverse};

my $tex_head_7 = << 'END';
\end{center}
\clearpage




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Source: http://www.latex-community.org/forum/viewtopic.php?f=45&t=8259
% TODO: only make the TOC show up in the PDF?
\cleardoublepage
\phantomsection

%\newgeometry{twoside,bindingoffset=1in,
%includeall,
%outer=0.8in,
%top=0.4in,
%bottom=0.4in,
%footskip=0.05in,
%heightrounded,showframe}
\addcontentsline{toc}{chapter}{Contents}
\tableofcontents
\restoregeometry
\mainmatter
% END tex_head
END

my $tex_foot = << 'END';
% START tex_foot
\backmatter
\cleardoublepage
\phantomsection
\addcontentsline{toc}{chapter}{Index}
\printindex
\end{document}
END

sub delete_extra_spaces {
	return ((shift(@_) =~ s/^ *//gr) =~ s/ *$//gr);
}

sub read_tags {
	# Format of file:
	#  recipe_filename:indexvalue1:indexvalue2:...
	#  #comment that will be ignored
	# Extra spaces at start and end of filenames and indexvalues will be removed.
	my $filename = shift(@_);
	my %tmphash = ();
	my $key;
	open(my $fh,"<",$filename) or die $!;
	LINE: while (my $row = <$fh>) {
		chomp $row;
		next LINE if ($row =~ /^#/);
		my @parts = split(/:/,$row);
		warn "Error in parsing line: $row\n" if (scalar(@parts)<=1);
		$key=delete_extra_spaces(shift(@parts));
		@parts=map(delete_extra_spaces($_),@parts);
		$tmphash{$key}=\@parts;
		#print "Processed \"$row\" into key \"$key\" and values ",join('/',@{$tmphash{$key}}),"\n";
	}
	close($fh);
	return %tmphash;
}

sub get_list_of_dirs {
	opendir(BASEDIR,$config{image_dir}) or die $!;
	while (my $basefile = readdir(BASEDIR)) {
		# Take only the directories, not beginning with a "."
		next if ($basefile =~ m/^\./);
		next unless (-d ($config{image_dir}."/".$basefile));
		print "\"$basefile\",\n";
	}
	closedir(BASEDIR);
}

sub replace_underlines_with_spaces {
	return (shift(@_) =~ s/_/ /gr);
#	return (map { s/_/ /gr } @_);
}

sub sanitize_ampersands {
	return (shift(@_) =~ s/&/\\&/gr);
}
sub sanitize_image_fnames {
	my $fname=shift(@_);
	# Graphicx has a problem with spaces in filenames, see http://tex.stackexchange.com/questions/4129/how-to-avoid-showing-the-filename-when-using-graphicx
	# Fix is to do:   "my file".jpg
	# Also need to replace "&" with "\string&"
	$fname =~ s/&/\\string&/g;
	my @fnamparts=split(/\./,$fname);
	my $extension=pop(@fnamparts);
	return ("\"".join(".",@fnamparts)."\".".$extension);
#
#	return (shift(@_) =~ s/&/\\string&/gr);
}

sub handle_dir_of_recipes {
	my $dir=shift(@_);
	# A hash reference, so we can delete keys once they're used.
	my $tagsleftref=shift(@_);
	my $sizesleftref=shift(@_);

	opendir(CURDIR,$dir) or die $!;
 	# Read the directory, get only the files ending in ".jpeg", ".jpg", or ".pdf"
	my @files = map {
		(not(-d "$dir/$_") and ($_ =~ m/\.jpe?g$/ or $_ =~ m/\.pdf$/))
			? $_ : ()
	} readdir(CURDIR);
	closedir(CURDIR);
	# Sort alphabetically without regard to case
	@files = sort {uc($a) cmp uc($b)} @files;

	my ($fname,$fnamewithoutextension,$fnamewithpath,$pretty_recipe_name,$tmpidx,$recipes_printed);
	$recipes_printed=0;
	# Now, iterate through the files.
	foreach $fname (@files) {
		$fnamewithpath="$dir/$fname";

		# We need to detect sequences of files, which may look like:
		#   Frozen Turkey Pies 1.jpg
		#   Frozen Turkey Pies 2.jpg
		# or
		#   Barbecued Hamburgers One.jpg    (just one recipe)
		#   Barbecued Hamburgers Two A.jpg  (next two are a pair)
		#   Barbecued Hamburgers Two B.jpg
		# First strip the file extension and replace _ with spaces
		$fnamewithoutextension = (($fname =~ s/.jpe?g$//r) =~ s/.pdf$//r);
		$pretty_recipe_name = replace_underlines_with_spaces($fnamewithoutextension);
		# If it ends in a "1" or "A" or does not end in a number or single letter (like ...One.jpg above), then it is the first image in the recipe.
		if ($pretty_recipe_name=~ m/ 1$/ or $pretty_recipe_name=~ m/ A$/ or not($pretty_recipe_name=~ m/ [\dA-Z]$/)) {
			$pretty_recipe_name = sanitize_ampersands ($pretty_recipe_name =~ s/ [A1]$//r);
			# Do we first need to end a recipe?
			if ($recipes_printed>0) {
				print "\\finishrecipe\n";
			}
			print "\n\\startrecipe{",$pretty_recipe_name,"}\n";
			$recipes_printed=$recipes_printed+1;

			# Now handle index entries.
			if (exists($tagsleftref->{$pretty_recipe_name})) {
				foreach $tmpidx (@{$tagsleftref->{$pretty_recipe_name}}) {
					print "  \\index{",$tmpidx,"}\n";
				}
				# For editing purposes, provide a way to list the index thingies in the margin; the package showidx doesn't work very well.
				#print "  \\cprotect\\maybemarginpar{\\begin{Verbatim}[fontsize=\\small]\n",join("\n",@{$tagsleftref->{$pretty_recipe_name}}),"\n\\end{Verbatim}}\n";
				print "  \\maybemarginpar{%\n",join("\\\\\n",@{$tagsleftref->{$pretty_recipe_name}}),"%\n}\n";
				# Delete the data, then the key
				$tagsleftref->{$pretty_recipe_name}=0;
				delete $tagsleftref->{$pretty_recipe_name};
			} else {
				print STDERR "No tags for:$pretty_recipe_name\n";
			}  
		}
		if (exists($sizesleftref->{$fnamewithoutextension})) {
			print "  \\putpicturesize{",sanitize_image_fnames($fnamewithpath),"}{", join(",",@{$sizesleftref->{$fnamewithoutextension}}),"}\n";
			# Delete the data, then the key
			$sizesleftref->{$fnamewithoutextension}=0;
			delete $sizesleftref->{$fnamewithoutextension};
		} else {
			print "  \\putpicture{",sanitize_image_fnames($fnamewithpath),"}\n";
		}
	}
	if ($recipes_printed>0) {
		print "\\finishrecipe\n";
	}
}

sub handle_toplevel_dir {
	# A toplevel directory will usually contain only directories, in which case
	#   toplevel is a chapter, subdirs are sections, recipes are subsections
	# If it has no directories in it, then
	#   toplevel is a chapter, recipes are subsections
	my $dir=shift(@_);
	my $toplevelname=shift(@_);
	# A hash reference, so we can delete keys once they're used.
	my $tagsleftref=shift(@_);
	my $sizesleftref=shift(@_);

	opendir(CURDIR,$dir) or die $!;
 	# Read the directories from the toplevel directory.  Skip those beginning with .
	my @subdirs = map {
		(-d "$dir/$_" and not($_ =~ m/^\./)) ? $_ : ()
	} readdir(CURDIR);
	closedir(CURDIR);
	# Sort alphabetically?
	@subdirs = sort {uc($a) cmp uc($b)} @subdirs;

	print "\n\\starttypeofrecipe{",replace_underlines_with_spaces($toplevelname),"}\n";
	if ((scalar(@subdirs))==0) {
		# No subtype here!
		handle_dir_of_recipes($dir, $tagsleftref, $sizesleftref);
	} else {
		my $subtype;
		foreach $subtype (@subdirs) {
			print "\n\\startsubtypeofrecipe{",replace_underlines_with_spaces($subtype),"}\n";
			handle_dir_of_recipes($dir . "/" . $subtype, $tagsleftref, $sizesleftref);

		}
	}
}


# First slurp the tags.
my %tagsleft=read_tags($config{tag_file});
my %sizesleft=read_tags($config{sizes_file});

# Write the LaTeX file.
# Header:
print $tex_head_1,$tex_head_2,$tex_head_3,$tex_head_4,$tex_head_5,$tex_head_6,$tex_head_7;
# Body:
for (my $i=0; $i<scalar(@{$config{chapters}}); $i+=2) {
	my $dirname = $config{image_dir}."/".($config{chapters}[$i]);
	my $chaptername = $config{chapters}[$i+1];
	print STDERR "Using directory \"",$dirname,"\" to write chapter \"",$chaptername,"\"\n";
	handle_toplevel_dir(
		$config{image_dir}."/".($config{chapters}[$i]),
		$config{chapters}[$i+1],
		\%tagsleft,
		\%sizesleft);
}
# Footer:
print $tex_foot;

# Check if there are any tags we never used!
foreach (sort(keys(%tagsleft))) {
	print STDERR "Tag unused :",$_,"\n";
}
foreach (sort(keys(%sizesleft))) {
	print STDERR "Size unused :",$_,"\n";
}

exit 0;

