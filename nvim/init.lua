-- Leader key: Space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Turn off the built-in file browser (nvim-tree replaces it)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Options
vim.o.termguicolors = true  -- full color for the sorbet theme
vim.o.modeline = false      -- ignore config lines hidden inside files
vim.o.number = true
vim.o.relativenumber = false
vim.o.fillchars = "eob: ,vert:│" -- hide ~ after end of file, thin split line
vim.o.laststatus = 3                -- one status bar across the bottom
vim.o.showmode = false              -- mode is already in the status bar
vim.o.cursorlineopt = "number"      -- highlight only the current line number
vim.o.statuscolumn = " %s%=%l  "    -- space on the left, gap between line numbers and code
vim.o.sidescrolloff = 8
vim.o.linebreak = true              -- wrap long lines at word boundaries
vim.o.breakindent = true            -- wrapped lines keep the indent of their line

vim.cmd.colorscheme("sorbet") -- built into Neovim, no download
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.scrolloff = 8
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.clipboard = "unnamedplus"

-- Plugins, pinned (checked 2026-10-30, all >= 14 days old)
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.nvim", version = "v0.18.0" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "ca581c3436fc2b236847f5b739ebc263739e5ca6" },
  -- nvim-tree pinned to a 1-day-old commit by choice; diff since 355bcc8 reviewed 2026-10-30
  { src = "https://github.com/nvim-tree/nvim-tree.lua", version = "96b6d0ea594a1e519abd58fd8b60a39a9dec1869" },
  -- v8.14.0 (released 2026-09-15), source scanned 2026-10-30: no network calls, shell only for latex
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim", version = "640a3ec6d538bad17c328be373c7cad0293d9589" },
})

-- Repo-wide change count for the status bar, Warp-style: "files • +added -removed"
-- New files count as all-added; gitignored files are skipped
local changes = ""
local function refresh_changes()
  local root = vim.fs.root(0, ".git")
  if not root then changes = "" return end
  vim.system({ "git", "diff", "HEAD", "--numstat" }, { cwd = root, text = true }, function(diff)
    vim.system({ "git", "ls-files", "--others", "--exclude-standard" }, { cwd = root, text = true }, function(new)
      vim.schedule(function()
        local files, add, del = 0, 0, 0
        for a, d in (diff.stdout or ""):gmatch("(%S+)\t(%S+)\t[^\n]*") do
          files, add, del = files + 1, add + (tonumber(a) or 0), del + (tonumber(d) or 0)
        end
        for f in (new.stdout or ""):gmatch("[^\n]+") do
          files = files + 1
          local path = root .. "/" .. f
          local fd = io.open(path, "rb")
          local head = fd and fd:read(8000) or ""
          if fd then fd:close() end
          -- count lines only for text files; binary files (images) have NUL bytes, like git's own check
          if not head:find("\0", 1, true) and vim.fn.getfsize(path) < 1e6 then
            add = add + #vim.fn.readfile(path)
          end
        end
        changes = files == 0 and "" or string.format(
          "%d • %%#MiniStatuslineChangesAdd#+%d %%#MiniStatuslineChangesDel#-%d", files, add, del)
        vim.cmd.redrawstatus()
      end)
    end)
  end)
end
vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "BufWritePost", "FocusGained" }, { callback = refresh_changes })

-- mini.nvim modules
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons() -- lets nvim-tree use mini.icons
local statusline = require("mini.statusline")
statusline.setup({
  content = {
    -- lualine-style: mode block, git branch + changes, file | file type, line:column
    active = function()
      local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
      local git = statusline.section_git({ trunc_width = 40 })
      local ft = vim.bo.filetype
      local icon = ft ~= "" and (MiniIcons.get("filetype", ft)) or ""
      return statusline.combine_groups({
        { hl = mode_hl, strings = { mode:upper() } },
        { hl = "MiniStatuslineDevinfo", strings = { git } },
        { hl = "MiniStatuslineDevinfo", strings = { changes } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { vim.fn.expand("%:~:.") .. "%m" } },
        "%=",
        { hl = "MiniStatuslineFileinfo", strings = { ft ~= "" and (icon .. " " .. ft) or "" } },
        { hl = mode_hl, strings = { "%l:%c" } },
      })
    end,
  },
})
require("mini.tabline").setup({ tabpage_section = "none" })
require("mini.files").setup({ options = { use_as_default_explorer = false } }) -- nvim-tree owns folder views
require("mini.pick").setup()
require("mini.extra").setup()
require("mini.diff").setup()
require("mini.git").setup() -- git branch in the status bar
require("mini.pairs").setup()
require("mini.surround").setup()
require("mini.ai").setup()

local miniclue = require("mini.clue")
miniclue.setup({
  triggers = {
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },
    { mode = "n", keys = "<C-w>" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
  },
  clues = {
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
    { mode = "n", keys = "<Leader>f", desc = "+find" },
    { mode = "n", keys = "<Leader>g", desc = "+git" },
  },
  window = { delay = 300 },
})

-- Sidebar file tree on the right, like Zed
require("nvim-tree").setup({
  view = { side = "right", width = 36, signcolumn = "yes" }, -- signcolumn = small left gap
  renderer = {
    group_empty = true,
    root_folder_label = ":t", -- just the folder name
    indent_markers = { enable = true },
    highlight_git = "name", -- color file names by git status
  },
  filters = {
    custom = { "^.git$" },
    git_ignored = false, -- show gitignored files, dimmed with ◌, instead of hiding them
  },
  update_focused_file = { enable = true },
})

-- Quiet UI: bars blend into the background, colors taken from the theme
local function quiet_ui()
  local hl = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end
  local fg = function(name) return vim.api.nvim_get_hl(0, { name = name, link = false }).fg end
  local bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
  local text, dim, warn = fg("Normal"), fg("Comment"), fg("DiagnosticWarn")

  -- Glass: drop the theme background so the terminal's transparency shows through
  for _, name in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "LineNr",
                          "CursorLineNr", "FoldColumn", "WinSeparator", "NvimTreeNormal",
                          "NvimTreeNormalNC", "NvimTreeEndOfBuffer", "NvimTreeWinSeparator" }) do
    local def = vim.api.nvim_get_hl(0, { name = name, link = false })
    def.bg = nil
    vim.api.nvim_set_hl(0, name, def)
  end
  local base = bg -- the theme color, still used as text on the colored mode block
  bg = "NONE"     -- bars below become see-through too

  hl("NormalFloat", { fg = text, bg = bg }) -- popups (find files, file browser) match the editor, not sorbet's light gray
  hl("NvimTreeWinSeparator", { link = "WinSeparator" })
  hl("NvimTreeIndentMarker", { fg = dim })
  hl("StatusLine", { fg = text, bg = bg })
  hl("StatusLineNC", { fg = dim, bg = bg })
  hl("MiniStatuslineFilename", { fg = text, bg = bg })
  hl("MiniStatuslineInactive", { fg = dim, bg = bg })
  local modes = { Normal = "Function", Insert = "String", Visual = "Statement",
                  Replace = "DiagnosticError", Command = "DiagnosticWarn", Other = "Special" }
  for mode, group in pairs(modes) do
    hl("MiniStatuslineMode" .. mode, { fg = base, bg = fg(group) }) -- colored block
  end
  local panel = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false }).bg or bg
  hl("MiniStatuslineDevinfo", { fg = text, bg = panel })
  hl("MiniStatuslineChangesAdd", { fg = fg("Added"), bg = panel })
  hl("MiniStatuslineChangesDel", { fg = fg("Removed"), bg = panel })
  -- :Changes panel (Warp-style cards)
  hl("ChangesHeader", { fg = text, bg = panel })
  hl("ChangesAddText", { fg = fg("Added"), bg = panel })
  hl("ChangesDelText", { fg = fg("Removed"), bg = panel })
  hl("ChangesAddLine", { bg = "#1f3326" }) -- dark green, like Warp's added lines
  hl("ChangesDelLine", { bg = "#3a2024" }) -- dark red for removed lines
  hl("MiniStatuslineFileinfo", { fg = dim, bg = bg })
  hl("TabLineFill", { bg = bg })
  hl("MiniTablineFill", { bg = bg })
  hl("MiniTablineCurrent", { fg = text, bg = bg, underline = true })
  hl("MiniTablineVisible", { fg = text, bg = bg })
  hl("MiniTablineHidden", { fg = dim, bg = bg })
  hl("MiniTablineModifiedCurrent", { fg = warn, bg = bg, underline = true })
  hl("MiniTablineModifiedVisible", { fg = warn, bg = bg })
  hl("MiniTablineModifiedHidden", { fg = warn, bg = bg })

  -- Remove bold everywhere (tree folders, headings, keywords), keep it only for **bold** text
  for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
    if not def.link and name ~= "@markup.strong" and (def.bold or (def.cterm and def.cterm.bold)) then
      def.bold = nil
      if def.cterm then def.cterm.bold = nil end
      vim.api.nvim_set_hl(0, name, def)
    end
  end

  -- Markdown headings: one theme color per level, bold, no background
  local levels = { "Function", "String", "Statement", "Special", "Comment", "Constant" }
  for i, group in ipairs(levels) do
    hl("MarkdownGlassH" .. i, { fg = fg(group), bold = true })
  end
end
quiet_ui()
vim.api.nvim_create_autocmd("ColorScheme", { callback = quiet_ui })

-- Markdown: rendered headings, lists, checkboxes and tables in the buffer
require("render-markdown").setup({
  latex = { enabled = false }, -- latex is the only part that runs outside programs
  heading = { -- colored heading text instead of solid bars, keeps the glass look
    backgrounds = { "MarkdownGlassH1", "MarkdownGlassH2", "MarkdownGlassH3",
                    "MarkdownGlassH4", "MarkdownGlassH5", "MarkdownGlassH6" },
    foregrounds = { "MarkdownGlassH1", "MarkdownGlassH2", "MarkdownGlassH3",
                    "MarkdownGlassH4", "MarkdownGlassH5", "MarkdownGlassH6" },
  },
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = true -- underline typos, ]s / [s to jump, z= for fixes
  end,
})

-- Images and PDFs: open in the Mac viewer (Preview) instead of as raw bytes
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.ico", "*.pdf" },
  callback = function(args)
    vim.ui.open(args.file)
    vim.schedule(function()
      local prev = vim.fn.bufnr("#")
      if prev > 0 and prev ~= args.buf and vim.fn.buflisted(prev) == 1 then
        vim.cmd("buffer #") -- go back to the file you were on, not an empty window
      end
      vim.api.nvim_buf_delete(args.buf, { force = true })
    end)
  end,
})

-- Treesitter highlighting, only for languages with an installed parser
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- Shortcuts
local map = vim.keymap.set

-- find
map("n", "<Leader>ff", function() MiniPick.builtin.files() end, { desc = "Find files" })
map("n", "<Leader>fg", function() MiniPick.builtin.grep_live() end, { desc = "Search text in project" })
map("n", "<Leader>fw", function() MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") }) end, { desc = "Search word under cursor" })
map("n", "<Leader>fb", function() MiniPick.builtin.buffers() end, { desc = "Open buffers" })
map("n", "<Leader>fr", function() MiniExtra.pickers.oldfiles() end, { desc = "Recent files" })
map("n", "<Leader>fh", function() MiniPick.builtin.help() end, { desc = "Help" })
map("n", "<Leader>fk", function() MiniExtra.pickers.keymaps() end, { desc = "Keymaps" })
map("n", "<Leader>fc", function() MiniPick.builtin.resume() end, { desc = "Resume last search" })
map("n", "<Leader><Leader>", function() MiniPick.builtin.files() end, { desc = "Find files" })

-- explorer
map("n", "<Leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })
map("n", "<Leader>E", "<cmd>NvimTreeFindFile<cr>", { desc = "Show current file in tree" })
map("n", "-", function()
  local path = vim.api.nvim_buf_get_name(0)
  MiniFiles.open(vim.uv.fs_stat(path) and path or nil)
end, { desc = "Quick file browser (popup)" })

-- :Changes - Warp-style panel on the right: one card per changed file
-- New files show as all-added, gitignored files are skipped
-- Keys: Enter = open file at that line (on a file header: fold/unfold), x = discard file, r = refresh, q = close
local changes_ns = vim.api.nvim_create_namespace("changes_panel")

local function collect_changes(root)
  local git = function(args) return vim.fn.systemlist(vim.list_extend({ "git", "-C", root }, args)) end
  local diff, new = git({ "diff", "--no-color", "HEAD" }), {}
  for _, f in ipairs(git({ "ls-files", "--others", "--exclude-standard" })) do
    new[f] = true
    vim.list_extend(diff, git({ "diff", "--no-color", "--no-index", "/dev/null", f }))
  end
  -- Parse the unified diff into files -> rows with real line numbers
  local files, cur, in_header, old_n, new_n = {}, nil, false, 0, 0
  for _, l in ipairs(diff) do
    local path = l:match("^diff %-%-git a/.- b/(.+)$")
    local o, n = l:match("^@@ %-(%d+),?%d* %+(%d+),?%d* @@")
    if path then
      cur, in_header = { path = path, new = new[path], add = 0, del = 0, rows = {} }, true
      table.insert(files, cur)
    elseif cur and o then
      if #cur.rows > 0 then table.insert(cur.rows, { kind = "gap" }) end
      in_header, old_n, new_n = false, tonumber(o), tonumber(n)
    elseif cur and not in_header then
      local c, text = l:sub(1, 1), l:sub(2)
      if c == "+" then
        table.insert(cur.rows, { kind = "add", n = new_n, at = new_n, text = text })
        new_n, cur.add = new_n + 1, cur.add + 1
      elseif c == "-" then
        table.insert(cur.rows, { kind = "del", n = old_n, at = new_n, text = text })
        old_n, cur.del = old_n + 1, cur.del + 1
      elseif c == " " then
        table.insert(cur.rows, { kind = "ctx", n = new_n, at = new_n, text = text })
        old_n, new_n = old_n + 1, new_n + 1
      end
    end
  end
  return files
end

vim.api.nvim_create_user_command("Changes", function()
  local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
  local files, folded, rows = collect_changes(root), {}, {}
  if #files == 0 then return vim.notify("No changes") end
  vim.cmd("botright vnew") -- opens as a panel on the far right, like Warp
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].filetype = "nofile", "wipe", "changes"
  for opt, val in pairs({ number = false, relativenumber = false, signcolumn = "no", statuscolumn = "",
                          foldcolumn = "0", spell = false, cursorline = true, cursorlineopt = "line" }) do
    vim.wo[win][opt] = val
  end

  local function render()
    local lines, marks = {}, {}
    rows = {}
    local function add(text, row) table.insert(lines, text); rows[#lines] = row end
    for _, f in ipairs(files) do
      local head = string.format(" %s %s  ", folded[f.path] and "▸" or "▾", f.path)
      local plus, minus = "+" .. f.add, " -" .. f.del
      add(head .. plus .. minus, { file = f, header = true })
      table.insert(marks, { #lines, "ChangesHeader" })
      table.insert(marks, { #lines, "ChangesAddText", #head, #head + #plus })
      table.insert(marks, { #lines, "ChangesDelText", #head + #plus, #head + #plus + #minus })
      if not folded[f.path] then
        for _, r in ipairs(f.rows) do
          if r.kind == "gap" then
            add("      ⋯", { file = f })
            table.insert(marks, { #lines, "Comment" })
          else
            local num = string.format(" %4d  ", r.n)
            add(num .. r.text, { file = f, lnum = r.at })
            table.insert(marks, { #lines, "LineNr", 0, #num })
            if r.kind == "add" then table.insert(marks, { #lines, "ChangesAddLine" }) end
            if r.kind == "del" then table.insert(marks, { #lines, "ChangesDelLine" }) end
          end
        end
      end
      add("", nil)
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, changes_ns, 0, -1)
    for _, m in ipairs(marks) do
      local opts = m[3] and { end_col = m[4], hl_group = m[2], priority = 200 } or { line_hl_group = m[2] }
      vim.api.nvim_buf_set_extmark(buf, changes_ns, m[1] - 1, m[3] or 0, opts)
    end
  end

  local function refresh()
    files = collect_changes(root)
    refresh_changes()
    if #files == 0 then
      vim.api.nvim_win_close(win, true)
      return vim.notify("No changes left")
    end
    render()
  end

  local function here(key, fn, desc) vim.keymap.set("n", key, fn, { buffer = buf, desc = desc }) end
  here("q", "<cmd>close<cr>", "Close changes panel")
  here("r", refresh, "Refresh changes")

  here("<CR>", function()
    local row = rows[vim.fn.line(".")]
    if not row then return end
    if row.header then
      folded[row.file.path] = not folded[row.file.path]
      return render()
    end
    if not row.lnum then return end
    -- open in a normal editor window, never in the panel or the file tree
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local b = vim.api.nvim_win_get_buf(w)
      if w ~= win and vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "NvimTree" then
        vim.api.nvim_set_current_win(w)
        vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. row.file.path))
        return pcall(vim.api.nvim_win_set_cursor, w, { math.max(row.lnum, 1), 0 })
      end
    end
    vim.cmd("leftabove vsplit " .. vim.fn.fnameescape(root .. "/" .. row.file.path))
    pcall(vim.api.nvim_win_set_cursor, 0, { math.max(row.lnum, 1), 0 })
  end, "Open file at this line / fold file")

  -- x: discard the file under the cursor, after a y/N confirm (default is No)
  -- tracked file -> back to the last commit; new file -> macOS Trash, so it can be recovered
  here("x", function()
    local row = rows[vim.fn.line(".")]
    if not row then return end
    local f = row.file
    local question = f.new and ("Move new file " .. f.path .. " to the Trash?")
                            or ("Discard all changes to " .. f.path .. "?")
    if vim.fn.confirm(question, "&Yes\n&No", 2) ~= 1 then return end
    local res = f.new and vim.system({ "/usr/bin/trash", root .. "/" .. f.path }):wait()
      or vim.system({ "git", "-C", root, "restore", "--source=HEAD", "--staged", "--worktree", "--", f.path }):wait()
    if res.code ~= 0 then return vim.notify(res.stderr, vim.log.levels.ERROR) end
    vim.cmd("checktime") -- reload open files from disk
    refresh()
  end, "Discard changes to this file")

  render()
end, { desc = "Show all changes, including new files" })

-- git
map("n", "<Leader>gs", "<cmd>Changes<cr>", { desc = "All changes (incl. new files)" })
map("n", "<Leader>gd", function() MiniDiff.toggle_overlay(0) end, { desc = "Show diff inline" })
map("n", "<Leader>gc", function() MiniExtra.pickers.git_hunks() end, { desc = "Changed lines" })

-- everyday
map("n", "<Leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<Leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("x", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("x", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
