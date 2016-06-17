# cookbook_generator
A Perl script that generates a cookbook (in LaTeX) from a directory tree of recipe images, and some metadata.  The main design goals were:
 * allow less technical users to organize the recipes
 * allow a comprehensive index for the recipes
 * allow multi-image recipes, using both PDF and JPEG images
 * generate attractive and professional output, appropriate for self-publishing
 * If a recipe is written on a 5x7 note card (that is, 5 inches by 7 inches), then that size should be maintained *as much as reasonable* in the final book.  For instance, you should be able to photocopy a page from the book, cut out the images, and paste them on 5x7 note cards.

## Usage
```
./cookbookgen.pl > sample.tex
pdflatex sample.tex
makeindex sample.idx
pdflatex sample.tex
pdflatex sample.tex
```
Then view [`sample.pdf`](sample-output.pdf).

## Configuration
By default, [`cookbookgen.pl`](cookbookgen.pl) uses the built-in configuration data, which generates a sample cookbook using the fake recipes put in the [`sample/`](sample/) directory.  If it finds a file called `config.pl`, then it will use that configuration data instead; see the [`cookbookgen.pl`](cookbookgen.pl) for details on how to make your own `config.pl`.

The configuration data specifies:
* the base directory of the images
* the location of the metadata files (indexing data, size overrides)
* PDF file metadata (author, title)
* a LaTeX snippet to specify the contents of the title page
* a LaTeX snippet to specify the contents of the back side of the title page
* a list of the various chapters and where their images may be found, relative to the base directory 

## Images?  Don't you mean recipes?
Images may be single-page PDFs or JPEG/JPG images, and are embedded in the resulting PDF file.  The name of the image is cleaned up slightly and used as the name of the recipe.  For example, a file named `Hot chOcOLate.jpg` or `Hot_chOcOLate.pdf` would result in a recipe named "Hot chOcOlate". 

A sequence of images may be used for a single recipe.  For example, having files named
```
Hot Chocolate 1.jpg
Hot Chocolate 2.jpg
Hot Chocolate 3.jpg
```
or
```
Hot Chocolate A.jpg
Hot Chocolate B.jpg
Hot Chocolate C.jpg
```
will each result in a 3-image recipe named `Hot Chocolate`.  The images are used in alphabetical order, and the extension and the (optional) single-digit sequencing indicator are stripped to find the name of the recipe.

## How are recipes arranged into chapters?
Consider a directory tree of the form:
```
app/
app/b.jpg
app/foo/
app/foo/e.jpg
app/foo/d_1.jpg
app/foo/d_2.jpg
app/bar/
app/bar/f.pdf
desserts/
desserts/Ice_cream.jpg
desserts/Chocolate Steak.pdf
```
where the configuration data says that the chapters are "Desserts and Yummies!" (pulled from `desserts/`) and then "Appetizers and more stuff" (pulled from `app/`).  Then the cookbook would be arranged as:

1. Table of contents
2. "Desserts and Yummies!" (chapter 1)
  1. "Chocolate Steak" (subsection 1.0.1, and a 1-image recipe)
  2. "Ice cream" (subsection 1.0.2, and a 1-image recipe)
3. "Appetizers and more stuff" (chapter 2)
  1. "bar" (section 2.1)
    1. "f" (subsection 2.1.1, and a 1-image recipe)
  2. "foo" (section 2.2)
    1. "d" (subsection 2.2.1, and a 2-image recipe)
    2. "e" (subsection 2.2.2, and a 1-image recipe)
4. The index

Thus:
* a chapter directory __with no subdirectories__ will have no sections, only a list of recipes.
* a chapter directory __with subdirectories__ will have its subdirectories treated as sections.  Sections are listed alphabetically.  Each section will contain a list of recipes.  (Note that files directly in the chapter directory, such as `app/b.jpg`, are ignored.)
* Each list of recipes is sorted alphabetically by the name of the recipe.
* Each recipe is placed in its own subsection.

## Metadata?
This program uses metadata for two purposes, indexing and sizing.

### Indexing
To allow comprehensive indexing of the recipes, we must "tag" the recipes with indexing data.  This information is stored within a "tag file".  For more information, see [the sample tag file](sample/tags.txt) and [documentation of LaTeX's indexing facility](https://en.wikibooks.org/wiki/LaTeX/Indexing#Sophisticated_indexing).

The program __gives warnings on stderr__ for each recipe that is not listed in the tag file (e.g., `No tags for:Extra tall recipe`).  If you have any such recipes, or are just getting started, then 
```
./cookbookgen.pl 2>&1 >/dev/null |egrep '^No tags for' |awk -F: '{print $2":"}' >> tag_file.txt
```
can be used to add blank lines for these recipes to the `tag_file.txt`.

The program also __gives warnings on stderr__ for each tag that is not used in the LaTeX file (e.g., `Tag unused :Foo`).

### Custom sizing
A few image files may be strangely sized, such as [a few images in the `sample/starters/Weird sizes` directory](sample/starters/Weird sizes).  These may need to be given custom sizes so that the book looks good and paginates well.  This is completely optional.  See [the sample sizing file](sample/sizes.txt) for more information.

The program __gives warnings on stderr__ for each size that is not used in the LaTeX file (e.g., `Size unused :Foo`).

##### How do I find oddly-sized images?
It can be useful to generate a list of image files, sorted by their height:width ratio.  An example script that uses `identify` (from ImageMagick) is:
```
# Generate a list of files in a directory.  For each, find the file size.
#
# Ignore files named .directory created by KDE...
find directory_of_images/ -type f ! -name .directory -print0 |xargs -0 -L 1 identify > list_of_images.txt
# This file has lines that can look like:
#   ./Appetizers/Aunt J's Encrusted Brie 2.jpg JPEG 1748x1085 1748x1085+0+0 8-bit sRGB 299KB 0.000u 0:00.000
# for JPEGs or
#   Turkey.pdf PBM 360x216 360x216+0+0 16-bit Bilevel Gray 9.78KB 0.000u 0:00.000
#   Lasagna.pdf[0] PBM 360x216 360x216+0+0 16-bit Bilevel Gray 9.78KB 0.000u 0:00.000
#   Lasagna.pdf[1] PBM 360x216 360x216+0+0 16-bit Bilevel Gray 9.78KB 0.000u 0:00.000
# for PDFs (the [number] indicates the page number of a multi-page PDF)
# Note that it is (width)x(height)
#
# Now sort by the ratio of height:width.
(/bin/echo -e "Recall: height/width would be\n0.6000000 for a 3x5 index card\n0.6666666 for a 4x6 index card\n0.7142857 for a 5x7 index card\n\nheight/width\twidth\theight\tfilename\n============\t=====\t======\t========"; \
perl -ne 'if (m/^(.*) (JPEG|PBM) (\d+)x(\d+) .*$/) {print sprintf("%.7f",($4/$3)),"\t$3\t$4\t$1\n";}' list_of_images.txt | sort -rn ) \
|less
```

## How can I type my recipes?
I had a few recipes that were written on scratch paper.  I wanted to type these in a format that would match the 5x7 cards that constituted most of my source material.
 
There are [many ways to write recipes in LaTeX](http://tex.stackexchange.com/questions/20549/a-cookbook-in-latex), but none of them seemed to match my criteria, so I made my own.

The source is available in [latex_recipe_template/](latex_recipe_template).  For instance, the [latex_recipe_template/Hot_Chocolate.tex](latex_recipe_template/Hot_Chocolate.tex) file results in [this PDF file](sample/DRINKS/Kid-friendly/Hot_Chocolate_1.pdf).

This method can produce multi-page PDFs, which must be split before they can be included in the book.  For this, I use the `pdfseparate` (in Debian, this is in the `poppler-utils` package).

