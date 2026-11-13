# DaiRH LLM \u5BA2\u6237\u7AEF ----------------------------------------------------------

.dai_strip_url <- function(u) sub("/*$", "", u)

# \u5343\u4E07\u4E0D\u8981\u7528 ellmer \u7684 api_key=\uFF1A0.4.1 \u7684\u5E9F\u5F03\u517C\u5BB9\u5C42\u6709 bug\uFF0C
# \u4F1A\u628A key \u5305\u6210 "Bearer Bearer <key>"\uFF08\u672C\u5730\u5047\u670D\u52A1\u5668\u62B3\u5934\u5B9E\u6D4B\uFF09\uFF0C
# \u5BF9\u4E25\u683C\u6821\u9A8C Authorization \u7684\u7F51\u5173\uFF08OpenCode Go\uFF09\u5FC5\u73B0 401 Invalid credential\u3002
# \u6B63\u786E\u5F62\u6001\uFF1Acredentials = function() <\u88F8 key>\uFF0Cellmer \u81EA\u5DF1\u8865 Bearer\u3002
.dai_make_openai_compatible <- function(base_url, name, system_prompt, key,
                                        model, params, headers = NULL) {
  if (is.null(headers)) headers <- character(0) # 4E0D63A553D7 NULL
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

# \u7EC4\u88C5 params: temperature = NA = \u4E0D\u53D1\u9001\u8BE5\u5B57\u6BB5\u2014\u2014Responses \u63A8\u7406\u6A21\u578B\u62D2\u6536\uFF0C0.9 \u5B9E\u6D4B\u3002
# \u7F3A\u7701\u5224\u5B9A\u53EA\u8BA4\u0020NULL\uFF1B\u663E\u5F0F NA = \u4E0D\u53D1\u9001\u3002 \u5343\u4E07\u522B\u7528 %||% \u2014\u2014 daiRH \u7684 %||% \u4F1A\u628A NA \u4E5F\u5F53\u7F3A\u7701\u541E\u6389\uFF08\u0030\u002E\u0039\u0020\u5B9E\u6D4B\u81EA\u6253\u8138\uFF09\u3002
.dai_resolve_temperature <- function(cfg) {
  tv <- cfg$temperature
  if (is.null(tv) || length(tv) == 0L) return(0.7)
  suppressWarnings(as.numeric(tv[[1]]))
}

.dai_build_params <- function(temperature, effort) {
  if (is.finite(temperature) && nzchar(effort)) {
    ellmer::params(temperature = round(temperature, 3),
      reasoning_effort = effort)
  } else if (is.finite(temperature)) {
    ellmer::params(temperature = round(temperature, 3))
  } else if (nzchar(effort)) {
    ellmer::params(reasoning_effort = effort)
  } else {
    ellmer::params()
  }
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
  # 0.9 \u5730\u677F\u5347 0.5.1 \u540E\u56DE\u5F52\u5355\u901A\u9053\uFF1Areasoning_effort \u7EDF\u4E00\u8D70 params()\u2014\u2014\u4E0A\u6E38 0.5.1
  # \u5DF2\u628A compatible provider \u7684 params \u767D\u540D\u5355\u4FEE\u597D\uFF08\u5047\u7F51\u5173\u5B9E\u6D4B\u80FD\u8FDB\u8BF7\u6C42\u4F53\u9876\u5C42\uFF09\uFF0C
  # api_args \u65C1\u8DEF\u64A4\u9500\u3002"" = \u4E0D\u53D1\u9001\u3002\u53EF\u53D6 minimal/low/medium/high\u3002
  effort <- .dairh_norm_effort(cfg$reasoning_effort %||% "")
  temperature <- .dai_resolve_temperature(cfg)
  params <- .dai_build_params(temperature, effort)
  provider <- .dairh_norm_provider(cfg$provider)
  model <- cfg$model %||% ""
  # \u65B0\u534F\u8BAE\u5206\u652F (chat_openai / chat_anthropic) \u7684 api_headers \u4E0D\u63A5\u53D7 NULL\u2014\u2014
  # \u4E0E .dai_make_openai_compatible \u7684 \u5B88\u536B\u540C\u6B3E (0.9 \u4E09\u6A21\u5F0F\u8865\u9F50\u65F6\u5B9E\u6D4B)\u3002
  headers <- .dai_session_headers(base_url)
  if (is.null(headers)) headers <- character(0)
  cl <- if (identical(provider, "ollama")) {
    # chat_ollama \u6784\u9020\u65F6\u4F1A ping \u7AEF\u70B9\uFF1B\u670D\u52A1\u5668\u4E0D\u5728\u7EBF\u65F6\u4E0D\u80FD\u8BA9\u9762\u677F\u76F4\u63A5\u5D29\u6389\uFF1A
    # \u9000\u56DE Ollama \u7684 /v1 OpenAI \u517C\u5BB9\u63A5\u53E3\uFF08\u6784\u9020\u4E0D\u8054\u7F51\uFF0C\u9519\u8BEF\u5EF6\u8FDF\u5230\u8BF7\u6C42\u65F6\u5C55\u793A\uFF09\u3002
    tryCatch(
      ellmer::chat_ollama(
        system_prompt = system_prompt,
        base_url = base_url,
        model = model,
        params = params,
        echo = "none"
      ),
      error = function(e) {
        .dai_make_openai_compatible(
          base_url = paste0(base_url, "/v1"),
          name = "DaiRH (ollama /v1)",
          system_prompt = system_prompt,
          key = "not-needed",
          model = model,
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
      model = model,
      params = params,
      headers = .dai_session_headers(base_url)
    )
    # 0.9 \u4E09\u6A21\u5F0F\u8865\u9F50\uFF1AOpenAI Responses \u534F\u8BAE\u76F4\u8FDE\uFF08\u4E0E\u7F51\u5173 responses \u6A21\u677F\u540C\u6784\uFF09\u3002
    # chat_openai \u6784\u9020\u4E0D\u8054\u7F51\uFF1B\u8BF7\u6C42 = {base_url}/responses\uFF0Cbase_url \u4EE5 /v1 \u6536\u5C3E\u3002
  } else if (identical(provider, "openai")) {
    ellmer::chat_openai(
      system_prompt = system_prompt,
      base_url = base_url,
      credentials = if (nzchar(dairh_api_key_value(cfg))) {
        function() dairh_api_key_value(cfg)
      } else NULL,
      model = model,
      params = params,
      api_args = if (nzchar(effort)) {
        list(reasoning = list(effort = effort, summary = "auto"))
      } else {
        list()
      },
      api_headers = headers,
      echo = "none"
    )
    # 0.9 Anthropic Messages \u534F\u8BAE\u76F4\u8FDE\uFF08\u4E0E\u7F51\u5173 messages \u6A21\u677F\u540C\u6784\uFF09\uFF1A\u8BF7\u6C42 = {base_url}/messages\u3002
    # reasoning_effort \u5728 Anthropic \u662F budget \u8BED\u4E49\uFF0C\u4E0D\u900F\u4F20\uFF08params \u767D\u540D\u5355\u4F1A\u4E22\uFF09\u3002
  } else if (identical(provider, "anthropic")) {
    ellmer::chat_anthropic(
      system_prompt = system_prompt,
      base_url = base_url,
      credentials = if (nzchar(dairh_api_key_value(cfg))) {
        function() dairh_api_key_value(cfg)
      } else NULL,
      model = model,
      params = .dai_build_params(temperature, ""),
      api_headers = headers,
      echo = "none"
    )
  } else {
    stop("\u672A\u77E5\u7684 provider: ", cfg$provider, "\uFF08\u5E94\u4E3A ollama / openai_compatible / openai / anthropic\uFF09",
      call. = FALSE
    )
  }
  # 0.6 \u8D77\u552F\u4E00\u6302\u70B9\uFF1A\u6240\u6709\u7ECF dairh_client() \u51FA\u6765\u7684\u4F1A\u8BDD\uFF08\u4E3B\u5BF9\u8BDD/\u5B50\u4EE3\u7406/\u8D77\u6807\u9898/
  # \u538B\u7F29\u603B\u7ED3\u5668\uFF09\u90FD\u81EA\u52A8\u8BB0\u5F55 token \u7528\u91CF\uFF08DAIRH_USAGE_LOG=0 \u53EF\u6574\u4F53\u5173\u95ED\uFF09\u3002
  .dairh_usage_install(cl, model)
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
      } else if (identical(provider, "anthropic")) {
        # Anthropic Messages \u539F\u751F\u5217\u6A21\u578B\uFF1AGET {base_url}/models\uFF0C
        # \u8BA4 x-api-key + anthropic-version\uFF08Bearer \u4E0D\u6536\u2014\u20140.9 \u5B9E\u6D4B\uFF09\u3002
        req <- httr2::request(base_url) |>
          httr2::req_url_path("models") |>
          httr2::req_timeout(timeout_s)
        key <- dairh_api_key_value(cfg)
        if (nzchar(key)) {
          req <- req |>
            httr2::req_headers(`x-api-key` = key,
              `anthropic-version` = "2023-06-01")
        }
        resp <- httr2::req_perform(req)
        body <- httr2::resp_body_json(resp)
        out <- vapply(body$data, function(x) x$id %||% x$name %||% NA_character_,
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
