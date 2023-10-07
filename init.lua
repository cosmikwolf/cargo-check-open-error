local function get_warning_or_error_block()
  local cursor_pos = vim.fn.getcurpos()
  local current_line = vim.fn.getline(cursor_pos[1])
  local warning_or_error_block = {}
  if current_line:match("^%s*(warning|error)") then
    table.insert(warning_or_error_block, current_line)
    local next_line = vim.fn.getline(cursor_pos[1] + 1)
    local file_path = next_line:match("%s+-->[%s]+(.+)")
    if file_path then
      table.insert(warning_or_error_block, next_line)
      local i = cursor_pos[1] + 2
      while i <= vim.fn.line("$") do
        local line = vim.fn.getline(i)
        if line == "" then
          break
        end
        if line:match("^%s+-->[%s]+") then
          local path = line:match("%s+-->[%s]+(.+)")
          if path and path ~= file_path then
            break
          end
        end
        table.insert(warning_or_error_block, line)
        i = i + 1
      end
    end
  end
  return warning_or_error_block
end

local function open_file_in_pane(file_path)
  vim.cmd("wincmd p")
  vim.cmd("edit " .. file_path)
  vim.cmd("wincmd p")
  vim.cmd("close")
end

local function launch_browser_with_search_term(search_term)
  local browser = "firefox"
  local search_engine = "duckduckgo"
  local url = "https://www." .. search_engine .. ".com/search?q=" .. search_term
  vim.fn.jobstart({ browser, url })
end

local function on_hover()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result, ctx, config)
    if err then
      print('Error:', err)
      return
    end
    if not result or vim.tbl_isempty(result) then
      print('No hover information available')
      return
    end
    local contents = result.contents
    if type(contents) == 'table' then
      contents = vim.lsp.util.convert_input_to_markdown_lines(contents)
    end
    if vim.tbl_islist(contents) then
      contents = table.concat(contents, '\n')
    end
    local search_term = table.concat(contents, " ")
    local choice = vim.fn.inputlist({ "Open file in pane", "Launch browser with search term" })
    if choice == 1 then
      local file_path = get_warning_or_error_block()[2]:match("%s+-->[%s]+(.+)")
      open_file_in_pane(file_path)
    elseif choice == 2 then
      launch_browser_with_search_term(search_term)
    end
  end)
end

local M = {}

function M.setup()
  vim.cmd("let mapleader = ','")
  vim.cmd(
  "autocmd BufRead,BufNewFile *:cargo check lua if vim.fn.expand('%:t') =~ #^%%d+:cargo check$# then vim.api.nvim_buf_set_keymap(vim.fn.bufnr('%'), 'n', '<leader>h', ':lua require(\"myplugin\").on_hover()<CR>', {noremap = true, silent = true}) end")
end

return M
