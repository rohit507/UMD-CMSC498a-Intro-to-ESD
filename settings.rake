#########################################
#                                       #
#   Name : settings.rake                #
#   About : Build automation document   #
#           with constants used by      #
#           primary and secondary       #
#           rakefiles.                  #
#                                       #
#########################################

# Preprocessor Options
$PP = "gpp"

    # Options for initial .pp to .ppmd pass
    $PPMACRO_PRE = "#{$ROOT_DIR}style/ppmd.gpp"
    $PPOPTS_PRE = '-U "@" "\n" "(" "," ")" "(" ")" "#" "" ' +
                  '+ciic "@@" "\n" +ciic "@>" "<@" +siqi "\"" "\"" "\\\\" ' +
                  "--include #{$PPMACRO_PRE}"

    # Options for final .tex to .pptex pass
    $PPMACRO_POST =  "#{$ROOT_DIR}style/pptex.gpp"
    $PPOPTS_POST = '-U "$" "\n" "(" "," ")\n" "(" ")" "#" "" ' +
                  "--include #{$PPMACRO_POST}"

# Latex Creator Options
$LC = "pandoc"

    # Template Files 
    $LCTEMPLATE_FILE = "#{$ROOT_DIR}style/pandoc-template.tex"
    $LCHEADER_FILE = "#{$ROOT_DIR}style/header.tex"

    # Bibiography and Citation Style Files
    $LCBIB_FILE = "#{$ROOT_DIR}src/Bibliography/Citations.bib"
    $LCCSL_FILE = "#{$ROOT_DIR}src/Bibliography/style.csl"

    # Standalone Options
    $LCOPTS_SA = "-s --toc-depth=2 -N -R --standalone -H #{$LCHEADER_FILE} " +
                 "--template #{$LCTEMPLATE_FILE} "# +
                 #"--bibliography #{$LCBIB_FILE} --csl #{$LCCSL_FILE}"

    # Linked Build Options
    $LCOPTS_CN = "-s --toc-depth=2 -N -R --standalone"

# PDF Creator Options
$PDF = "pdflatex"
$PDFOPTS = "--trace"

# HTML Creator Options
$HTML = "pandoc"
$HTMLOPTS = ""

# SVG Renderer Options
$SVG = "pdf2svg"
$SVGOPTS = ""

# General Settings 


