library(ellmer)


coding_client <- ellmer::chat_ollama(model = 'gemma4:12b',
                                     #model = 'qwen3.5:9b',
                                     base_url = 'http://localhost:11434',
                                     #params = params(seed = 1128),
                                     api_args = list(temperature = 0.7),
                                     echo = 'all')

## 基于coding界面
chat_app(coding_client)
