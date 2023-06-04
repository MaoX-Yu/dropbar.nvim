local M = {}

---@class dropbar_configs_t
M.opts = {
  general = {
    ---@type boolean|fun(buf: integer, win: integer): boolean
    enable = function(buf, win)
      return not vim.api.nvim_win_get_config(win).zindex
        and vim.bo[buf].buftype == ''
        and vim.api.nvim_buf_get_name(buf) ~= ''
        and not vim.wo[win].diff
    end,
    update_events = {
      win = {
        'CursorMoved',
        'CursorMovedI',
        'WinEnter',
        'WinResized',
        'WinScrolled',
      },
      buf = {
        'BufModifiedSet',
        'FileChangedShellPost',
        'TextChanged',
        'TextChangedI',
      },
      global = {
        'DirChanged',
        'VimResized',
      },
    },
  },
  icons = {
    kinds = {
      use_devicons = true,
      symbols = {
        Array = '󰅪 ',
        Boolean = ' ',
        BreakStatement = '󰙧 ',
        Call = '󰃷 ',
        CaseStatement = '󱃙 ',
        Class = ' ',
        Color = '󰏘 ',
        Constant = '󰏿 ',
        Constructor = ' ',
        ContinueStatement = '→ ',
        Copilot = ' ',
        Declaration = '󰙠 ',
        Delete = '󰩺 ',
        DoStatement = '󰑖 ',
        Enum = ' ',
        EnumMember = ' ',
        Event = ' ',
        Field = ' ',
        File = '󰈔 ',
        Folder = '󰉋 ',
        ForStatement = '󰑖 ',
        Function = '󰊕 ',
        Identifier = '󰀫 ',
        IfStatement = '󰇉 ',
        Interface = ' ',
        Keyword = '󰌋 ',
        List = '󰅪 ',
        Log = '󰦪 ',
        Lsp = ' ',
        Macro = '󰁌 ',
        MarkdownH1 = '󰉫 ',
        MarkdownH2 = '󰉬 ',
        MarkdownH3 = '󰉭 ',
        MarkdownH4 = '󰉮 ',
        MarkdownH5 = '󰉯 ',
        MarkdownH6 = '󰉰 ',
        Method = '󰆧 ',
        Module = '󰏗 ',
        Namespace = '󰅩 ',
        Null = '󰢤 ',
        Number = '󰎠 ',
        Object = '󰅩 ',
        Operator = '󰆕 ',
        Package = '󰆦 ',
        Property = ' ',
        Reference = '󰦾 ',
        Regex = ' ',
        Repeat = '󰑖 ',
        Scope = '󰅩 ',
        Snippet = '󰩫 ',
        Specifier = '󰦪 ',
        Statement = '󰅩 ',
        String = '󰉾 ',
        Struct = ' ',
        SwitchStatement = '󰺟 ',
        Text = ' ',
        Type = ' ',
        TypeParameter = '󰆩 ',
        Unit = ' ',
        Value = '󰎠 ',
        Variable = '󰀫 ',
        WhileStatement = '󰑖 ',
      },
    },
    ui = {
      bar = {
        separator = ' ',
        extends = '…',
      },
      menu = {
        separator = ' ',
        indicator = ' ',
      },
    },
  },
  bar = {
    ---@type dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]
    sources = function(_, _)
      local sources = require('dropbar.sources')
      return {
        sources.path,
        {
          get_symbols = function(buf, cursor)
            if vim.bo[buf].ft == 'markdown' then
              return sources.markdown.get_symbols(buf, cursor)
            end
            for _, source in ipairs({
              sources.lsp,
              sources.treesitter,
            }) do
              local symbols = source.get_symbols(buf, cursor)
              if not vim.tbl_isempty(symbols) then
                return symbols
              end
            end
            return {}
          end,
        },
      }
    end,
    padding = {
      left = 1,
      right = 1,
    },
    pick = {
      pivots = 'abcdefghijklmnopqrstuvwxyz',
    },
    truncate = true,
  },
  menu = {
    entry = {
      padding = {
        left = 1,
        right = 1,
      },
    },
    ---@type table<string, string|function|table<string, string|function>>
    keymaps = {
      ['<LeftMouse>'] = function()
        local api = require('dropbar.api')
        local menu = api.get_current_dropbar_menu()
        if not menu then
          return
        end
        local mouse = vim.fn.getmousepos()
        if mouse.winid ~= menu.win then
          local parent_menu = api.get_dropbar_menu(mouse.winid)
          if parent_menu and parent_menu.sub_menu then
            parent_menu.sub_menu:close()
          end
          if vim.api.nvim_win_is_valid(mouse.winid) then
            vim.api.nvim_set_current_win(mouse.winid)
          end
          return
        end
        menu:click_at({ mouse.line, mouse.column }, nil, 1, 'l')
      end,
      ['<CR>'] = function()
        local menu = require('dropbar.api').get_current_dropbar_menu()
        if not menu then
          return
        end
        local cursor = vim.api.nvim_win_get_cursor(menu.win)
        local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
        if component then
          menu:click_on(component, nil, 1, 'l')
        end
      end,
      ['<MouseMove>'] = function()
        local menu = require('dropbar.api').get_current_dropbar_menu()
        if not menu then
          return
        end
        local mouse = vim.fn.getmousepos()
        if mouse.winid ~= menu.win then
          return
        end
        menu:update_hover_hl({ mouse.line, mouse.column })
      end,
    },
    ---@alias dropbar_menu_win_config_opts_t any|fun(menu: dropbar_menu_t):any
    ---@type table<string, dropbar_menu_win_config_opts_t>
    ---@see vim.api.nvim_open_win
    win_configs = {
      border = 'none',
      style = 'minimal',
      row = function(menu)
        return menu.parent_menu
            and menu.parent_menu.clicked_at
            and menu.parent_menu.clicked_at[1] - vim.fn.line('w0')
          or 1
      end,
      col = function(menu)
        return menu.parent_menu and menu.parent_menu._win_configs.width or 0
      end,
      relative = function(menu)
        return menu.parent_menu and 'win' or 'mouse'
      end,
      win = function(menu)
        return menu.parent_menu and menu.parent_menu.win
      end,
      height = function(menu)
        return math.max(
          1,
          math.min(
            #menu.entries,
            vim.go.pumheight ~= 0 and vim.go.pumheight
              or math.ceil(vim.go.lines / 4)
          )
        )
      end,
      width = function(menu)
        local min_width = vim.go.pumwidth ~= 0 and vim.go.pumwidth or 8
        if vim.tbl_isempty(menu.entries) then
          return min_width
        end
        return math.max(
          min_width,
          math.max(unpack(vim.tbl_map(function(entry)
            return entry:displaywidth()
          end, menu.entries)))
        )
      end,
    },
  },
  sources = {
    path = {
      ---@type string|fun(buf: integer): string
      relative_to = function(_)
        return vim.fn.getcwd()
      end,
      ---Can be used to filter out files or directories
      ---based on their name
      ---@type fun(name: string): boolean
      filter = function(_)
        return true
      end,
      ---Symbol of current buf is modified
      ---@param sym dropbar_symbol_t
      ---@return dropbar_symbol_t
      modified = function(sym)
        return sym
      end,
    },
    treesitter = {
      -- Lua pattern used to extract a short name from the node text
      -- Be aware that the match result must not be nil!
      name_pattern = string.rep('[#~%w%._%->!]*', 4, '%s*'),
      -- The order matters! The first match is used as the type
      -- of the treesitter symbol and used to show the icon
      -- Types listed below must have corresponding icons
      -- in the `icons.kinds.symbols` table for the icon to be shown
      valid_types = {
        'array',
        'boolean',
        'break_statement',
        'call',
        'case_statement',
        'class',
        'constant',
        'constructor',
        'continue_statement',
        'delete',
        'do_statement',
        'enum',
        'enum_member',
        'event',
        'for_statement',
        'function',
        'if_statement',
        'interface',
        'keyword',
        'list',
        'macro',
        'method',
        'module',
        'namespace',
        'null',
        'number',
        'operator',
        'package',
        'property',
        'reference',
        'repeat',
        'scope',
        'specifier',
        'string',
        'struct',
        'switch_statement',
        'type',
        'type_parameter',
        'unit',
        'value',
        'variable',
        'while_statement',
        'declaration',
        'field',
        'identifier',
        'object',
        'statement',
        'text',
      },
    },
    lsp = {
      request = {
        -- Times to retry a request before giving up
        ttl_init = 60,
        interval = 1000, -- in ms
      },
    },
    markdown = {
      parse = {
        -- Number of lines to update when cursor moves out of the parsed range
        look_ahead = 200,
      },
    },
  },
}

---Set dropbar options
---@param new_opts dropbar_configs_t?
function M.set(new_opts)
  new_opts = new_opts or {}
  -- Notify deprecated options
  if new_opts.general and vim.tbl_islist(new_opts.general.update_events) then
    vim.api.nvim_echo({
      { '[dropbar.nvim] ', 'Normal' },
      { 'opts.general.update_events', 'WarningMsg' },
      { ' is deprecated.\n', 'Normal' },
      { '[dropbar.nvim] ', 'Normal' },
      { 'Please use\n', 'Normal' },
      { '               opts.general.update_events.win ', 'WarningMsg' },
      { 'for updating a winbar attached to a single window,\n', 'Normal' },
      { '               opts.general.update_events.buf ', 'WarningMsg' },
      { 'for updating all winbars attached to a buffer, or\n', 'Normal' },
      { '               opts.general.update_events.global ', 'WarningMsg' },
      { 'for updating all winbars in current nvim session ', 'Normal' },
      { 'instead.\n', 'Normal' },
    }, true, {})
    new_opts.general.update_events = {
      win = new_opts.general.update_events,
    }
  end
  M.opts = vim.tbl_deep_extend('force', M.opts, new_opts)
end

---Evaluate a dynamic option value (with type T|fun(...): T)
---@generic T
---@param opt T|fun(...): T
---@return T
function M.eval(opt, ...)
  if type(opt) == 'function' then
    return opt(...)
  end
  return opt
end

return M
