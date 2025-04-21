require("avante_lib").load()
require("avante").setup({
  provider = "openai",
  auto_suggestions_provider = "openai",
  openai = {
    api_key_name = {"sh", "-c", "cat ~/.config/openai/api_key | tr -d \"\\n\""},
  },
  behaviour = {
    enable_cursor_planning_mode = true,
  },
})
