local M = {}
local api = vim.api
local opt = require 'completion.option'
local validate = vim.validate

function M.on_InsertLeave() M.insertLeave = true end

function M.on_InsertEnter()

    M.insertLeave = false
    local timer = vim.loop.new_timer()

    timer:start(0, 80, vim.schedule_wrap(
                    function()

            M.autoOpenUltisnips()

            if vim.fn.pumvisible() ~= 1 then
                if M.winnr ~= nil and api.nvim_win_is_valid(M.winnr) then
                    api.nvim_win_close(M.winnr, true)
                end
                M.winnr = nil
                return
            end

            if M.insertLeave == true and timer:is_closing() == false then
                timer:stop()
                timer:close()

            end
        end))
end

local read_file_async = function(filepath, callback)

    vim.loop.fs_open(filepath, 'r', 438, function(err_open, fd)
        if err_open then
            print(
                'We tried to open this file but couldn\'t. We failed with following error message: ' ..
                    err_open)
            return
        end
        vim.loop.fs_fstat(fd, function(err_fstat, stat)
            assert(not err_fstat, err_fstat)
            if stat.type ~= 'file' then return callback('') end
            vim.loop.fs_read(fd, stat.size, 0, function(err_read, data)
                assert(not err_read, err_read)
                vim.loop.fs_close(fd, function(err_close)
                    assert(not err_close, err_close)
                    return callback(data)
                end)
            end)
        end)
    end)
end

M.load_floating_contents = function(name)

    if vim.fn.exists('*UltiSnips#SnippetsInCurrentScope') == 0 then return {} end
    vim.call('UltiSnips#SnippetsInCurrentScope', 1)
    local snippetsList = vim.g.current_ulti_dict_info

    local ultisnips_path = snippetsList[name].location

    if string.find(ultisnips_path, '\\') ~= nil then
        delim = '\\'
    elseif string.find(ultisnips_path, '/') ~= nil then
        delim = '/'
    end

    local all_matches = {}
    for match in string.gmatch(ultisnips_path, '%w+[^' .. delim .. ']+') do
        table.insert(all_matches, match)
    end

    local filepath = string.gsub(ultisnips_path, '.snippets:%d*', '.snippets')
    local _, _, linenr = string.find(ultisnips_path, ':(%d+)')
    local linenr = tonumber(linenr)

    read_file_async(filepath, vim.schedule_wrap(
                        function(data)

            local data = vim.split(data, '[\r]?\n')

            local snippet = {}
            local findmaxstr = {}
            for i, v in ipairs(data) do
                if i > linenr then
                    if v ~= 'endsnippet' then
                        table.insert(snippet, v)
                        local linewidth = api.nvim_strwidth(v)
                        table.insert(findmaxstr, linewidth)
                    elseif v == 'endsnippet' then

                        break
                    end
                end
            end

            local function max(a)
                local values = {}

                for k, v in pairs(a) do values[#values + 1] = v end
                table.sort(values) -- automatically sorts lowest to highest

                return values[#values]
            end

            vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, true, snippet)

            local winopts = {width = max(findmaxstr) + 1, height = #snippet}

            local position = vim.fn.pum_getpos()
            local total_column = api.nvim_get_option('columns')
            local align
            if position['col'] < total_column / 2 then
                align = 'right'
            else
                align = 'left'
            end

            if align == 'right' then

                col = position['col'] + position['width'] + 1

            else

                col = position['col'] - winopts['width'] - 1
            end

            if M.winnr == nil then

                M.winnr = vim.api.nvim_open_win(M.bufnr, false, {
                    col = col,
                    row = position['row'],
                    relative = 'editor',
                    width = winopts['width'],
                    height = winopts['height'],
                    style = 'minimal',
                    focusable = false
                })
            end

            local ft = vim.api.nvim_buf_get_option(0, 'filetype')
            M.highlighter(M.bufnr, ft)
        end))

end

local function has_filetype(ft) return ft and ft ~= '' end

-- Attach default highlighter which will choose between regex and ts
M.highlighter = function(bufnr, ft)
    if not (M.ts_highlighter(bufnr, ft)) then M.regex_highlighter(bufnr, ft) end
end

-- Attach regex highlighter
M.regex_highlighter = function(bufnr, ft)

    vim.api.nvim_buf_set_option(bufnr, 'syntax', ft)
    return true

end

-- Attach ts highlighter
M.ts_highlighter = function(bufnr, ft)
    if not has_ts then
        has_ts, _ = pcall(require, 'nvim-treesitter')
        if has_ts then
            _, ts_highlight = pcall(require, 'nvim-treesitter.highlight')
            _, ts_parsers = pcall(require, 'nvim-treesitter.parsers')
        end
    end

    if has_ts then
        local lang = ts_parsers.ft_to_lang(ft);
        if ts_parsers.has_parser(lang) then
            ts_highlight.attach(bufnr, lang)
            return true
        end
    end
    return false
end

function M.autoOpenUltisnips()

    if api.nvim_call_function('pumvisible', {}) == 1 then
        local items = api.nvim_call_function('complete_info', {
            {'eval', 'selected', 'items', 'user_data'}
        })

        if items['selected'] ~= -1 and items['selected'] ~= nil then
            local item = items['items'][items['selected'] + 1]

            if item.kind == 'UltiSnips' then

                if M.bufnr == nil then
                    M.bufnr = vim.api.nvim_create_buf(false, true)

                end

                if M.winnr == nil then
                    M.load_floating_contents(item.abbr)
                end

            elseif item.kind ~= 'Ultisnips' then

                if M.winnr ~= nil and api.nvim_win_is_valid(M.winnr) then

                    api.nvim_win_close(M.winnr, true)
                    M.winnr = nil
                end

            end

        end -- if items['selected'] ~= 1
    end -- if pumvisible
end -- endfunction M.autoHoverPopup()

function M.on_CompleteDone()
    if M.winnr ~= nil and api.nvim_win_is_valid(M.winnr) then
        api.nvim_win_close(M.winnr, true)
    end

end

M.on_attach = function(option)

    api.nvim_command(
        'autocmd InsertEnter <buffer> lua require\'ultipreview\'.on_InsertEnter()')
    api.nvim_command(
        'autocmd InsertLeave <buffer> lua require\'ultipreview\'.on_InsertLeave()')
    api.nvim_command(
        'autocmd CompleteDone <buffer> lua require\'ultipreview\'.on_CompleteDone()')

end

return M
