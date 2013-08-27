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
    $PPOPTS_PRE = '-U "@" "\n" "(" "," ")\n" "(" ")" "#" "" ' +
                  "--include #{$PPMACRO_PRE}"

    # Options for final .tex to .pptex pass
    $PPMACRO_POST =  "#{$ROOT_DIR}style/pptex.gpp"
    $PPOPTS_POST = '-U "$" "\n" "(" "," ")\n" "(" ")" "#" "" ' +
                  "--include #{$PPMACRO_POST}"

# Latex Creator Options
$LC = "pandoc"

    # Standalone Options
    $LCOPTS_SA = "-s --toc-depth=2 -N -R --standalone"

    # Connected Build Options
    $LCOPTS_CN = "-s --toc-depth=2 -N -R --standalone"

# PDF Creator Options
$PDF = "pdflatex"
$PDFOPTS = ""

# HTML Creator Options
$HTML = "pandoc"
$HTMLOPTS = ""

# SVG Renderer Options
$SVG = "pdf2svg'"
$SVGOPTS = ""

# General Settings 


