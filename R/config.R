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

# \u5E38\u7528\u670D\u52A1\u5546\u9884\u8BBE\uFF1A\u4E00\u952E\u56DE\u586B base_url \u4E0E\u6A21\u578B\u540D\u3002
# models\uFF08\u53EF\u9009\uFF09\uFF1A\u9884\u8BBE\u5185\u7F6E\u7684\u6A21\u578B\u6E05\u5355\u2014\u2014\u7AEF\u70B9\u672A\u5B9E\u73B0 GET /models \u65F6\uFF0C"\u5217\u51FA\u6A21\u578B"
# \u6309\u94AE\u56DE\u9000\u5230\u8FD9\u4EFD\u6E05\u5355\uFF080.6 \u8D77\uFF09\u3002Ollama \u52A8\u6001\u53D1\u73B0\u53EF\u9760\uFF0C\u4E0D\u9700\u8981\u5185\u7F6E\u3002
DAI_LLM_PRESETS <- list(
  `ollama.local` = list(
    provider = "ollama",
    base_url = "http://localhost:11434",
    model = "gemma4:12b"
  ),
  `deepseek.chat` = list(
    provider = "openai_compatible",
    base_url = "https://api.deepseek.com",
    model = "deepseek-chat",
    models = c("deepseek-chat", "deepseek-reasoner")
  ),
  `deepseek.reasoner` = list(
    provider = "openai_compatible",
    base_url = "https://api.deepseek.com",
    model = "deepseek-reasoner",
    models = c("deepseek-reasoner", "deepseek-chat")
  ),
  `opencode.go.chat` = list(
    provider = "openai_compatible",
    # OpenCode Go \u8BA1\u5212\u7F51\u5173\uFF08OpenAI \u517C\u5BB9\uFF09\uFF1Bkey \u5728\u8BBE\u7F6E\u91CC\u81EA\u586B\uFF08\u6216\u586B\u73AF\u5883\u53D8\u91CF\u540D\uFF09\u3002
    # \u8BE5\u7F51\u5173\u672A\u5B9E\u73B0 GET /models\uFF1A\u201C\u5217\u51FA\u6A21\u578B\u201D\u6309\u94AE\u5728\u6B64\u9884\u8BBE\u4E0B\u81EA\u52A8\u56DE\u9000\u5230\u4E0B\u65B9\u5185\u7F6E\u6E05\u5355\u3002
    base_url = "https://opencode.ai/inference/go/openai/v1",
    model = "glm-5.3-flash",
    models = c(
      "glm-5.3-flash", "glm-5.3", "glm-5.2", "glm-5.1",
      "kimi-k3.1-pro", "kimi-k3", "kimi-k2.7-code", "kimi-k2.6",
      "deepseek-v4.1-flash", "deepseek-v4-pro", "deepseek-v4-flash",
      "deepseek-v4-flash-vision-exp",
      "mimo-v2.6-pro", "mimo-v2.6-flash", "mimo-v2.5", "mimo-v2.5-pro",
      "minimax-m3.1-flash", "hy4-preview", "hy3"
    )
  ),
  `opencode.go.responses` = list(
    provider = "openai",
    # \u540C\u7F51\u5173\u7684 OpenAI Responses \u534F\u8BAE\u5165\u53E3\uFF08{base_url}/responses\uFF09\uFF1B
    # \u5185\u7F6E\u6E05\u5355\u7167 ZCode \u6A21\u677F\uFF08zcode-builtin.json\uFF09\u7684 builtinModelIds\u3002
    base_url = "https://opencode.ai/inference/go/openai/v1",
    model = "gpt-6-luna",
    models = c("gpt-6-luna", "gpt-5.6-luna", "grok-4.7", "grok-4.6")
  ),
  `opencode.go.messages` = list(
    provider = "anthropic",
    # \u540C\u7F51\u5173\u7684 Anthropic Messages \u534F\u8BAE\u5165\u53E3\uFF08{base_url}/messages\uFF09\uFF1B
    # \u5185\u7F6E\u6E05\u5355\u7167 ZCode \u6A21\u677F\uFF08zcode-builtin.json\uFF09\u7684 builtinModelIds\u3002
    base_url = "https://opencode.ai/inference/anthropic/v1",
    model = "minimax-m3",
    models = c(
      "minimax-m3", "minimax-m2.7", "minimax-m2.5",
      "qwen3.8-max", "qwen3.8-flash", "qwen3.7-max", "qwen3.7-plus",
      "qwen3.6-plus", "claude-haiku-5-5"
    )
  ),
  `zhipu.glm` = list(
    provider = "openai_compatible",
    base_url = "https://open.bigmodel.cn/api/paas/v4",
    model = "glm-4.6"
  ),
  `qwen.chat` = list(
    provider = "openai_compatible",
    base_url = "https://maas.qianwenaiapi.com/compatible-mode/v1",
    model = "qwen3.8-flash",
    models = c(
      "qwen3.8-flash", "qwen3.8-max",
      "qwen3.7-max", "qwen3.7-plus", "qwen3.7-flash",
      "qwen3.6-plus", "qwen3.6-flash", "qwen3.5-plus", "qwen3.5-flash",
      "qwen3-max", "qwen-plus", "qwen-flash", "qwen3-vl-plus"
    )
  ),
  `qwen.messages` = list(
    provider = "anthropic",
    base_url = "https://maas.qianwenaiapi.com/apps/anthropic/v1",
    model = "qwen3.8-flash",
    models = c(
      "qwen3.8-flash", "qwen3.8-max",
      "qwen3.7-max", "qwen3.7-plus", "qwen3.7-flash",
      "qwen3.6-plus", "qwen3.6-flash", "qwen3.5-plus", "qwen3.5-flash",
      "qwen3-max", "qwen-plus", "qwen-flash", "qwen3-vl-plus"
    )
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
    # \u6A21\u578B\u4E0A\u4E0B\u6587\u7A97\u53E3\uFF08tokens\uFF09\uFF1A\u6807\u9898\u680F"\u4E0A\u4E0B\u6587\u5BB9\u91CF"\u7684\u5206\u6BCD\u3002\u7F51\u5173\u4E00\u822C\u4E0D\u4F1A\u544A\u77E5\uFF0C
    # \u7559 NA = \u672A\u77E5\uFF08\u6807\u9898\u680F\u53EA\u663E\u793A\u5360\u7528\uFF0C\u4E0D\u663E\u793A\u767E\u5206\u6BD4\uFF09\u3002
    context_window = NA_real_,
    # 0.9 \u538B\u7F29\u63D0\u793A\u9608\u503C\uFF1A\u5360\u7528/\u7A97\u53E3 \u8FBE\u5230\u5B83\u65F6\u63A8\u4E00\u6B21\u901A\u77E5\u5E76\u9AD8\u4EAE\u8BFB\u6570\uFF1B0 = \u5173\u3002
    compact_hint = 0.7,
    api_key = "",
    api_key_env = "DAI_API_KEY",
    temperature = 0.7,
    # \u601D\u8003\u5F3A\u5EA6\uFF08\u63A8\u7406\u529B\u5EA6\uFF09\uFF1A\u900F\u4F20\u7ED9\u7F51\u5173\u30020.9 \u5730\u677F\u5347 ellmer 0.5.1 \u8D77\u5355\u901A\u9053\u2014\u2014\u7EDF\u4E00\u8D70
    # params()\uFF08\u4E0A\u6E38 0.5.1 \u5DF2\u4FEE compatible provider \u7684\u767D\u540D\u5355\uFF0C\u5047\u7F51\u5173\u5B9E\u6D4B\u8FDB\u9876\u5C42\uFF09\u3002
    # "" = \u4E0D\u53D1\u9001\u8BE5\u5B57\u6BB5\u3002\u53EF\u53D6 minimal/low/medium/high\u3002
    reasoning_effort = "",
    max_steps = 12,
    run_mode = "bg",
    # \u4F1A\u8BDD\u6A21\u5F0F\uFF1Aplan\uFF08\u8BA1\u5212\uFF09= \u53EA\u8BFB\u8C03\u7814\u5DE5\u5177\u9762\uFF1Bbuild\uFF08\u6784\u5EFA\uFF09= \u5168\u5DE5\u5177\u3002\u9762\u677F\u5934\u90E8\u6309\u94AE\u70ED\u5207\u6362\uFF0C
    # \u8FD9\u91CC\u662F\u65B0\u4F1A\u8BDD\u7684\u9ED8\u8BA4\u503C\u3002
    mode = "build",
    allow_edit = TRUE,
    allow_run = TRUE,
    restrict_paths = TRUE,
    system_prompt_extra = "",
    # 0.8 \u9879\u76EE\u6982\u89C8\uFF1A\u65B0\u4F1A\u8BDD\u7CFB\u7EDF\u63D0\u793A\u81EA\u52A8\u5E26 git \u5FEB\u7167 / \u76EE\u5F55\u6811 / \u5DE5\u4F5C\u533A\u6458\u8981\uFF08\u53EA\u8BFB\u4FE1\u606F\uFF09\u3002
    project_brief = TRUE,
    bg_image = "",
    # 0.8 \u9762\u677F\u5DE6\u4FA7\u5409\u7965\u7269\u56FE\uFF1A\u672C\u5730\u8DEF\u5F84\u6216 http(s) URL\uFF1B\u7559\u7A7A = \u5185\u7F6E\u5C0F\u673A\u5668\u4EBA SVG\u3002
    # \uFF08\u4F7F\u7528\u7B2C\u4E09\u65B9\u63D2\u753B\u65F6\u8BF7\u4FDD\u7559\u4F5C\u8005\u7F72\u540D\uFF0C\u5E76\u81EA\u884C\u786E\u8BA4\u6388\u6743\u3002\uFF09
    mascot = "",
    trace = TRUE,
    trace_dir = "",
    tools_profile = "",
    history = TRUE,
    history_dir = "",
    history_title = TRUE,
    allow_subagent = TRUE,
    subagent_max_steps = 8,
    # \u5B50\u4EE3\u7406\u7528\u6A21\u578B\uFF1A\u7559\u7A7A = \u6CBF\u7528\u4E3B\u6A21\u578B\uFF1B\u586B\u8F7B\u91CF\u6A21\u578B\u53EF\u7701\u989D\u5EA6\uFF08usage \u65E5\u5FD7 model \u5B57\u6BB5\u81EA\u52A8\u8DDF\u968F\uFF09\u3002
    delegate_model = "",
    # 0.9 \u8F7B\u91CF\u6A21\u578B\u8D77\u6807\u9898\uFF1A\u7559\u7A7A = \u4E3B\u6A21\u578B\uFF08\u9ED8\u8BA4\uFF09\uFF1B\u586B\u4FBF\u5B9C\u6A21\u578B\u540D\u53EF\u7701\u8D77\u6807\u9898\u7684\u8D26\u3002
    title_model = "",
    # 0.9 \u601D\u8003\u8FC7\u7A0B\u5C55\u793A\u5F00\u5173\uFF1A\u5173 = \u9762\u677F\u4E0D\u6E32\u67D3\u6298\u53E0\u601D\u8003\u5757\uFF08shinychat \u7684
    # show_thinking_after_s \u8D1F\u503C\u901A\u9053\uFF09\uFF1B\u91CD\u5F00\u9762\u677F\u751F\u6548\u3002
    show_thinking = TRUE
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
  if (identical(key, "mode")) out <- .dairh_norm_mode(out)
  if (identical(key, "reasoning_effort")) out <- .dairh_norm_effort(out)
  out
}

# provider \u5F52\u4E00\u5316\uFF1A\u5C0F\u5199 + \u628A\u5E38\u89C1\u663E\u793A\u6587\u6848\u6620\u5C04\u56DE\u89C4\u8303\u503C\uFF08\u8BFB/\u5199/\u5BA2\u6237\u7AEF\u5171\u7528\uFF09
.dairh_norm_provider <- function(p) {
  if (is.null(p) || !length(p) || is.na(p)) return("ollama")
  p <- tolower(trimws(as.character(p)[[1]]))
  if (p %in% c("ollama", "openai_compatible", "openai", "anthropic")) return(p)
  # \u7F51\u5173\u6A21\u677F id \u4E5F\u80FD\u76F4\u63A5\u586B\uFF1Aopencode-go-chat/messages/responses \u81EA\u52A8\u5F52\u4E00
  if (grepl("messages", p, fixed = TRUE) || grepl("anthropic", p, fixed = TRUE)) {
    return("anthropic")
  }
  if (grepl("responses", p, fixed = TRUE)) return("openai")
  if (grepl("ollama", p, fixed = TRUE)) return("ollama")
  if (grepl("chat", p, fixed = TRUE) || grepl("openai", p, fixed = TRUE)) {
    return("openai_compatible")
  }
  stop("\u672A\u77E5\u7684 provider: ", p, "\uFF08\u5E94\u4E3A ollama / openai_compatible / openai / anthropic\uFF09", call. = FALSE)
}

.dairh_norm_run_mode <- function(m) {
  # \u53EA\u8BA4\u89C4\u8303\u503C\uFF1B\u5386\u53F2\u5783\u573E\u663E\u793A\u6587\u6848\u4E00\u5F8B\u56DE\u843D\u5230\u63A8\u8350\u503C bg\uFF08
  # \u5199\u5165\u7AEF\u5DF2\u7531\u8BBE\u7F6E\u754C\u9762\u6309\u89C4\u8303\u503C\u63D0\u4EA4\u3002\u907F\u514D\u4E2D\u6587\u5B57\u9762 grepl \u7684 locale \u98CE\u9669\uFF09
  m <- tolower(trimws(as.character(m %||% "bg")[[1]]))
  if (identical(m, "gadget") || identical(m, "bg")) return(m)
  "bg"
}

# \u4F1A\u8BDD\u6A21\u5F0F\u5F52\u4E00\u5316\uFF1A\u53EA\u8BA4 plan/build\uFF1B\u4E71\u503C\u56DE\u843D build\uFF08\u5199\u5165\u7AEF\u7531\u4E0B\u62C9/\u6309\u94AE\u6309\u89C4\u8303\u503C\u63D0\u4EA4\uFF09
.dairh_norm_mode <- function(m) {
  v <- as.character(m %||% "build")
  m <- if (length(v)) tolower(trimws(v[[1]])) else "build"
  if (!length(m) || is.na(m)) m <- "build"
  if (identical(m, "plan") || identical(m, "build")) return(m)
  "build"
}

# \u601D\u8003\u5F3A\u5EA6\u5F52\u4E00\u5316\uFF1A\u53EA\u8BA4 minimal/low/medium/high\uFF1B\u7A7A/\u4E71\u503C = \u4E0D\u53D1\u9001\u8BE5\u5B57\u6BB5
.dairh_norm_effort <- function(e) {
  v <- as.character(e %||% "")
  e <- if (length(v)) tolower(trimws(v[[1]])) else ""
  if (!length(e) || is.na(e)) e <- ""
  if (identical(e, "minimal") || identical(e, "low") ||
      identical(e, "medium") || identical(e, "high")) return(e)
  ""
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
  # NA \u6570\u503C\u843D\u76D8\u4E3A\u54E8\u5175\u4E32\u0020\u0022\u004E\u0041\u0022\uFF1AJSON null \u4F1A\u88AB defaults \u5408\u5E76\u9876\u56DE\u7F3A\u7701\u503C\uFF0C\u201Cleave empty = omit\u201D \u7684\u8BED\u4E49\uFF08temperature \u7B49\uFF09\u6D3B\u4E0D\u8FC7\u4E00\u6B21\u5F80\u56DE\uFF080.9 \u5B9E\u6D4B\uFF09\u3002
  coerced <- lapply(coerced, function(v) {
    if (is.numeric(v) && length(v) == 1L && is.na(v)) "NA" else v
  })
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
