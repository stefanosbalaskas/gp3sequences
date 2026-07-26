namespace_lines <- readLines(
  "NAMESPACE",
  warn = FALSE,
  encoding = "UTF-8"
)

exports <- sub(
  "^export\\(([^)]+)\\)$",
  "\\1",
  grep(
    "^export\\(",
    namespace_lines,
    value = TRUE
  )
)

exports <- sort(
  unique(exports),
  method = "radix"
)

pkgdown_lines <- if (
  file.exists("_pkgdown.yml")
) {
  readLines(
    "_pkgdown.yml",
    warn = FALSE,
    encoding = "UTF-8"
  )
} else {
  character()
}

audit <- data.frame(
  "function" = exports,
  manual = file.exists(
    file.path(
      "man",
      paste0(
        exports,
        ".Rd"
      )
    )
  ),
  in_pkgdown = vapply(
    exports,
    function(fun) {
      any(
        grepl(
          paste0(
            "^[[:space:]]*-[[:space:]]*",
            fun,
            "[[:space:]]*$"
          ),
          pkgdown_lines
        )
      )
    },
    logical(1)
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

print(
  audit,
  row.names = FALSE
)

cat(
  "\nExports:",
  nrow(audit),
  "\n"
)
cat(
  "Missing manuals:",
  sum(!audit$manual),
  "\n"
)
cat(
  "Missing pkgdown reference entries:",
  sum(!audit$in_pkgdown),
  "\n"
)
