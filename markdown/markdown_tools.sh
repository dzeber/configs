#
# Tools for rendering Markdown.
#

# Render a '.md' file to a standalone HTML file using Pandoc.
# 
# By default, the generated file has the same name and path as the first
# listed Markdown file, although this can be overriden using Pandoc's `-o` arg.
#
# If the `--github` flag is specified, the input file will be treated as
# Github-flavoured markdown. Otherwise, it is considered Pandoc markdown.

# 
# Usage: md_2_html_pandoc [--github] [args passed to Pandoc...] <file> [<file2> ...]
md_2_html_pandoc () {
    local PANDOC_ARGS="" 
    local FIRST_MD_FILE=""
    local HAS_OFILE="no"
    while [[ -n "$1" ]]; do
        # Check for Github-flavoured markdown flag.
        if [[ "$1" == "--github" ]]; then
            PANDOC_ARGS="$PANDOC_ARGS --from=markdown_github"
            shift
            continue
        fi
        # Flag if output file is specified.
        [[ "$1" == "-o" ]] || echo "$1" | grep -q '^--output=' &&
            HAS_OFILE="no"
        # Detect the first supplied Markdown input file.
        [[ (! "$FIRST_MD_FILE") ]] && echo "$1" | grep -q '\.md$' &&
            FIRST_MD_FILE="$1"

        PANDOC_ARGS="$PANDOC_ARGS $1"
        shift
    done
    
    if [[ (! "$FIRST_MD_FILE") ]]; then
        echo "At least one .md file must be specified." 1>&2
        exit 1
    fi

    # Set the output file path, if necessary.
    if [[ "$HAS_OFILE" == "no" ]]; then
        PANDOC_ARGS="$PANDOC_ARGS --output=$(echo "$FIRST_MD_FILE" |
            sed 's/\.md$/.html/')"
    fi

    # Set the default date string.
    local DEFAULT_DATE="Updated $(date '+%B %-d, %Y')"

    # TODO: 
    # - if --github, run this logic by default
    # - offer -notitle and -nodate switches to turn off default metadata.
    # - offer -detect-title switch to turn on default title
    # - look up CSS files from default dir if path not given
    # - title detection:
    #       * if there are more than one level 1 headers, default to filename
    #       * if there is one level 1 header, use it as the title.
    #         In this case, strip it from the doc before rendering.
    #       * if there are no level 1 headers, default to filename
    #
    # Detect the string to use as the title.
    # The title defaults to the first level one header in the first md doc.
    # A level-one header is a line starting with a single '#' or a line followed
    # by a line containing only '='.
#    local DEFAULT_TITLE=$(
#        grep -E -m 1 '^#(\s+\S|[^#[:space:]])' $FIRST_MD_FILE |
#        sed 's/^#\s*//')
#    [[ "$DEFAULT_TITLE" ]] || \
#        DEFAULT_TITLE=$(grep -E -m 1 -B 1 '^=+\s*$' $FIRST_MD_FILE | head -n 1)
#    # If no level one header was found, default to the file name.
#    [[ "$DEFAULT_TITLE" ]] || DEFAULT_TITLE="$FIRST_MD_FILE"
    local DEFAULT_TITLE="$FIRST_MD_FILE"

    # Create a dummy YAML file containing these default strings.
    # This will be passed as the final argument to Pandoc.
    # The title and date strings will be drawn from this file unless otherwise
    # specified in another YAML header or file, or a commandline arg.
    echo "---
        title: $DEFAULT_TITLE
        date: $DEFAULT_DATE
        ---" |
        sed -E 's/^\s+//' > _default_meta.yaml

    # Render the file.
    RENDER_CMD="pandoc --parse-raw --smart --standalone --table-of-contents"
    RENDER_CMD="$RENDER_CMD --section-divs --mathjax $PANDOC_ARGS"
    RENDER_CMD="$RENDER_CMD _default_meta.yaml"

    echo -e "Rendering command:\n"
    echo "$RENDER_CMD"
    eval $RENDER_CMD

    rm _default_meta.yaml
}


