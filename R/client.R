# DaiRH LLM \u5BA2\u6237\u7AEF ----------------------------------------------------------

.dai_strip_url <- function(u) sub("/*$", "", u)

# \u5343\u4E07\u4E0D\u8981\u7528 ellmer \u7684 api_key=\uFF1A0.4.1 \u7684\u5E9F\u5F03\u517C\u5BB9\u5C42\u6709 bug\uFF0C
# \u4F1A\u628A key \u5305\u6210 "Bearer Bearer <key>"\uFF08\u672C\u5730\u5047\u670D\u52A1\u5668\u62B3\u5934\u5B9E\u6D4B\uFF09\uFF0C
# \u5BF9\u4E25\u683C\u6821\u9A8C Authorization \u7684\u7F51\u5173\uFF08OpenCode Go\uFF09\u5FC5\u73B0 401 Invalid credential\u3002
# \u6B63\u786E\u5F62\u6001\uFF1Acredentials = function() <\u88F8 key>\uFF0Cellmer \u81EA\u5DF1\u8865 Bearer\u3002
.dai_make_openai_compatible <- function(base_url, name, system_prompt, key,
                                        model, params, headers = NULL) {
  if (is.null(headers)) headers <- character(0) # ellmer \u4E0D\u63A5\u53D7 NULL
  ellmer::chat_openai_compatible(
    base_url = base_url,
    name = name,
    system_prompt = system_prompt,
    credentials = if (nzchar(key)) function() key else NULL,
    model = model,
    params = params,
    api_headers = headers,
    echo = "none"
  )
}

# \u7F51\u5173\u7279\u6B8A\u4F1A\u8BDD\u5934\uFF1AOpenCode Go \u8981\u6C42\u8BF7\u6C42\u643A\u5E26 x-opencode-session
# \uFF08\u5B98\u65B9\u6587\u6863\uFF1A\u6BCF\u4E2A\u4F1A\u8BDD\u4E00\u4E2A\u7A33\u5B9A ID\uFF0C\u7528\u4E8E\u8DEF\u7531\u4E0E\u63D0\u793A\u7F13\u5B58\u4F18\u5316\uFF09\u3002
# \u672C\u6B21\u5B9E\u73B0\u91CC\u6BCF\u4E2A dairh_client() \u5B9E\u4F8B\u751F\u6210\u4E00\u4E2A\uFF08= \u9762\u677F\u4E00\u6B21\u4F1A\u8BDD\uFF09\u3002
.dai_session_headers <- function(base_url) {
  if (!grepl("opencode\\.ai", base_url)) return(NULL)
  sid <- paste0(
    "daiRH-",
    paste0(sprintf("%08x", as.integer(runif(6, 1, 2147483647))), collapse = "")
  )
  # ellmer \u7684 api_headers \u9700\u8981\u547D\u540D character \u5411\u91CF\uFF08\u975E list\uFF09
  stats::setNames(c(sid), "x-opencode-session")
}

#' \u6309\u914D\u7F6E\u6784\u5EFA ellmer Chat \u5BF9\u8C61
#'
#' provider = "ollama" \u65F6\u4F7F\u7528 [ellmer::chat_ollama]\uFF0C
#' provider = "openai_compatible" \u65F6\u4F7F\u7528 [ellmer::chat_openai_compatible]
#' \uFF08DeepSeek / GLM / Kimi / \u4EFB\u610F OpenAI \u517C\u5BB9\u7F51\u5173\u5747\u53EF\uFF09\u3002
#' \u8FD9\u91CC\u53EA\u6784\u9020\u5BA2\u6237\u7AEF\uFF0C\u4E0D\u53D1\u7F51\u7EDC\u8BF7\u6C42\u3002
#'
#' @param cfg [dairh_config_get()] \u7684\u914D\u7F6E\u5217\u8868
#' @param system_prompt \u8986\u76D6\u7CFB\u7EDF\u63D0\u793A\u8BCD\uFF1BNULL \u5219\u4E0D\u9644\u7CFB\u7EDF\u63D0\u793A
#' @return ellmer Chat (R6) \u5BF9\u8C61
#' @export
dairh_client <- function(cfg = dairh_config_get(), system_prompt = NULL) {
  base_url <- .dai_strip_url(cfg$base_url %||% "")
  params <- ellmer::params(temperature = round(as.numeric(cfg$temperature %||% 0.7), 3))
  provider <- .dairh_norm_provider(cfg$provider)
  if (identical(provider, "ollama")) {
    # chat_ollama \u6784\u9020\u65F6\u4F1A ping \u7AEF\u70B9\uFF1B\u670D\u52A1\u5668\u4E0D\u5728\u7EBF\u65F6\u4E0D\u80FD\u8BA9\u9762\u677F\u76F4\u63A5\u5D29\u6389\uFF1A
    # \u9000\u56DE Ollama \u7684 /v1 OpenAI \u517C\u5BB9\u63A5\u53E3\uFF08\u6784\u9020\u4E0D\u8054\u7F51\uFF0C\u9519\u8BEF\u5EF6\u8FDF\u5230\u8BF7\u6C42\u65F6\u5C55\u793A\uFF09\u3002
    tryCatch(
      ellmer::chat_ollama(
        system_prompt = system_prompt,
        base_url = base_url,
        model = cfg$model,
        params = params,
        echo = "none"
      ),
      error = function(e) {
        .dai_make_openai_compatible(
          base_url = paste0(base_url, "/v1"),
          name = "DaiRH (ollama /v1)",
          system_prompt = system_prompt,
          key = "not-needed",
          model = cfg$model,
          params = params,
          headers = .dai_session_headers(paste0(base_url, "/v1"))
        )
      }
    )
  } else if (identical(provider, "openai_compatible")) {
    .dai_make_openai_compatible(
      base_url = base_url,
      name = "DaiRH",
      system_prompt = system_prompt,
      key = dairh_api_key_value(cfg),
      model = cfg$model,
      params = params,
      headers = .dai_session_headers(base_url)
    )
  } else {
    stop("\u672A\u77E5\u7684 provider: ", cfg$provider, "\uFF08\u5E94\u4E3A ollama \u6216 openai_compatible\uFF09",
      call. = FALSE
    )
  }
}

#' \u5217\u51FA\u5F53\u524D\u7AEF\u70B9\u53EF\u7528\u7684\u6A21\u578B
#'
#' Ollama \u8D70 `/api/tags`\uFF0COpenAI \u517C\u5BB9\u7AEF\u70B9\u8D70 `GET /models`\u3002
#' \u8BF7\u6C42\u5931\u8D25\u65F6\u8FD4\u56DE character(0)\uFF08\u4E0D\u62A5\u9519\uFF0CUI \u53EF\u663E\u793A\u7A7A\u5217\u8868\uFF09\u3002
#'
#' @param cfg \u914D\u7F6E\u5BF9\u8C61\uFF08dairh_config_get() \u7684\u7ED3\u679C\u6216\u540C\u6784\u5B57\u6BB5\u7684 list\uFF09\u3002
#' @param timeout_s \u8BF7\u6C42\u8D85\u65F6\u79D2\u6570\uFF0C\u9ED8\u8BA4 10\u3002
#'
#' @return \u6A21\u578B\u540D\u7684 character \u5411\u91CF\uFF1B\u8BF7\u6C42\u5931\u8D25\u65F6\u4E3A character(0)\u3002
#'
#' @export
dairh_list_models <- function(cfg = dairh_config_get(), timeout_s = 10) {
  base_url <- .dai_strip_url(cfg$base_url %||% "")
  provider <- .dairh_norm_provider(cfg$provider)
  models <- tryCatch(
    {
      if (identical(provider, "ollama")) {
        resp <- httr2::request(base_url) |>
          httr2::req_url_path("api/tags") |>
          httr2::req_timeout(timeout_s) |>
          httr2::req_perform()
        body <- httr2::resp_body_json(resp)
        m <- body$models
        out <- vapply(m, function(x) x$name %||% x$model %||% NA_character_,
          character(1)
        )
        out[!is.na(out)]
      } else {
        key <- dairh_api_key_value(cfg)
        req <- httr2::request(base_url) |>
          httr2::req_url_path("models") |>
          httr2::req_timeout(timeout_s)
        if (nzchar(key)) {
          req <- req |> httr2::req_headers(Authorization = paste("Bearer", key))
        }
        resp <- httr2::req_perform(req)
        body <- httr2::resp_body_json(resp)
        out <- vapply(body$data, function(x) x$id %||% NA_character_,
          character(1)
        )
        out[!is.na(out)]
      }
    },
    error = function(e) {
      warning("\u83B7\u53D6\u6A21\u578B\u5217\u8868\u5931\u8D25\uFF1A", conditionMessage(e), call. = FALSE)
      character(0)
    }
  )
  unique(sort(models))
}
