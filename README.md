# ultipreview.nvim

[WIP] Adds a preview window for ultisnippet completion sources to completion-nvim menu



## Usage

```vim
Plug 'SirVer/ultisnips'
Plug 'nvim-lua/completion-nvim'

Plug 'fhill2/ultipreview.nvim'
```

add to custom on_attach function in nvim lsp config something like this:

```lua
local completion = require('completion')
local ultipreview = require('ultipreview')

local custom_attach = function()
completion.on_attach()
ultipreview.on_attach()
end

require'lspconfig'.sumneko_lua.setup {
      on_attach = custom_attach,
        -- your config here
}
```

## Features
Async timer completion (from completion-nvim)
Treesitter highlighted preview window, falls back to regex (from telescope-nvim)
Async read file (from telescope-nvim)



## Why?
Currently ultisnippets only returns snippet name & description for other plugin authors to implement with their plugin. 
Because of this, the content of each snippet is read from the snippet files available in the current buffer when a Ultisnippets completion source is selected in the completion-nvim dropdown (how coc-snippets does it)


This plugin could work with other completion providers as it doesn't rely on completion-nvim to be installed. So far I have only tested with completion-nvim.


## Limitations

Currently if 2 ultisnip snippets available in the current buffer have the same name, the first one will only be able to be previewed. Working on fixing this.
To check: 
```vim
echo g:current_ulti_dict_info
```


## Progress

- vsnip support 
- choose between 'snippets' syntax or treesitter/regex
- config option for description in preview window
- match location of preview window with completion-nvim menu when in docked mode
- fix same name snippets



___

## Contributions
all PRs welcome




<!--
TODO: additional fixes
make sure lua-2ndcategory.snippets get colored
-->
