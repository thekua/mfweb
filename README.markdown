# mfweb

These scripts are a subset of the scripts I use for building
martinfowler.com. They are here on github to help with collaborating
with colleagues who are writing articles for martinfowler.com. As such
they aren't intended as a library for general use, although you're
welcome to give them a spin if you so wish.

##Using the scripts

The top level folders are:

- `lib` contains the ruby scripts 
- `lib\mfweb\core` scripts required for various parts of the web site
- `lib\mfweb\article` scripts to turn article files into html
- `sample` an example website to show how it builds. Build it by going into the sample directory and invoke `rake`
- `css` css files used for these parts of the web site.
- `test` some unit tests (see below)

My full web site contains many more scripts than this, I've just
pulled out those scripts required for collaboration.

To perform a build you'll need to have ruby and rake installed. You
can then just issue `rake` to build the articles. In addition to ruby
and rake you will need some gems too. I've been lazy about tracking
which actual ones you need (I really ought to sort things out with
builder) but you'll certainly need Nokogiri, Kramdown, and Builder. The scripts
should work on ruby 1.8.7 and ruby 1.9.

To start on an article, copy the sample article in
`sample\articles\simple` and write away. Any xml file in
`sample\articles\simple` will be transformed to an html file in `build/articles`

Note for code examples, the code can be auto-imported from any source
file. I find this very handy as I can put my actual source files, do
compiles and tests, and just use the comment annotations to mark bits
of code to incorporate into the text.

## Digging in the Code

If you want to dig around in the code that generates things, here's a
few signposts

The entry point for transforming an article xml file into html is
ArticleMaker (in `lib/mfweb/article`). Its task is to coordinate the various
objects that do most of the work. This is set up for each paper in the
rakefile.

First of these is the PageSkeleton, which you set up with the header,
footer, and css information. It writes these things out and hands over
to the PaperTransformer which actually does most of the work. (There
is also a PatternTransformer which is used for patterns done in my
template.)

The paper transformer is a subclass of transformer (in
`lib\mfweb\core`), which is a general class for transforming xml
documents into html. The transformer walks the tree of the xml
document. Most behavior is defined by creating methods named
handle_elementName for each element you want to do something with.
Handle methods usually do some specific things for that element and at
some point call `apply` which continues the walk down to the children.

Any html output is done through an instance of HtmlEmitter, present
through the instance variable `@html`. HtmlEmitter has a range of
methods to emit common html elements, together with general methods
`element_block` and `element_span` to spit out any named with elements
with or without surrounding newlines. You can also send raw output to
the HtmlEmitter with `<<`.

Although the handle_* methods give you the most control about
processing an XML element, there are some common cases that have short
cuts. The transformer parent class defines some lists `@ignore_set`,
`@copy_set`, `@p_set` and `@span_set` for these shortcut behaviors.

If you want to do some specialized transforming of some particular
element structure, it's often easiest to make your own transformer
subclass and call it during the tree walk. See how processing the
abstract in `handle_abstract` leads to calls into a separate
FrontMatterTransformer to print things like the table of contents and
author lists.

Various more complicated operations are done by separate service
objects which are defined on the PaperMaker which passes itself as a
service locator to the transformer. These include PatternServer (for
pattern reference lookups), CodeServer (for code extraction),
Bibliography (for citations), FootnoteServer (for footnotes).

There aren't many tests in here. These are limited since I have a fast and
simple functional test system (generate the entire web site, and diff
it with a known good output site.)
