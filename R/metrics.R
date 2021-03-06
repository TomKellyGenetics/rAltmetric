#' Query data from the Altmetric.com API
#'
#' @param oid  An object ID (assigned internally by Altmetric)
#' @param id An altmetric.com id for a scholarly product
#' @param doi A persistent identifier for a scholarly product
#' @param pmid An is for any article indexed in Pubmed. PubMed accesses the MEDLINE database of references and abstracts on life sciences and biomedical topics
#' @param arxiv  A valid id from arxiv. The arxiv is a repository of preprints in the fields of mathematics, physics, astronomy, computer science, quantitative biology, statistics, and quantitative finance.
#' @param isbn A International Standard Book Number (ISBN)
#' @param uri A Uniform Resource Identifier such as webpage
#' @param apikey Your API `key`. By default the package ships with a key, but mostly as a demo. If the key becomes overused, then it is likely that you will start to see API limit errors
#' @param foptions Additional options for `httr`
#' @param ... additional options
#' @importFrom httr GET stop_for_status status_code warn_for_status
#' @export
#' @examples
#' \dontrun{
#' altmetrics(doi ='10.1038/480426a')
#' # For ISBNs
#' ib <- altmetrics(isbn = "978-3-319-25557-6")
#' }
altmetrics <-
  function(oid = NULL,
           id = NULL,
           doi = NULL,
           pmid = NULL,
           arxiv = NULL,
           isbn = NULL,
           uri = NULL,
           apikey = getOption('altmetricKey'),
           foptions = list(),
           ...) {
    if (is.null(apikey))
      apikey <- '37c9ae22b7979124ea650f3412255bf9'

    acceptable_identifiers <- c("doi", "arxiv", "id", "pmid", "isbn", "uri")
    # If you start hitting rate limits, email support@altmetric.com
    # to get your own key.


  if (all(sapply(list(oid, doi, pmid, arxiv, isbn, uri), is.null)))
      stop("No valid identfier found. See ?altmetrics for more help", call. =
             FALSE)

    # If any of the identifiers are not prefixed by that text:
    if (!is.null(id)) id <- prefix_fix(id, "id")
    if (!is.null(doi)) doi <- prefix_fix(doi, "doi")
    if (!is.null(isbn)) isbn <- prefix_fix(isbn, "isbn")
    if (!is.null(uri)) uri <- prefix_fix(uri, "uri")
    if (!is.null(arxiv)) arxiv <- prefix_fix(arxiv, "arXiv")
    if (!is.null(pmid)) pmid <- prefix_fix(pmid, "pmid")

    # remove the identifiers that weren't specified
    identifiers <- ee_compact(list(oid, id, doi, pmid, arxiv, isbn, uri))


    # If user specifies more than one at once, then throw an error
    # Users should use lapply(object_list, altmetrics)
    # to process multiple objects.
    if (length(identifiers) > 1)
      stop(
        "Function can only take one object at a time. Use lapply with a list to process multiple objects",
        call. = FALSE
      )

    if (!is.null(identifiers)) {
      ids <- identifiers[[1]]
    }


    supplied_id <-
      as.character(as.list((strsplit(ids, '/'))[[1]])[[1]])

     # message(sprintf("%s", supplied_id))
    if (!(supplied_id %in% acceptable_identifiers))
      stop("Unknown identifier. Please use doi, pmid, isbn, uri, arxiv or id (for altmetric id).",
           call. = F)
    base_url <- "http://api.altmetric.com/v1/"
    args <- list(key = apikey)
    request <-
      httr::GET(paste0(base_url, ids), query = args, foptions, httr::add_headers("user-agent" = "#rstats rAltmertic package https://github.com/ropensci/rAltmetric"))
    if(httr::status_code(request) == 404) {
    stop("No metrics found for object")
    } else {
    httr::warn_for_status(request)
    results <-
      jsonlite::fromJSON(httr::content(request, as = "text"), flatten = TRUE)
    results <- rlist::list.flatten(results)
    class(results) <- "altmetric"
    results

    }
  }


#' Returns a data.frame from an S3 object of class altmetric
#' @param alt_obj An object of class altmetric
#' @export
altmetric_data <- function(alt_obj) {
  if (inherits(alt_obj, "altmetric"))  {
    res <- data.frame(t(unlist(alt_obj)), stringsAsFactors = FALSE)
  }
  res
}

#' @noRd
ee_compact <- function(l)
  Filter(Negate(is.null), l)

#' @noRd
prefix_fix <- function(x = NULL, type = "doi") {
  if(is.null(x))
      stop("Some identifier required")

  # Check for arXiv and arxiv
  type2 <- tolower(type)
  val <- c(grep(type, x), grep(type2, x))

  if(any(val == 1)) {
    # lose the prefix and grab the ID
    id <-  strsplit(x, ":")[[1]][2]
    res <- paste0(tolower(type),"/", id)
  } else {
    res <- paste0(tolower(type),"/", x)
  }
  res
}
