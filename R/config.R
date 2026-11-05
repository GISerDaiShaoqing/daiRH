# DaiRH \u914D\u7F6E ---------------------------------------------------------------
# \u914D\u7F6E\u6301\u4E45\u5316\u5728 R_user_dir("daiRH", "config")/config.json\uFF0C
# provider \u652F\u6301\u9884\u8BBE\uFF1AOllama / DeepSeek / \u667A\u8C31 GLM / Kimi / OpenAI \u517C\u5BB9\u4EFB\u610F\u7AEF\u70B9\u3002

dairh_config_dir <- function() {
  dir <- tools::R_user_dir("daiRH", "config")
  dir
}

dairh_config_path <- function() {
  # \u6D4B\u8BD5\u53EF\u901A\u8FC7 option \u8986\u76D6\u4FDD\u5B58\u8DEF\u5F84
  p <- getOption("daiRH.config_path") %||%
    file.path(dairh_config_dir(), "config.json")
  # \u5305\u66FE\u53EB daillm\uFF1A\u9996\u6B21\u8BFB\u53D6\u65F6\u628A\u65E7\u5305\u7684 config.json \u6574\u76D8
  # \u642C\u5230\u65B0\u5305\u76EE\u5F55\uFF08idempotent\uFF0C\u65B0\u8DEF\u5F84\u5DF2\u6709\u6587\u4EF6\u5C31\u76F4\u63A5\u8DF3\u8FC7\uFF09
  if (is.null(getOption("daiRH.config_path"))) {
    .dairh_migrate_old_config(p)
  }
  p
}

.dairh_migrate_old_config <- function(new_path) {
  if (file.exists(new_path)) return(invisible(FALSE))
  old_path <- file.path(tools::R_user_dir("daillm", "config"), "config.json")
  if (!file.exists(old_path)) return(invisible(FALSE))
  dir.create(dirname(new_path), recursive = TRUE, showWarnings = FALSE)
  ok <- tryCatch(
    {
      file.copy(old_path, new_path, overwrite = TRUE)
      TRUE
    },
    error = function(e) FALSE
  )
  if (isTRUE(ok)) {
    message("\u5DF2\u628A\u65E7 daillm \u914D\u7F6E\u8FC1\u79FB\u5230 daiRH\uFF1A", new_path)
  }
  invisible(isTRUE(ok))
}

# \u5E38\u7528\u670D\u52A1\u5546\u9884\u8BBE\uFF1A\u4E00\u952E\u56DE\u586B base_url \u4E0E\u6A21\u578B\u540D
DAI_LLM_PRESETS <- list(
  `ollama.local` = list(
    provider = "ollama",
    base_url = "http://localhost:11434",
    model = "gemma4:12b"
  ),
  `deepseek.chat` = list(
    provider = "openai_compatible",
    base_url = "https://api.deepseek.com",
    model = "deepseek-chat"
  ),
  `deepseek.reasoner` = list(
    provider = "openai_compatible",
    base_url = "https://api.deepseek.com",
    model = "deepseek-reasoner"
  ),
  `opencode.go` = list(
    provider = "openai_compatible",
    # OpenCode Go \u8BA1\u5212\u7F51\u5173\uFF08OpenAI \u517C\u5BB9\uFF09\uFF1Bkey \u5728\u8BBE\u7F6E\u91CC\u81EA\u586B\uFF08\u6216\u586B\u73AF\u5883\u53D8\u91CF\u540D\uFF09\u3002
    # \u8BE5\u7F51\u5173\u672A\u5B9E\u73B0 GET /models\uFF0C\u201C\u5217\u51FA\u6A21\u578B\u201D\u6309\u94AE\u5728\u6B64\u9884\u8BBE\u4E0B\u9700\u624B\u52A8\u586B\u6A21\u578B\u540D\u3002
    base_url = "https://opencode.ai/inference/go/openai/v1",
    model = "glm-5.3-flash"
  ),
  `zhipu.glm` = list(
    provider = "openai_compatible",
    base_url = "https://open.bigmodel.cn/api/paas/v4",
    model = "glm-4.6"
  ),
  `kimi.moonshot` = list(
    provider = "openai_compatible",
    base_url = "https://api.moonshot.cn/v1",
    model = "kimi-k2"
  ),
  `OpenAI API` = list(
    provider = "openai_compatible",
    base_url = "https://api.openai.com/v1",
    model = "gpt-4.1-mini"
  )
)

dairh_config_default <- function() {
  list(
    provider = "ollama",
    base_url = "http://localhost:11434",
    model = "gemma4:12b",
    api_key = "",
    api_key_env = "DAI_API_KEY",
    temperature = 0.7,
    max_steps = 12,
    run_mode = "bg",
    allow_edit = TRUE,
    allow_run = TRUE,
    restrict_paths = TRUE,
    system_prompt_extra = "",
    bg_image = "",
    trace = TRUE,
    tools_profile = "",
    history = TRUE,
    history_title = TRUE
  )
}

.dai_cfg_coerce <- function(key, value, template) {
  tpl <- template[[key]]
  if (is.null(tpl)) return(value) # \u672A\u77E5\u5B57\u6BB5\u539F\u6837\u4FDD\u7559
  out <- if (is.logical(tpl)) {
    isTRUE(value) || isTRUE(as.logical(value))
  } else if (is.numeric(tpl)) {
    suppressWarnings(as.numeric(value))
  } else {
    as.character(value)
  }
  # provider / run_mode \u6536\u655B\u5230\u89C4\u8303\u503C\uFF08\u5386\u53F2\u914D\u7F6E\u53EF\u80FD\u5B58\u8FC7\u663E\u793A\u6587\u6848\uFF0C\u5982 "Ollama"\u3001"\u540E\u53F0\u8FD0\u884C\uFF08\u2026\uFF09"\uFF09
  if (identical(key, "provider")) out <- .dairh_norm_provider(out)
  if (identical(key, "run_mode")) out <- .dairh_norm_run_mode(out)
  out
}

# provider \u5F52\u4E00\u5316\uFF1A\u5C0F\u5199 + \u628A\u5E38\u89C1\u663E\u793A\u6587\u6848\u6620\u5C04\u56DE\u89C4\u8303\u503C\uFF08\u8BFB/\u5199/\u5BA2\u6237\u7AEF\u5171\u7528\uFF09
.dairh_norm_provider <- function(p) {
  if (is.null(p) || !length(p) || is.na(p)) return("ollama")
  p <- tolower(trimws(as.character(p)[[1]]))
  if (identical(p, "ollama") || identical(p, "openai_compatible")) return(p)
  if (grepl("ollama", p, fixed = TRUE)) return("ollama")
  if (grepl("openai", p, fixed = TRUE)) return("openai_compatible")
  stop("\u672A\u77E5\u7684 provider: ", p, "\uFF08\u5E94\u4E3A ollama \u6216 openai_compatible\uFF09", call. = FALSE)
}

.dairh_norm_run_mode <- function(m) {
  # \u53EA\u8BA4\u89C4\u8303\u503C\uFF1B\u5386\u53F2\u5783\u573E\u663E\u793A\u6587\u6848\u4E00\u5F8B\u56DE\u843D\u5230\u63A8\u8350\u503C bg\uFF08
  # \u5199\u5165\u7AEF\u5DF2\u7531\u8BBE\u7F6E\u754C\u9762\u6309\u89C4\u8303\u503C\u63D0\u4EA4\u3002\u907F\u514D\u4E2D\u6587\u5B57\u9762 grepl \u7684 locale \u98CE\u9669\uFF09
  m <- tolower(trimws(as.character(m %||% "bg")[[1]]))
  if (identical(m, "gadget") || identical(m, "bg")) return(m)
  "bg"
}

#' \u8BFB\u53D6 DaiRH \u914D\u7F6E
#'
#' \u8BFB\u53D6\u6301\u4E45\u5316\u914D\u7F6E\u5E76\u5408\u5E76\u9ED8\u8BA4\u503C\uFF1B\u914D\u7F6E\u6587\u4EF6\u7F3A\u5931\u6216\u635F\u574F\u65F6\u81EA\u52A8\u56DE\u9000\u9ED8\u8BA4\u503C\u3002
#'
#' @return \u547D\u540D\u5217\u8868\uFF0C\u5305\u542B provider/base_url/model/api_key \u7B49\u5B57\u6BB5\u3002
#' @export
dairh_config_get <- function() {
  cfg <- dairh_config_default()
  path <- dairh_config_path()
  if (file.exists(path)) {
    stored <- tryCatch(
      jsonlite::fromJSON(path, simplifyVector = FALSE),
      error = function(e) NULL
    )
    if (!is.null(stored)) {
      if (is.data.frame(stored)) {
        # fromJSON \u53EF\u80FD\u628A\u6241\u5E73\u5BF9\u8C61\u89E3\u6790\u6210 1 \u884C data.frame
        stored <- as.list(stored[1, ])
        stored <- lapply(stored, function(v) if (length(v) == 1L) v[[1]] else v)
      }
      for (nm in names(stored)) {
        val <- stored[[nm]]
        if (is.null(val)) next
        cfg[[nm]] <- .dai_cfg_coerce(nm, val, cfg)
      }
    }
  }
  cfg
}

#' \u5199\u5165 DaiRH \u914D\u7F6E
#'
#' \u5C06\u7ED9\u5B9A\u5B57\u6BB5\u5408\u5E76\u8FDB\u73B0\u6709\u914D\u7F6E\u5E76\u6301\u4E45\u5316\u5230 config.json\u3002
#'
#' @param ... \u5B57\u6BB5/\u503C\uFF0C\u6216\u4E00\u4E2A\u547D\u540D\u5217\u8868\uFF08\u7B2C\u4E00\u4E2A\u53C2\u6570\uFF09\u3002
#' @return \u9690\u5F0F\u8FD4\u56DE\u5199\u597D\u7684\u914D\u7F6E\u5217\u8868\u3002
#' @export
dairh_config_set <- function(...) {
  patch <- list(...)
  if (length(patch) == 1L && is.list(patch[[1]]) && is.null(names(patch))) {
    patch <- patch[[1]]
  }
  patch <- patch[!vapply(patch, is.null, logical(1))]
  coerced <- Map(.dai_cfg_coerce, names(patch), patch,
    MoreArgs = list(template = dairh_config_default())
  )
  names(coerced) <- names(patch)
  new_cfg <- utils::modifyList(
    dairh_config_get(),
    coerced,
    keep.null = FALSE
  )
  dir.create(dairh_config_dir(), showWarnings = FALSE, recursive = TRUE)
  json <- jsonlite::toJSON(
    new_cfg, auto_unbox = TRUE, pretty = TRUE, null = "null"
  )
  writeLines(json, dairh_config_path(), useBytes = TRUE)
  invisible(new_cfg)
}

# API Key \u89E3\u6790 --------------------------------------------------------------
# \u987A\u5E8F\uFF1Aapi_key \u76F4\u63A5\u503C -> \u73AF\u5883\u53D8\u91CF\u540D\uFF08api_key_env\uFF09
# api_key \u652F\u6301\u4E09\u79CD\u5199\u6CD5\uFF1A\u5B57\u9762\u91CF / "env:VARNAME" / \u5927\u5199\u4E0B\u5212\u7EBF\u7684\u73AF\u5883\u53D8\u91CF\u540D
dairh_api_key_value <- function(cfg) {
  key <- cfg$api_key %||% ""
  key_env <- cfg$api_key_env %||% ""
  if (nzchar(key)) {
    m <- "^env:([A-Za-z_][A-Za-z0-9_]*)$"
    if (grepl(m, key)) return(Sys.getenv(sub(m, "\\1", key), ""))
    if (grepl("^[A-Z][A-Z0-9_]*$", key)) {
      from_env <- Sys.getenv(key, "")
      if (nzchar(from_env)) return(from_env)
    }
    return(key)
  }
  if (nzchar(key_env)) return(Sys.getenv(key_env, ""))
  ""
}
